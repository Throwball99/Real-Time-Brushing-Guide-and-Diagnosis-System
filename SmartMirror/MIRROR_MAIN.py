from bluepy import btle
import numpy as np
import time
import firebase_admin
from firebase_admin import credentials, firestore, storage
import datetime
import socket
import struct
import tensorflow as tf
from sklearn.preprocessing import StandardScaler, LabelEncoder
from scipy.signal import butter, filtfilt

###################################################################
# 1. 블루투스 재연결 관련 예외처리 부족 및 보완 해야함.             
# 2. 지도모드 : 현재 총9 단계의 지도 화면으로 이루어져 있음         
# 3. 검증모드 : 13방향의 양치질을 검출 가능.                        
# 4. 현재 블루투스 데이터 무결성 체크는 데이터의 길이만으로 하는중.            
#    따라서 이후에 체크섬 등의 방식을 활용해서 보완해야 함.            
# 5. 블루투스로 전송받는 데이터의 크기는 15 Byte, 0~2 는 칫솔의 정보.     
#    3~6 은 X축의 가속도, 7~10 은 Y축의 가속도, 11~14 은 Z축의 가속도임. 
###################################################################






# BLE 서버의 MAC 주소 (ESP32-C3의 주소로 변경해야 함)
SERVER_ADDRESS = "ESP32의 MAC주소"
#

# 서비스 및 특성 UUID (ESP32-C3의 UUID와 일치해야 함)
SERVICE_UUID = "ESP32의 서비스 UUID"
CHARACTERISTIC_UUID = "ESP32의 캐릭터 UUID"

# Firebase Admin SDK 초기화
cred = credentials.Certificate('파이어스토어 json파일')
firebase_admin.initialize_app(cred)
db = firestore.client()

# 파이어스토어 관련 변수
# 칫솔의 방향을 불러올 때 사용하는 변수
Direction = 0
Last_Direction = 0

# 포터블 모드를 불러올 때 사용하는 변수
Portable = False
Last_Portable = False

# 충치 모드를 불러올 때 사용하는 변수
Cavity = False
Last_Cavity = False
Last_Cavity_For_BLE = False

# BLE 관련 변수
device = None
characteristic = None
BLE_error_time = 0
M_before = 0
T_before = 0.1
X_before = 0.1
Y_before = 0.1
Z_before = 0.1
B_before = 0
S_before = 0
val_before = 0

#칫솔 변수 설정
directions = 13 # 칫솔의 검출 가능한 방향 갯수
Brush_interval = 1 # 칫솔의 정보를 처리하는 주기
Last_Brush_time = time.perf_counter() #마지막으로 폴링한 시간
Brush_Direction = 0 # 칫솔의 방향 0 ~ 14
Last_Brush_mode = 1 # 칫솔의 마지막 모드

#검증 모드에서의 배열 및 변수
Motor_Array = np.zeros(directions)#각 부위별 모터 진동 횟수
Time_Array = np.zeros(directions)#각 부위별 양치 시간
Motor_Cnt = 0 # 진동 횟수
Motor_Cnt_before = 0#값 업데이트 전의 진동 횟수
Firestore_Updated = False # 파이어스토어 업데이트 여부777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777776 

#지도 모드에서의 배열 및 변수
Teach_Array = np.zeros(3)
Teach_State = 3


# 모델 로드777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
model = tf.keras.models.load_model('h5모델 경로')

def predict_new_data(new_data):
    # 예측 수행
    predictions = model.predict(np.array([new_data]))
    
    # 예측 결과 출력
    predicted_class = np.argmax(predictions)
    
    return predicted_class



class NotificationDelegate(btle.DefaultDelegate):
    def handleNotification(self, cHandle, data):
        print(f"<BLE>  Received notification: {data.decode()}")

#파이어스토어 어플리케이션 연동 데이터 업로드 
def add_category_data(date, side, time, count):
    date_doc_ref = db.collection('date').document(str(date))
    side_doc_ref = date_doc_ref.collection('categories').document(str(side))
    date_doc_ref.set({'dateField': str(date)})
    side_data = {'side': str(side), 'time': str(time), 'count': str(count)}
    side_doc_ref.set(side_data)

