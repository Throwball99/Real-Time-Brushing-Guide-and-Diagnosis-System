import socket
import base64
import numpy as np
import cv2
import time
import binascii
from collections import Counter
import tensorflow as tf
from tensorflow import keras
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import mediapipe as mp
from ultralytics import YOLO

mp_face_detection = mp.solutions.face_detection
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles

# Firebase 인증 정보를 제공하는 서비스 계정 키 파일을 다운로드하고 경로를 설정합니다.
cred = credentials.Certificate('firebase.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

collection_name = 'UI'
document_id = 'Info'

doc_ref = db.collection(collection_name).document(document_id)

config = tf.compat.v1.ConfigProto(
    gpu_options=tf.compat.v1.GPUOptions(
        per_process_gpu_memory_fraction=0.75 #최대치의 75%까지
    )
)
sess = sess = tf.compat.v1.Session(config=config)

model = YOLO("yolov8l.pt")  # load a custom model

effb1_model = keras.models.load_model('model.h5')


label = {0 : 'middlefront', 1 : 'middledown', 2 : 'middleup',
         3 : 'leftfront', 4 : 'leftdown', 5 : 'leftup',
         6 : 'rightfront', 7 : 'rightdown', 8 : 'rightup',
         9 : 'Not Detect Tooth'}

rule_label = {0: 7, 1: 4, 2: 1,
              3: 6, 4: 3, 5: 0,
              6: 8, 7: 5, 8: 2,
              9: 9}

def check_x(x1, x2, width):
    if x1 < 0:
        new_x1 = 0
        new_x2 = x2 - x1
    elif x2 > width:
        new_x2 = width
        new_x1 = x1 - (x2 - width)
    
    else:
        new_x1 = x1
        new_x2 = x2
    
    return new_x1, new_x2

def check_y(y1, y2, height):
    if y1 < 0:
        new_y1 = 0
        new_y2 = y2 - y1
    elif y2 > height:
        new_y2 = height
        new_y1 = y1 - (y2 - height)
    
    else:
        new_y1 = y1
        new_y2 = y2
    
    return new_y1, new_y2

def receive_image(server_ip, server_port):
    # 소켓 생성

    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((server_ip, server_port))
    server_socket.listen(1)
    print("Server listening on {}:{}".format(server_ip, server_port))
    counter = Counter()
    teeth_label = None
    past_teeth_label = None
    previous_time = time.time()
    check_tooth = time.time()
    detect = False
    while True:
        try:
            with mp_face_detection.FaceDetection(
            model_selection=0, min_detection_confidence=0.7) as face_detection:
                client_socket, _ = server_socket.accept()
                data = b""

                while True:
                    packet = client_socket.recv(4096)

                    if not packet:
                        break
                    data += packet

                # 데이터 디코딩
                img_data = base64.b64decode(data)
                np_data = np.frombuffer(img_data, np.uint8)
                #img = cv2.imdecode(np_data, cv2.IMREAD_ANYCOLOR)
                image = cv2.imdecode(np_data, cv2.IMREAD_GRAYSCALE)
                #image = cv2.flip(image, 1)

                image.flags.writeable = False
                image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)

                results = face_detection.process(image)
                image.flags.writeable = True

                if results.detections:
                    detect = True
                    bbox = results.detections[0].location_data.relative_bounding_box
                    x = int(bbox.xmin * image.shape[1])
                    y = int(bbox.ymin * image.shape[0])
                    x1 = x - 44
                    y1 = y - 60   # -75
                    x2 = x + 196
                    y2 = y + 180  # -75

                    x1, x2 = check_x(x1, x2, image.shape[1])
                    y1, y2 = check_y(y1, y2, image.shape[0])
            
                    image = image[y1:y2, x1:x2]
                
                else:
                    if detect is True:
                        image = image[prev_y1:prev_y2, prev_x1:prev_x2]
                
                if detect is True:
                    prev_x1 = x1
                    prev_y1 = y1
                    prev_x2 = x2
                    prev_y2 = y2

                if image.shape[0] == 240:
                    result = model(image)
                    model_image = np.expand_dims(image, axis=0)

                    pred = effb1_model.predict(model_image)
                    
                    past_teeth_label = teeth_label

                    if max(pred[0]) > 0.7:
                        predict = np.argmax(pred)
                        counter[predict] += 1
                        cv2.putText(image, label[predict] + str(round(max(pred[0]), 2)), (20, 40), cv2.FONT_HERSHEY_PLAIN, 1.5, (0, 0, 255), 3)

                        if (time.time() - previous_time) > 1:
                            most_teeth_label = counter.most_common(1)[0]
                            teeth_label = most_teeth_label[0]
                            print('1 second most teeth label: ' + label[most_teeth_label[0]])
                            previous_time = time.time()
                            counter = Counter()     
                    
                    # bounding box based on yolo
                    boxes = result[0].boxes
                    rec_box = []
                    for box in boxes:
                        if box.cls.cpu().detach().numpy().tolist()[0] == 79: # tooth
                            rec_box.append(box.xyxy.cpu().detach().numpy().tolist())
                    
                    if len(rec_box) != 0:
                        check_tooth = time.time()
                        for box in rec_box:
                            start_point = (int(box[0][0]), int(box[0][1]))
                            end_point = (int(box[0][2]), int(box[0][3]))
                            color = (0, 255, 0)
                            thickness = 2

                            cv2.rectangle(image, start_point, end_point, color, thickness)

                    if (time.time() - check_tooth) >= 3: # 칫솔을 3초 이상 감지를 못하면
                        teeth_label = 9

                    if teeth_label is not None:
                        cv2.putText(image, label[teeth_label], (20, 40), cv2.FONT_HERSHEY_PLAIN, 1.5, (0, 0, 255), 3)

                        if teeth_label != past_teeth_label:
                            doc_ref.set({'Direction' : int(rule_label[teeth_label])}, merge=True)

                cv2.imshow('image', image)
                
                if cv2.waitKey(150) == ord('q'):
                    break             

                client_socket.close()

        # 서버 끊김 방지를 위한 예외 처리
        except cv2.error:
            continue
        except ConnectionResetError:
            continue
        except binascii.Error:
            continue
        except AttributeError:
            continue

receive_image('0.0.0.0', 'PORT')  # 서버 IP와 포트번호 사용