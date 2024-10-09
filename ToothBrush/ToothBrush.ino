#include <Arduino.h>
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <string>
using namespace std;

//칫솔 설정
#define Floats 3 //보내는 소수 갯수
#define Mode 3 //보내는 데이터 갯수
//BLE 데이터 패킷 배열 설정
uint8_t Data_Packet[(Floats * 4) + Mode] = {0};
uint8_t Teach_Mode_Motor_Count[9] = {0};

uint8_t Brush_mode = 0; //양치질 모드, 0 : 검증모드, 1 : 지도모드
uint8_t Motor_Count = 0; // 진동이 몇 번 울렸는지 check
const float Limit_Accel = 1.7f; // 진동이 울리는 가속도 값

//GPIO핀 설정
#define MOTOR_PIN 10 //진동 모듈 핀
#define SDA_PIN 8 //I2C SDA핀
#define SCL_PIN 9 //I2C SCL핀
#define SWITCH_PIN 5 //택트 스위치 핀

//MPU-6050 설정
#define MPU_ADDR 0x68 // MPU-6050 I2C 주소
#define Limit_Accel 1.8 // 진동을 울리게 하는 가속도 최소값
#define MPU_Work_Period_ms 10 // 가속도 센서 작동 주기
#define Threshold 0.5 // 가속도 센서 조정 값
#define Max_Cnt 20 // 방향을 몇 번 샐지 정하는 값

//MPU-6050 변수
int16_t AcX, AcY, AcZ, Tmp, GyX, GyY, GyZ; // 가속도 센싱 값 
unsigned long MPU_6050_now, MPU_6050_before = 0; // MPU6050의 센싱 시간을 정할 때 사용하는 변수
float TotalAccel = 0.1f;//칫솔의 가속도 
uint8_t Direction_Cnt[26] = {0}; // 각 방향의 카운트
uint8_t Brush_Direction = 0; // 칫솔의 방향, 26방향

// 3축의 가속도 값
float accel_X = 0;
float accel_Y = 0;
float accel_Z = 0;


//MPU-6050 저역 필터 설정
#define ALPHA 0.5 //저역 통과 필터 상수 1~0의 값, 값이 클 수록 더 많은 필터링
float FilteredAcX = 0;
float FilteredAcY = 0;
float FilteredAcZ = 0;


//스위치 관련
uint8_t SW_cnt = 0;
bool SW_State = false;
unsigned long Switch_now, Switch_before = 0;

//BLE설정=========================================================================================
//BLE UUID설정=====================================================
#define SERVICE_UUID        "*******"//UUID 입력해야 함
#define CHARACTERISTIC_UUID "*******"//UUID 입력해야 함
//=================================================================

//BLE 디바이스 이름
String BLE_Device_name = "Smart_ToothBrush";

uint32_t value = 0;
bool deviceConnected = false;//현재 디바이스가 연결되어있으면 true
bool oldDeviceConnected = false;//과거에 디바이스가 연결되었으면 true
int reciveValue = 0;//블루투스로 전송 받은 값 int형

bool Data_Request = false;//데이터 전송 요청을 받으면 true
bool Data_Send = false; // 데이터를 전송하면 true

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
//================================================================================================

union FloatUnion{
  float value;
  uint8_t bytes[4];
};


void setup() {
  //Serial.begin(115200);
  MPU_6050_init();
  pinMode(SWITCH_PIN, INPUT_PULLUP);
  pinMode(MOTOR_PIN, OUTPUT);
  BLE_init();
}

void loop() {
  Switch_Read(SWITCH_PIN, 3000);//스위치 read, 3초가 넘었으면 칫솔질의 mode 변경
  MPU_6050_work(500);
  restart_esp();
  //ble가 연결되었을 때
  // if(deviceConnected){
  //   Send_BLE_Data();
  // }

  //블루투스 재연결 매서드
  // disconnecting
  if (!deviceConnected && oldDeviceConnected) {
    delay(200); // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising(); // restart advertising
    //Serial.println("start advertising");
    // Data_Request = false;
    // Data_Send = false;
    // reciveValue = 0;
    oldDeviceConnected = deviceConnected;
  }
  // connecting
  if (deviceConnected && !oldDeviceConnected) {
    // do stuff here on connecting
    oldDeviceConnected = deviceConnected;
  }
}

