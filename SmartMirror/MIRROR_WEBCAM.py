import firebase_admin
from firebase_admin import credentials, firestore, storage
import time
import mediapipe as mp
import cv2
import socket
import base64
import warnings
import numpy as np
from datetime import datetime
from ultralytics import YOLO
from PyQt6 import QtCore, QtGui, QtWidgets
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options

warnings.filterwarnings('ignore')

#크롬 드라이버(인터넷 창)==================================================================================
#크롬 드라이버 경로 설정
chrome_driver_path = '크롬 드라이버 경로'
UI_Path = 'UI 웹사이트 경로'
#옵션 설정
chrome_options = Options()
#전체화면 모드로 시작
chrome_options.add_argument("--start-maximized")#창을 최대화하여 시작
chrome_options.add_argument("disable-infobars")#정보 바 비활성화
chrome_options.add_argument("disable-extensions")#확장 프로그램 비활성화
#"자동화된 테스트 소프트웨어에 의해 제어되고 있습니다" 메세지 제거
chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
chrome_options.add_experimental_option("useAutomationExtension", False)

#크롬 드라이버 서비스 시작
print(f"MIRROR.WEBCAM <System>  크롬 드라이버 서비스 시작 중... 경로 : ({chrome_driver_path})")
service = Service(chrome_driver_path)
driver = webdriver.Chrome(service=service, options=chrome_options)


driver.get(UI_Path)
driver.fullscreen_window()
#페이지 로딩 대기
print(f"MIRROR.WEBCAM <System>  UI 페이지 여는 중... 경로 : ({UI_Path})")
time.sleep(5)
#driver.execute_script("document.documentElement.requestFullscreen();")

#웹 페이지 열기 닫기 하는 코드
#웹 페이지 열기 -> driver.get('https://www.example.com')
#웹 페이지 닫기 -> driver.quit()

#=======================================================================================================


#양치 검증 및 학습 모드일 때의 코드=========================================================================
def send_image(image, image_zip, server_ip, server_port):
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_socket.connect((server_ip, server_port))

    _, img_encode = cv2.imencode('.png', image, image_zip)
    data = base64.b64encode(img_encode).decode('utf-8')

    client_socket.sendall(data.encode('utf-8'))
    client_socket.close()

def Work_Cam():
    global cavity
    global detect
    global portable
    prev_time = time.time()
    while True:
        ret, frame = cap1.read()
        if not ret:
            print("MIRROR.WEBCAM <MAIN CAM>  Failed to capture image")
            break
        
        frame = cv2.flip(frame, 1)
        
        # cv2.imshow('MIRROR.WEBCAM <MAIN CAM>  GCP Video Stream', frame)

        # if cv2.waitKey(150) == ord('q'):
        #     break

        if cavity:
            break
        if portable:
            break

        frame_gray = cv2.cvtColor(frame, cv2.COLOR_RGB2GRAY)
        frame_zip = [int(cv2.IMWRITE_JPEG_QUALITY), 25
        ]
        current_time = time.time()

        if (current_time - prev_time) >= 0.25:
            send_image(frame_gray, frame_zip, '서버 IP', 8080)
            prev_time = time.time()

    cap1.release()
    cv2.destroyAllWindows()
#======================================================================================================



#충치 검출 및 치석 검출일 때의 코드=========================================================================
model = YOLO('pt파일')
UI_Second = 10
UI_Photo_Count = 0
UI_Take_Photo = False