#파이어스토어 UI연동 데이터 업로드 
def add_UI_data(time_sum, motor_count, mode, teach_time, direction):
    UI_doc_ref = db.collection('UI').document('Info')
    doc = UI_doc_ref.get()
    if doc.exists:
        existing_data = doc.to_dict()
        existing_data.update({
            'Mode': int(mode),
            'Motor_Count': int(motor_count),
            'Time': str(time_sum),
            'Teach_Time': str(teach_time),
            'UI_Direction': int(direction)
        })
        UI_doc_ref.set(existing_data)

#BLE연결 함수
def BLE_Connect():
    global device, characteristic
    try:
        device = btle.Peripheral(SERVER_ADDRESS)
        print("<BLE>  BLE 연결됨")
        time.sleep(0.2)
        device.withDelegate(NotificationDelegate())
        service = device.getServiceByUUID(SERVICE_UUID)
        characteristic = service.getCharacteristics(CHARACTERISTIC_UUID)[0]
    except btle.BTLEException as e:
        print(f"<BLE>  BLE 연결 실패 : {e}")

def Read_BLE_Value():
    global device, characteristic
    global val_before
    try:
        Value = None
        while Value is None or len(Value) != 15:
            if device:
                try:
                    val = characteristic.read()
                except Exception as e:
                    val = val_before
                    print(f"<BLE>데이터 읽기 오류 : {e}")
                    # 블루투스 장치 재연결 시도
                    if device:
                        device.disconnect()
                    #BLE 초기화
                    time.sleep(1)
                    BLE_Connect()
                    print("<BLE> 재연결 성공")
            # 데이터 배열 변환
            val_before = val
            Value = np.frombuffer(val, dtype=np.uint8)
            if Value is None:
                print("<BLE> 데이터 읽기 실패, 재시도 중...")
            elif len(Value) != 15:
                print(f"<BLE> 잘못된 데이터 길이 ({len(Value)} 바이트), 재시도 중...")
        
        # 스위치 카운트 Read
        SW_Cnt = Value[0]
        # 칫솔 Mode Read
        Brush_Mode = Value[1]
        # 모터 카운트 Read
        Motor_Count = Value[2]
        # float형 데이터 x, y, z, total accels Read
        X_accel = struct.unpack('f', bytearray(Value[3:7]))[0]
        Y_accel = struct.unpack('f', bytearray(Value[7:11]))[0]
        Z_accel = struct.unpack('f', bytearray(Value[11:15]))[0]
        #Total_accel = struct.unpack('f', bytearray(Value[15:19]))[0]
       
        print(f"<BLE> 스위치 : {SW_Cnt}, 양치질 모드 : {Brush_Mode}, 진동 횟수 : {Motor_Count}")
        # print(f"<BLE> X_accel : {X_accel}, Y_accel : {Y_accel}, Z_accel : {Z_accel}, Total_accel : {Total_accel}")
       
        return SW_Cnt, Brush_Mode, Motor_Count, X_accel, Y_accel, Z_accel#, Total_accel
   
    except BrokenPipeError as e:
        print(f"<BLE> 연결이 끊어졌습니다. 재연결 시도 중... (오류 코드: {e})")
        try:
            # 블루투스 장치 재연결 시도
            if device:
                device.disconnect()
            #BLE 초기화
            time.sleep(1)
            device = None
            characteristic = None
            BLE_Connect()
            print("<BLE> 재연결 성공")
            return None  # 재연결 후 다시 시도
           
        except Exception as e:
            print(f"<BLE> 재연결 실패, 다시 시도하십시오. (오류 코드: {e})")
            if device:
                device.disconnect()
            #BLE 초기화
            device = None
            characteristic = None
            time.sleep(1)
            BLE_Connect()
            return None
   
    except Exception as e:
        print(f"<BLE> 데이터 읽기 오류, 코드 : ({e})")
        if device:
            device.disconnect()
        #BLE 초기화
        device = None
        characteristic = None
        time.sleep(1)
        BLE_Connect()
        return None


#데이터 전송 함수
def Write_BLE_Value(val):
    global characteristic
    try:
        value_bytes = str(val)
        characteristic.write(value_bytes.encode())
    except Exception as e:
        print(f"<BLE> 데이터 쓰기 오류, 코드 : ({e})")

