from bluepy import btle
import numpy as np
import time
import firebase_admin
from firebase_admin import credentials, firestore, storage
import datetime
import socket
import struct
import csv
import sys
import tensorflow as tf

# BLE 서버의 MAC 주소 (ESP32-C3의 주소로 변경해야 함)
SERVER_ADDRESS = "ESP32의 MAC주소"

# 서비스 및 특성 UUID (ESP32-C3의 UUID와 일치해야 함)
SERVICE_UUID = "ESP32의 서비스 UUID"
CHARACTERISTIC_UUID = "ESP32의 캐릭터 UUID"

# CSV 파일 경로
now = datetime.datetime.now()
FILE_NAME = '파일 이름.csv'
FILE_NAME_WITH_DATE = now.strftime('%Y-%m-%d_%H:%M:%S') + '_' + FILE_NAME
CSV_FILE_PATH = '파일 경로'+ FILE_NAME_WITH_DATE#accel_data.csv'

# BLE 관련 변수
DeviceConnected = False
OldDeviceConnected = False

class NotificationDelegate(btle.DefaultDelegate):
    def handleNotification(self, cHandle, data):
        print(f"MIRROR_MAIN <BLE>  Received notification: {data.decode()}")

def BLE_Connect():
    global DeviceConnected
    # BLE 장치에 연결
    device = btle.Peripheral(SERVER_ADDRESS)
    print("MIRROR.MAIN <BLE>  Connected!")
    time.sleep(0.2)
    # 알림 델리게이트 설정
    device.withDelegate(NotificationDelegate())

    # 서비스 찾기
    service = device.getServiceByUUID(SERVICE_UUID)

    # 특성 찾기
    characteristic = service.getCharacteristics(CHARACTERISTIC_UUID)[0]

    DeviceConnected = True

    return device, characteristic

def Read_BLE_Value(device, characteristic):
    # 특성 값 읽기
    value = characteristic.read()
    receive_array = np.frombuffer(value, dtype=np.uint8)
    #print(f"MIRROR.MAIN <BLE>  Received value: {receive_array}")
   
    Direction = receive_array[0]
    if Direction == 0:
        print("초기 상태. 아무 동작도 하지 않음.")
        return None  # 초기 상태인 경우 아무 동작도 하지 않고 None 반환

    if Direction == 16:
        print("Dirrection이 9이므로 프로그램 종료.")
        sys.exit(0)

    print(f"방향 : {Direction}")
    data = bytearray([receive_array[1], receive_array[2], receive_array[3], receive_array[4]])
    X_accel = struct.unpack('f', data)[0]
    print(f"X_accel : {X_accel}")
    data = bytearray([receive_array[5], receive_array[6], receive_array[7], receive_array[8]])
    Y_accel = struct.unpack('f', data)[0]
    print(f"Y_accel : {Y_accel}")
    data = bytearray([receive_array[9], receive_array[10], receive_array[11], receive_array[12]])
    Z_accel = struct.unpack('f', data)[0]
    print(f"Z_accel : {Z_accel}")
    data = bytearray([receive_array[13], receive_array[14], receive_array[15], receive_array[16]])
    Total_accel = struct.unpack('f', data)[0]
    print(f"Total_accel : {Total_accel}")

   
    return Direction, X_accel, Y_accel, Z_accel, Total_accel

def Write_BLE_Value(val, characteristic):
    value_bytes = str(val)
    characteristic.write(value_bytes.encode())

def write_to_csv(data, file_path):
    header = ['Direction', 'X_accel', 'Y_accel', 'Z_accel', 'Total_accel']
    file_exists = False
   
    try:
        with open(file_path, 'r', newline='') as csvfile:
            file_exists = True
    except FileNotFoundError:
        pass
   
    with open(file_path, 'a', newline='') as csvfile:
        writer = csv.writer(csvfile)
        if not file_exists:
            writer.writerow(header)
        writer.writerow(data)

def main():
    device = None
    global DeviceConnected, OldDeviceConnected

    while True:
        # 기기가 켜지고 연결이 한 번도 안 되었을 때
        if not DeviceConnected and not OldDeviceConnected:
            # 블루투스가 연결될 때 까지 연결 시도
            while True:
                try:
                    device, characteristic = BLE_Connect()
                    # 블루투스가 연결되면 while문 break하여 다음 동작 수행
                    if DeviceConnected:
                        OldDeviceConnected = True
                        break
                except (btle.BTLEException, socket.error) as e:
                    print(f"MIRROR.MAIN <BLE>  연결 시도 중 오류: {e}")
                    time.sleep(1)

        # 장치가 작동 도중 블루투스 연결이 해지되었을 때
        if not DeviceConnected and OldDeviceConnected:
            print("MIRROR.MAIN <BLE>  예기치 못한 연결 해지, 재 연결 시도중...")
            # 1초 대기
            time.sleep(1)
            while True:
                try:
                    device, characteristic = BLE_Connect()
                    if DeviceConnected:
                        break
                except (btle.BTLEException, socket.error) as e:
                    print(f"MIRROR.MAIN <BLE>  연결 재시도 중 오류: {e}")
                    time.sleep(1)

        # 블루투스 기기가 연결되었을 때
        if DeviceConnected:
            # 데이터 읽기 시도
            try:
                result = Read_BLE_Value(device, characteristic)
                if result:
                    Direction, X_accel, Y_accel, Z_accel, Total_accel = result
                    data = [Direction, X_accel, Y_accel, Z_accel, Total_accel]
                    write_to_csv(data, CSV_FILE_PATH)
                    print(f"전송받은 값 : {data}")
            except (btle.BTLEException, socket.error, BrokenPipeError) as e:
                print(f"MIRROR.MAIN <BLE>  데이터 읽기 오류: {e}")
                if device:
                    try:
                        device.disconnect()
                    except BrokenPipeError as e:
                        print(f"MIRROR.MAIN <BLE>  블루투스 연결 해제 오류: {e}")
                device = None
                DeviceConnected = False

if __name__ == "__main__":
    main()