//ESP32 재시작
void restart_esp(){
  if(deviceConnected){
    if(reciveValue == 44){
      delay(1000);
      ESP.restart();
    }
  }
}

//MPU-6050 초기 설정
void MPU_6050_init(){//MPU_6050_초기 설정
  Wire.begin(SDA_PIN, SCL_PIN, 100000); // sda, scl
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(0x6B);  // PWR_MGMT_1 register
  Wire.write(0);     // set to zero (wakes up the MPU-6050)
  Wire.endTransmission(true); // I2C 제어권 반환 
  //Serial.println("MPU_6050_Setup complete");
}


//MPU-6050 동작
void MPU_6050_work(uint8_t delay_time_ms){
  
  MPU_6050_now = millis();
  if(MPU_6050_now - MPU_6050_before >= delay_time_ms){
    MPU_6050_before = MPU_6050_now;
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x3B);
    Wire.endTransmission(true);
    Wire.beginTransmission(MPU_ADDR);
    Wire.requestFrom(MPU_ADDR, 14, true);
    AcX = Wire.read() << 8 | Wire.read();
    AcY = Wire.read() << 8 | Wire.read();
    AcZ = Wire.read() << 8 | Wire.read();

    // 저역 통과 필터 적용
    FilteredAcX = ALPHA * AcX + (1 - ALPHA) * FilteredAcX;
    FilteredAcY = ALPHA * AcY + (1 - ALPHA) * FilteredAcY;
    FilteredAcZ = ALPHA * AcZ + (1 - ALPHA) * FilteredAcZ;

    //각 축의 가속도 계산
    accel_X = (float)AcX / 16384.0;
    accel_Y = (float)AcY / 16384.0;
    accel_Z = (float)AcZ / 16384.0;

    //칫솔의 가속력 계산
    TotalAccel = sqrt(pow(accel_X, 2) + pow(accel_Y, 2) + pow(accel_Z, 2));
    if(TotalAccel > Limit_Accel){//칫솔의 가속력이 일정 가속력을 넘으면
      //진동 모터 1초 ON
      digitalWrite(MOTOR_PIN, HIGH);
      delay(500);
      digitalWrite(MOTOR_PIN, LOW);
      if(Brush_mode == 0){
        Motor_Count++;//모터가 한 번 울림을 확인
      }
      if(Brush_mode == 1){
        Teach_Mode_Motor_Count[SW_cnt / 2] = Teach_Mode_Motor_Count[SW_cnt / 2] + 1;
      }
    }
    if(deviceConnected){
      Send_BLE_Data();
    }

    // Serial.print("스위치 상태 : "); Serial.println(SW_cnt);
    // Serial.print("accel_X : "); Serial.println(accel_X);
    // Serial.print("accel_Y : "); Serial.println(accel_Y);
    // Serial.print("accel_Z : "); Serial.println(accel_Z);
  }
}

void Send_BLE_Data(){
  //데이터 전송 요청 받았을 때
  // if(reciveValue == 1){
  //   Data_Request = true;
  // }

  //데이터 전송 요청을 받았지만 데이터를 보내지 않았을 때
  // if(Data_Request && !Data_Send){
    //ble 데이터 전송힘 
    FloatUnion X;
    X.value = accel_X;
    FloatUnion Y;
    Y.value = accel_Y;
    FloatUnion Z;
    Z.value = accel_Z;
    // FloatUnion Accel;
    // Accel.value = TotalAccel;
    
    //ble 데이터 보내기
    Data_Packet[0] = SW_cnt;
    Data_Packet[1] = Brush_mode;
    if(Brush_mode == 0){
      Data_Packet[2] = Motor_Count;
    }
    if(Brush_mode == 1){
      Data_Packet[2] = Teach_Mode_Motor_Count[SW_cnt / 2];
    }
    Data_Packet[3] = X.bytes[0];
    Data_Packet[4] = X.bytes[1];
    Data_Packet[5] = X.bytes[2];
    Data_Packet[6] = X.bytes[3];
    Data_Packet[7] = Y.bytes[0];
    Data_Packet[8] = Y.bytes[1];
    Data_Packet[9] = Y.bytes[2];
    Data_Packet[10] = Y.bytes[3];
    Data_Packet[11] = Z.bytes[0];
    Data_Packet[12] = Z.bytes[1];
    Data_Packet[13] = Z.bytes[2];
    Data_Packet[14] = Z.bytes[3];
    // Data_Packet[15] = Accel.bytes[0];
    // Data_Packet[16] = Accel.bytes[1];
    // Data_Packet[17] = Accel.bytes[2];
    // Data_Packet[18] = Accel.bytes[3];
    pCharacteristic->setValue(Data_Packet, sizeof(Data_Packet));
    pCharacteristic->notify();
    // Data_Send = true;// 데이터를 전송했음을 저장
  // }
  // //데이터 전송 받았음을 확인하면
  // if(reciveValue == 2){
  //   //관련 변수 초기화
  //   Data_Request = false;
  //   Data_Send = false;
  // }
}