#칫솔질 방향 판단 함수
def Brush_Process(directions):
    global Brush_Direction, Brush_interval, Last_Brush_time, Motor_Cnt, Motor_Cnt_before
    global Motor_Array, Time_Array, Teach_Array
    global Last_Brush_mode
    global Teach_State
    global device, characteristic
    global BLE_error_time
    global S_before, M_before, B_before, X_before, Y_before, Z_before, T_before
    global Firestore_Updated
    #파이어스토어에 입력될 더미값들
    Time_Dumi_Data = '0/0/0/0/0/0/0/0/0/0/0/0/0'
    Teach_Dumi_Data = '0/0/0'
    #현재 시간 check
    current_time = time.perf_counter()

    #Brush_interval의 주기로 동작
    if current_time - Last_Brush_time >= Brush_interval:
        try:
            BLE_Value = Read_BLE_Value()
            SW_Cnt, Brush_Mode, Motor_Count, X_accel, Y_accel, Z_accel = BLE_Value
            S_before, B_before, M_before, X_before, Y_before, Z_before = BLE_Value
        except Exception as e:
            print(f"진짜 엄청난 에러 발생 : {e}")
            #BLE 초기화
            if device:
                device.disconnect()
            device = None
            characteristic = None
            time.sleep(1)
            BLE_Connect()
            SW_Cnt = S_before
            Brush_Mode = B_before
            Motor_Count = M_before
            X_accel = X_before
            Y_accel = Y_before
            Z_accel = Z_before
            #Total_accel = T_before

        if Brush_Mode != Last_Brush_mode:
            Motor_Cnt = 0
            Motor_Cnt_before = 0
            for i in range(directions):
                Motor_Array[i] = 0
                Time_Array[i] = 0
            Last_Brush_mode = Brush_Mode

        accel_array = [X_accel, Y_accel, Z_accel]
        MPU_6050_Direction = predict_new_data(accel_array)
        Video_Direction = poll_firestore_Direction()

        #방향 판단
        #프론트 3방향 검출 하였을 때
        if Video_Direction >= 6 and Video_Direction <= 8:
            #프론트 3방향으로 방향 결정
            Brush_Direction = Video_Direction
        #영상에서 프론트 3방향이 검출이 되지 않았을 때
        else: 
            #MPU-6050에서 방향 검출이 되지 않으면
            if MPU_6050_Direction == 0:
                #영상 방향으로 방향 결정
                Brush_Direction = Video_Direction
            #MPU-6050에서 방향 검출이 되었을 때
            else:
                #칫솔 가속도 데이터로 방향 결정
                Brush_Direction = MPU_6050_Direction + 8


        #사용자가 검증 모드를 선택하였을 때
        if Brush_Mode == 0:
            #스위치 입력 횟수가 0이면
            if SW_Cnt == 0:
                Firestore_Updated = False
                #파이어스토어에 값 업로드 및 관련 변수들 초기화
                add_UI_data(Time_Dumi_Data, 0, SW_Cnt, Teach_Dumi_Data, 0)
                Motor_Cnt = 0
                Motor_Cnt_before = 0
                for i in range(directions):
                    Motor_Array[i] = 0
                    Time_Array[i] = 0

            #스위치 입력 횟수가 1이면
            elif SW_Cnt == 1:
                #칫솔의 진동 모터 가동 횟수를 Read
                Motor_Cnt = Motor_Count
                #진동 모터의 가동 횟수가 과거의 값보다 많으면
                if Motor_Cnt > Motor_Cnt_before:
                    #인식된 방향의 진동 횟수 1회 증가시킴
                    Motor_Array[Brush_Direction] += 1
                    #과거 값을 현재 값으로 업데이트
                    Motor_Cnt_before = Motor_Cnt
                #1초마다 방향을 check하여 그 방향의 값 증가시켜줌
                Time_Array[Brush_Direction] += 1
                #배열을 문자열로 변환한 뒤 사이사이에 '/' 추가
                time_str = '/'.join(map(str, Time_Array))
                #모터 진동 횟수를 저장하는 배열의 전체 합을 구함
                motor_cnt = np.sum(Motor_Array)
                #파이어스토어에 업로드
                add_UI_data(time_str, motor_cnt, SW_Cnt, '0/0/0', Brush_Direction)
            
            #스위치 입력 횟수가 2이면
            else:
                #양치 시간과 모터 진동 횟수를 모두 더함
                time_sum = np.sum(Time_Array)
                motor_sum = np.sum(Motor_Array)
                #파이어베이스에 업로드
                add_UI_data(time_sum, motor_sum, SW_Cnt, '0/0/0', 0)
                #현재 날짜, 시간 정보를 불러옴
                current_date = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
                #모터 관련 변수 초기화
                Motor_Cnt = 0
                Motor_Cnt_before = 0
                #파이어스토어에 총 양치 정보를 업로드하지 않았으면
                if not Firestore_Updated:
                    #값을 업로드
                    for i in range(directions):
                        add_category_data(current_date, i, Time_Array[i], Motor_Array[i])
                        Motor_Array[i] = 0
                        Time_Array[i] = 0
                    #Firestore_Updated 를 True로 하여 중복 업데이트 방지
                    Firestore_Updated = True

        
        #사용자가 지도 모드를 사용할 때
        elif Brush_Mode == 1:
            #아두이노에서 파이썬으로 코드를 옮기면서
            #기존의 UI와의 호환성을 위하여 스위치 입력값에
            #3을 더하여 사용
            Teach_State = SW_Cnt + 3
            
            #스위치 입력값이 15보다 낮을 때
            if Teach_State < 22:
            #초기화면으로 돌려야 할 때, 각 단계가 끝나면 초기화면으로 돌아감
            #초기화면은 스위치 입력이 0, 2, 4, 6, 8, 10, 12, 14, 16회일 때
                if Teach_State == 3 or Teach_State == 5 or Teach_State == 7 or Teach_State == 9 or Teach_State == 11 or Teach_State == 13 or Teach_State == 15 or Teach_State == 17 or Teach_State == 19 :
                    add_UI_data(Time_Dumi_Data, 0, 3, '0/0/0', 0)
                    #배열 초기화, 각 방향 지도 화면에서 사용했던 배열 초기화
                    for i in range(3):
                        Teach_Array[i] = 0

                #각 방향의 지도를 해야할 때, 9단계의 지도 단계가 있음
                #각 방향의 지도는 스위치 입력이 1, 3, 5, 7, 9, 11, 13, 15, 17회일 때
                elif Teach_State == 4 or Teach_State == 6 or Teach_State == 8 or Teach_State == 10 or Teach_State == 12 or Teach_State == 14 or Teach_State == 16 or Teach_State == 18 or Teach_State == 20:
                    #사용자가 스위치를 누르고 바로 지도가 시작하는 것이 아니라
                    #5초의 대기시간을 주기 때문에 5초가 되기 전까지는 방향 검증을 하지 않음
                    if Teach_Array[0] < 5 : 
                        #5초가 지나지 않으면
                        #전체 시간에서 1을 증가시킴
                        Teach_Array[0] = Teach_Array[0] + 1
                        #시간 정보 배열을 문자로 변환 및 '/' 첨가
                        Teach_Sum = '/'.join(map(str, Teach_Array))

                        #UI와의 호환성을 위하여 값을 변환해줌
                        if Teach_State == 4:
                            teach_state_buffer = 4
                        elif Teach_State == 6:
                            teach_state_buffer = 5
                        elif Teach_State == 8:
                            teach_state_buffer = 6
                        elif Teach_State == 10:
                            teach_state_buffer = 7
                        elif Teach_State == 12:
                            teach_state_buffer = 8
                        elif Teach_State == 14:
                            teach_state_buffer = 9
                        elif Teach_State == 16:
                            teach_state_buffer = 10
                        elif Teach_State == 18:
                            teach_state_buffer = 11
                        elif Teach_State == 20:
                            teach_state_buffer = 12
                        
                        #위의 단계에서 가공한 값을 Firestore에 업로드 
                        add_UI_data(Time_Dumi_Data, 0, teach_state_buffer, Teach_Sum, Brush_Direction)

                    #5초가 지나면 30초 동안 각 방향 검출함
                    elif Teach_Array[0] >= 5 and Teach_Array[0] <= 35:
                        #0번, 9번 방향을 닦아야 할 때
                        if Teach_State == 4:
                            #올바르게 0번, 9번 방향으로 닦으면
                            if Brush_Direction == 0 or Brush_Direction == 9:
                                Teach_Array[1] = Teach_Array[1] + 1
                            #올바른 방향으로 닦지 않으면
                            else: 
                                Teach_Array[2] = Teach_Array[2] + 1
                            Teach_Array[0] = 5 + Teach_Array[1] + Teach_Array[2]
                            Teach_Sum = '/'.join(map(str, Teach_Array))
                            add_UI_data(Time_Dumi_Data, Motor_Count, 4, Teach_Sum, Brush_Direction)
                        #1번 방향을 닦아야 할 때
                        elif Teach_State == 6:
                            if Brush_Direction == 1:
                                Teach_Array[1] = Teach_Array[1] + 1
                            else:
                                Teach_Array[2] = Teach_Array[2] + 1
                            Teach_Array[0] = 5 + Teach_Array[1] + Teach_Array[2]
                            Teach_Sum = '/'.join(map(str, Teach_Array))
                            add_UI_data(Time_Dumi_Data, Motor_Count, 5, Teach_Sum, Brush_Direction)
                        #2번, 10번 방향을 닦아야 할 때
                        elif Teach_State == 8:
                            if Brush_Direction == 2 or Brush_Direction == 10:
                                Teach_Array[1] = Teach_Array[1] + 1
                            else:
                                Teach_Array[2] = Teach_Array[2] + 1
                            Teach_Array[0] = 5 + Teach_Array[1] + Teach_Array[2]
                            Teach_Sum = '/'.join(map(str, Teach_Array))
                            add_UI_data(Time_Dumi_Data, Motor_Count, 6, Teach_Sum, Brush_Direction)
                        #3번, 11번 방향을 닦아야 할 때
                        elif Teach_State == 10:
                            if Brush_Direction == 3 or Brush_Direction == 11:
                                Teach_Array[1] = Teach_Array[1] + 1
                            else:
                                Teach_Array[2] = Teach_Array[2] + 1
                            Teach_Array[0] = 5 + Teach_Array[1] + Teach_Array[2]
                            Teach_Sum = '/'.join(map(str, Teach_Array))
                            add_UI_data(Time_Dumi_Data, Motor_Count, 7, Teach_Sum, Brush_Direction)
                        #4번 방향을 닦아야 할 때
                        elif Teach_State == 12:
                            if Brush_Direction == 4:
                                Teach_Array[1] = Teach_Array[1] + 1
                            else:
                                Teach_Array[2] = Teach_Array[2] + 1
                            Teach_Array[0] = 5 + Teach_Array[1] + Teach_Array[2]
                            Teach_Sum = '/'.join(map(str, Teach_Array))
                            add_UI_data(Time_Dumi_Data, Motor_Count, 8, Teach_Sum, Brush_Direction)
                        #5번, 12번 방향을 닦아야 할 때
                        elif Teach_State == 14:
                            if Brush_Direction == 5 or Brush_Direction == 12:
                                Teach_Array[1] = Teach_Array[1] + 1
                            else:
                                Teach_Array[2] = Teach_Array[2] + 1
                            Teach_Array[0] = 5 + Teach_Array[1] + Teach_Array[2]
                            Teach_Sum = '/'.join(map(str, Teach_Array))
                            add_UI_data(Time_Dumi_Data, Motor_Count, 9, Teach_Sum, Brush_Direction)
                        #6번 방향을 닦아야 할 때
                        elif Teach_State == 16:
                            if Brush_Direction == 6:
                                Teach_Array[1] = Teach_Array[1] + 1
                            else:
                                Teach_Array[2] = Teach_Array[2] + 1
                            Teach_Array[0] = 5 + Teach_Array[1] + Teach_Array[2]
                            Teach_Sum = '/'.join(map(str, Teach_Array))
                            add_UI_data(Time_Dumi_Data, Motor_Count, 10, Teach_Sum, Brush_Direction)
                        #7번 방향을 닦아야 할 때
                        elif Teach_State == 18:
                            if Brush_Direction == 7:
                                Teach_Array[1] = Teach_Array[1] + 1
                            else:
                                Teach_Array[2] = Teach_Array[2] + 1
                            Teach_Array[0] = 5 + Teach_Array[1] + Teach_Array[2]
                            Teach_Sum = '/'.join(map(str, Teach_Array))
                            add_UI_data(Time_Dumi_Data, Motor_Count, 11, Teach_Sum, Brush_Direction)
                        #8번 방향을 닦아야 할 때
                        elif Teach_State == 20:
                            if Brush_Direction == 8:
                                Teach_Array[1] = Teach_Array[1] + 1
                            else:
                                Teach_Array[2] = Teach_Array[2] + 1
                            Teach_Array[0] = 5 + Teach_Array[1] + Teach_Array[2]
                            Teach_Sum = '/'.join(map(str, Teach_Array))
                            add_UI_data(Time_Dumi_Data, Motor_Count, 12, Teach_Sum, Brush_Direction)

                    elif Teach_Array[0] > 34:
                        pass
            
                else:
                    add_UI_data(Time_Dumi_Data, 0, 13, '0/0/0/0', 0)
            
        Last_Brush_time = current_time