class VideoThread(QtCore.QThread):
    change_pixmap_signal = QtCore.pyqtSignal(np.ndarray)

    def run(self):
        cap = cv2.VideoCapture(0)
        prev_time = time.time()
        prev_time_for_UI = time.time()
        count = 0
        count_for_UI = 0
        size = 7
        half_size = size // 2
        desired_alpha = 125
        alpha = desired_alpha / 255.0
        global UI_Second
        global UI_Photo_Count
        global UI_Take_Photo
        global cavity
        global portable

        while True:
            check_cavity = False
            check_plaque = False
            if portable:
                break

            if not cavity:
                break
            now_time = time.time()
            now_time_for_UI = time.time()
            ret, frame = cap.read()
            if not ret:
                break

            frame = cv2.flip(frame, 1)
           
            if now_time_for_UI -prev_time_for_UI >= 1:
                count_for_UI += 1
                UI_Second = 10 - count_for_UI
                prev_time_for_UI = time.time()
                print(f"MIRROR.WEBCAM <SUB CAM>  촬영까지 남은 시간 : {UI_Second}초")

            if now_time - prev_time >= 10:
                count += 1
                UI_Take_Photo = True
                UI_Photo_Count = count
                print(f"MIRROR.WEBCAM <SUB CAM>  찍은 횟수 : {count}")
                results = model(frame)
                boxes = results[0].boxes

                alpha_image = cv2.cvtColor(frame, cv2.COLOR_BGR2BGRA)
                gray_mask_image = np.zeros([frame.shape[0], frame.shape[1]], dtype='uint8')
                mask_image = np.zeros([frame.shape[0], frame.shape[1], 3], dtype='uint8')
               
                if len(boxes) != 0:
                    caries_boxes = []
                    normal_boxes = []
                    for box in boxes:
                        class_name = results[0].names[box.cls.numpy()[0]]
                        if class_name == 'Caries':
                            caries_boxes.append([int(v) for v in box.xyxy.numpy()[0]])
                        else:
                            normal_boxes.append([int(v) for v in box.xyxy.numpy()[0]])
                   
                    if len(normal_boxes) != 0:
                        for box in normal_boxes:
                            crop_image = frame[box[1]:box[3], box[0]:box[2]]
                            hls_crop_image = cv2.cvtColor(crop_image, cv2.COLOR_BGR2HLS)
                            lower_orange_yellow = np.array([10, 35, 35])  # 대략적인 주황색 하한
                            upper_orange_yellow = np.array([60, 150, 150])  # 대략적인 노란색 상한

                            mask = cv2.inRange(hls_crop_image, lower_orange_yellow, upper_orange_yellow)
                            white_index = []

                            for j in range(mask.shape[0]):
                                for i in range(mask.shape[1]):
                                    if mask[j, i] == 255:
                                        white_index.append((j, i))
                           
                            for y, x in white_index:
                                start_x = max(x - half_size, 0)
                                end_x = min(x + half_size + 1, mask.shape[1])
                                start_y = max(y - half_size, 0)
                                end_y = min(y + half_size + 1, mask.shape[0])
                                mask[start_y:end_y, start_x:end_x] = 255

                            #치석 면적 구하기
                            plaque_area_list = (mask == 255)
                            plaque_area = np.sum(plaque_area_list)
                            plaque_ratio = np.round(plaque_area / (mask.shape[0]*mask.shape[1]) * 100 * 1.25, 1)

                            if plaque_ratio >= 20:
                                cv2.rectangle(alpha_image, (box[0], box[1]), (box[2], box[3]), (0, 0, 255), 3)
                                gray_mask_image[box[1]:box[3], box[0]:box[2]] = mask
                                check_plaque = True
                            else:
                                gray_mask_image[box[1]:box[3], box[0]:box[2]] = mask

                        color_mask = (gray_mask_image==255)
                        print(f"MIRROR.WEBCAM <SUB CAM>  color_mask sum is : {np.sum(color_mask)}")
                        mask_image[color_mask] = [255, 0, 0]

                        alpha_mask_image = cv2.cvtColor(mask_image, cv2.COLOR_BGR2BGRA)

                        result = cv2.addWeighted(alpha_image, 1, alpha_mask_image, alpha, 0)
                        frame = cv2.cvtColor(result, cv2.COLOR_BGRA2BGR)
                               
                    if len(caries_boxes) != 0:
                        check_cavity = True
                        for box in caries_boxes:
                            cv2.rectangle(frame, (box[0], box[1]), (box[2], box[3]), (0, 255, 0), 3)
                
                if check_cavity is True and check_plaque is False:
                    current_time = datetime.now()
                    current_time = current_time.isoformat(timespec='seconds')
                    file_name = '사진 저장할 경로' + current_time + '_Cavity' + '.jpg'
                    cv2.imwrite(file_name, frame)
                    frame_ref = db.collection('Picture').document(current_time)
                    data = {
                        'Cavity': True,
                        'DataField': current_time,
                        'Path': file_name,
                        'Plaque': False
                    }
                    frame_ref.set(data)
                    blob = bucket.blob(file_name)
                    blob.upload_from_filename(file_name)

                elif check_cavity is False and check_plaque is True:
                    current_time = datetime.now()
                    current_time = current_time.isoformat(timespec='seconds')
                    file_name = '사진 저장할 경로' + current_time + '_Plaque' + '.jpg'
                    cv2.imwrite(file_name, frame)
                    frame_ref = db.collection('Picture').document(current_time)
                    data = {
                        'Cavity': False,
                        'DataField': current_time,
                        'Path': file_name,
                        'Plaque': True
                    }
                    frame_ref.set(data)
                    blob = bucket.blob(file_name)
                    blob.upload_from_filename(file_name)

                elif check_cavity is True and check_plaque is True:
                    current_time = datetime.now()
                    current_time = current_time.isoformat(timespec='seconds')
                    file_name = '사진 저장할 경로' + current_time + '_Combine' + '.jpg'
                    cv2.imwrite(file_name, frame)
                    frame_ref = db.collection('Picture').document(current_time)
                    data = {
                        'Cavity': True,
                        'DataField': current_time,
                        'Path': file_name,
                        'Plaque': True
                    }
                    frame_ref.set(data)
                    blob = bucket.blob(file_name)
                    blob.upload_from_filename(file_name)

                UI_Take_Photo = False
                count_for_UI = 0
                prev_time = time.time()

            self.change_pixmap_signal.emit(frame)
       
        cap.release()