void Switch_Read(uint8_t PIN, int SW_time_ms){
  if(!SW_State){//스위치 입력이 없었으면
    Switch_now = millis();// 입력이 없는 시간 최신화

    if(digitalRead(PIN) == LOW){// 입력이 없다가 스위치를 눌렀을 때
      SW_State = true; // 스위치를 눌렀음을 저장
    } 
  }
  else{//스위치 입력이 있는 상태이면
    
    if(digitalRead(PIN) == HIGH){//사용자가 스위치에서 손을 때면
      SW_cnt++; //스위치 카운트 + 1
      SW_State = false; // 스위치 입력이 없는 상태로 돌림
    }
    
    if(Switch_now + SW_time_ms <= millis()){ // 사용자가 3초 이상 스위치를 누르면
      //칫솔 모드 전환
      if(Brush_mode == 0){
        Brush_mode = 1;
      }else{
        Brush_mode = 0;
      }
      SW_cnt = 0; // 스위치 카운트 초기화
      Motor_Count = 0;
      for(int i = 0; i < 9; i++){
        Teach_Mode_Motor_Count[i] = 0;
      }
      //진동 모터 1초 ON
      digitalWrite(MOTOR_PIN, HIGH);
      delay(1000);
      digitalWrite(MOTOR_PIN, LOW);
      SW_State = false; // 스위치 입력이 없는 상태로 돌림
    }
  }
  if(Brush_mode == 0 && SW_cnt > 2){
    SW_cnt = 0;
  }
  if(Brush_mode == 1 && SW_cnt > 18){
    SW_cnt = 0;
    Brush_mode = 0;
  }
  delay(70);//스위치 디바운스
}

class MyServerCallbacks: public BLEServerCallbacks {//BLEServerCallbacks 상속
  void onConnect(BLEServer* pServer) { deviceConnected = true; };
  void onDisconnect(BLEServer* pServer) { deviceConnected = false; }
};

class MyCallbacks : public BLECharacteristicCallbacks {//BLECharacteristicCallbacks 상속
  void onWrite(BLECharacteristic *pCharacteristic) {
    String value = pCharacteristic->getValue(); // 쓰여진 값을 얻음
    if (value.length() > 0) {
      //Serial.println("Received value: " + String(value.c_str()));
      // 쓰여진 값을 int로 변환하여 reciveValue에 저장
      reciveValue = atoi(value.c_str());
      //Serial.println(reciveValue);
    }

  }
};

void BLE_init(){
    // BLE 초기화
      BLEDevice::init(BLE_Device_name);
      pServer = BLEDevice::createServer();
      pServer->setCallbacks(new MyServerCallbacks());

      BLEService *pService = pServer->createService(SERVICE_UUID);
      pCharacteristic = pService->createCharacteristic(
                              CHARACTERISTIC_UUID,
                              BLECharacteristic::PROPERTY_READ   |
                              BLECharacteristic::PROPERTY_WRITE  |
                              BLECharacteristic::PROPERTY_NOTIFY |
                              BLECharacteristic::PROPERTY_INDICATE
                          );
      pCharacteristic->addDescriptor(new BLE2902());
      pCharacteristic->setCallbacks(new MyCallbacks());
      pService->start();

      BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
      pAdvertising->addServiceUUID(SERVICE_UUID);
      pAdvertising->setScanResponse(false);
      pAdvertising->setMinPreferred(0x06);  // set value to 0x00 to not advertise this parameter
      BLEDevice::startAdvertising();
  }