def poll_firestore_Direction():#
    global Direction
    doc_ref = db.collection('UI').document('Info')
    try:
        doc = doc_ref.get()
        if doc.exists:
            data = doc.to_dict()
            Direction = data.get('Direction')
        return Direction
    except Exception as e:
        print(f"<Firestore>  Firestore 폴링 중 오류: {e}")

def on_firestore_update(doc_snapshot, changes, read_time):
    global Portable, Last_Portable
    global Cavity, Last_Cavity
    for doc in doc_snapshot:
        Portable = doc.to_dict().get('Portable')
        Cavity = doc.to_dict().get('Cavity')

        if Portable != Last_Portable:
            if not Portable:
                time.sleep(2)
            Last_Portable = Portable
            print(f"<Firestore>  거울/포터블 변경,  변경된 값 : {Portable}")
        if Cavity != Last_Cavity:
            Last_Cavity = Cavity
            print(f"<Firestore>  거울/충치 변경,  변경된 값 : {Cavity}")

def watch_firestore():
    doc_ref = db.collection('UI').document('Info')
    doc_ref.on_snapshot(on_firestore_update)

def main():
    global device, characteristic
    global Direction, Portable, Cavity, Last_Cavity_For_BLE
    global directions

    while True:
        #포터블 모드가 아닐 때
        if not Portable:
            #반복
            while True:
                #충치 검출 모드가 변경될 때
                if Cavity != Last_Cavity_For_BLE:
                    #충치 검출 모드이면
                    if Cavity:
                        try:
                            if device and characteristic:
                                #칫솔에 재시작 신호 보내기
                                Write_BLE_Value(44)
                                #BLE연결 종료
                                device.disconnect()
                                #BLE 초기화
                                device = None
                                characteristic = None
                                print("<BLE>  충치 모드로 전환에 따라 BLE연결 해지")
                                dumi = '0/0/0/0/0/0/0/0/0/0/0/0/0'
                                add_UI_data(dumi, 0, 0, '0/0/0', 0)
                        except (btle.BTLEException, socket.error) as e:
                            print(f"<BLE>  BLE 쓰기 및 연결 해지 오류: {e}")
                    Last_Cavity_For_BLE = Cavity

                #충치 검출 모드가 꺼져있으면
                if not Cavity :
                    #BLE 연결이 되어있지 않으면
                    if device is None or characteristic is None:
                        #연결 시도
                        print("<BLE>  연결 시도 중...")
                        BLE_Connect()
                        #0.1초 대기
                        time.sleep(0.1)
                        
                    #연결에 성공하였으면
                    if device and characteristic:
                        Brush_Process(directions)

                #포터블 모드가 아닐 때 포터블 모드로 전환되면
                if Portable:
                    #BLE가 연결되어 있으면
                    if device and characteristic:
                        try:
                            #칫솔에 재시작 신호 보내기
                            Write_BLE_Value(44)
                            #BLE 연결 종료
                            device.disconnect()
                            #BLE 변수 초기화
                            device = None
                            characteristic = None
                            #UI 초기화
                            dumi = '0/0/0/0/0/0/0/0/0/0/0/0/0'
                            add_UI_data(dumi, 0, 0, '0/0/0', 0)
                            print("<System>  포터블 모드로 변경.")
                            #break 하여 포터블 모드로 전환
                            break
                        except (btle.BTLEException, socket.error) as e:
                            print(f"<BLE>  BLE 쓰기 오류: {e}")
                        except Exception as e:
                            print(f"<BLE>  BLE 오류 : {e}")

        #포터블 모드일 때
        else:
            while True:
                if not Portable:
                    device = None
                    characteristic = None
                    print("<System>  거울 사용 모드로 변경.")
                    time.sleep(4)
                    try:
                        BLE_Connect()
                        break
                    except (btle.BTLEException, socket.error) as e:
                        print(f"<BLE>  연결 시도 중 오류: {e}")
                    

if __name__ == "__main__":
    watch_firestore()
    main()