class App(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()
        global UI_Take_Photo
        self.setWindowTitle("충치 및 치석 검출 모델")
        self.setStyleSheet("QWidget { background-color: black; }")
        self.showFullScreen()
        screen = QtWidgets.QApplication.primaryScreen().size()
        self.disply_width = screen.width()
        self.display_height = screen.height()
        self.image_label = QtWidgets.QLabel(self)
        self.image_label.resize(self.disply_width, self.display_height)
        self.top_text_label = QtWidgets.QLabel(f"10초마다 자동으로 촬영됩니다.   (촬영까지 남은 시간 : {str(UI_Second)}초)", self)
        self.top_text_label.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        self.top_text_label.setStyleSheet("QLabel { background-color : black; color : white; font-size: 23px; }")
        self.bottom_text_label = QtWidgets.QLabel(f"촬영 전 까지 원하는 위치로 카메라를 이동시켜 주세요.    (찍은 횟수 : {UI_Photo_Count})", self)
        self.bottom_text_label.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        self.bottom_text_label.setStyleSheet("QLabel { background-color : black; color : white; font-size: 23px; }")
       
        vbox = QtWidgets.QVBoxLayout()
        vbox.addWidget(self.top_text_label)
        vbox.addWidget(self.image_label)
        vbox.addWidget(self.bottom_text_label)
        self.setLayout(vbox)

        self.timer = QtCore.QTimer(self)
        self.timer.timeout.connect(self.update_labels)
        self.timer.start(500)
       
        self.thread = VideoThread()
        self.thread.change_pixmap_signal.connect(self.update_image)
        self.thread.start()

    @QtCore.pyqtSlot(np.ndarray)
    def update_image(self, cv_img):
        qt_img = self.convert_cv_qt(cv_img)
        self.image_label.setPixmap(qt_img)

    def convert_cv_qt(self, cv_img):
        rgb_image = cv2.cvtColor(cv_img, cv2.COLOR_BGR2RGB)
        h, w, ch = rgb_image.shape
        bytes_per_line = ch * w
        convert_to_Qt_format = QtGui.QImage(rgb_image.data, w, h, bytes_per_line, QtGui.QImage.Format.Format_RGB888)
        p = convert_to_Qt_format.scaled(self.disply_width, self.display_height, QtCore.Qt.AspectRatioMode.KeepAspectRatio)
        return QtGui.QPixmap.fromImage(p)
    
    def hide_window(self):
        if self.window is not None:
            self.window.hide()
            self.video_thread.stop()
            self.window_visible = False

    def close_window(self):
        self.thread.quit()
        self.thread.wait()
        self.close()

    def update_labels(self):
        global UI_Second, UI_Photo_Count
        if UI_Take_Photo == False:
            self.top_text_label.setText(f"10초마다 자동으로 촬영됩니다.   (촬영까지 남은 시간 : {str(UI_Second)}초)")
            self.bottom_text_label.setText(f"촬영 전 까지 원하는 위치로 카메라를 이동시켜 주세요.  찍은 횟수 : {UI_Photo_Count}")
        else:
            self.top_text_label.setText(f"충치 및 치석 검출 중...")
            self.bottom_text_label.setText(f"분석 결과는 전용 어플에서 확인할 수 있습니다.")
#======================================================================================================




#파이어스토어 셋=========================================================================================
# Firebase Admin SDK 및 스토리지 초기화 
id = '파이어스토어 ID'
cred = credentials.Certificate('파이어스토어 json파일 경로')
default_app = firebase_admin.initialize_app(cred, {
    'storageBucket' : f"{id}.appspot.com"
})
bucket = storage.bucket()

# Firebase Storage에 사진을 올리기 위한 함수
def upload_image(path, blob_name):
    blob = bucket.blob(blob_name)
    blob.upload_from_filename(path)

    blob.make_public()

db = firestore.client()
cavity = False
last_cavity = False
portable = False
last_portable = False

def on_firestore_update(doc_snapshot, changes, read_time):
    global cavity, last_cavity
    global portable, last_portable
    for doc in doc_snapshot:
        cavity = doc.to_dict().get('Cavity')
        portable = doc.to_dict().get('Portable')
        if cavity != last_cavity:
            last_cavity = cavity
            print(f"MIRROR.WEBCAM <Firestore>  카메라 변경, 변경된 값 : {cavity}")
        if portable != last_portable:
            last_portable = portable
            print(f'MIRROR.WEBCAM <Firestore>  거울/포터블 모드 변경, 변경된 값 : {portable}')


def watch_firestore():
    doc_ref = db.collection('UI').document('Info')
    doc_ref.on_snapshot(on_firestore_update)

# 파이어베이스 리스너 등록(while문 안에 들어가면 안됨)
watch_firestore()
#======================================================================================================
if __name__ == '__main__':
    app = QtWidgets.QApplication([])
    window = None

    while True:
        #포터블 모드일 때
        if portable:
            while True:
                if window is not None:
                    window.close_window()
                    window = None
                if not portable:
                    
                    break

                pass
        #거울을 사용할 때
        else:
            while True:
                if cavity:
                    if window is None:
                        window = App()
                        window.show()
                    app.processEvents()

                else:
                    if window is not None:
                        window.close_window()
                        window = None
                    cap1 = cv2.VideoCapture(2)
                    Work_Cam()
                if portable:
                    break

        time.sleep(0.1)
