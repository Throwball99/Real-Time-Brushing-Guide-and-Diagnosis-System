  #include <Arduino.h>
  #include <Wire.h>
  #include <BLEDevice.h>
  #include <BLEServer.h>
  #include <BLEUtils.h>
  #include <BLE2902.h>
  using namespace std;

  //GPIO핀 설정=====================================================================================
  #define MOTOR_PIN 10 //진동 모듈 핀
  #define SDA_PIN 8 //I2C SDA핀
  #define SCL_PIN 9 //I2C SCL핀
  #define SWITCH_PIN 5 //택트 스위치 핀
  //================================================================================================


  //택트 스위치 설정=================================================================================
  bool Switch_Before_Push = false;
  int Switch_Count = 0;
  int Switch_times = 0;
  unsigned int Switch_now, Switch_before = 0;
  //================================================================================================


  //MPU-6050 설정===================================================================================
  const int MPU_ADDR = 0x68; // MPU-6050 I2C 주소
  const float Limit_Accel = 1.7f;//진동이 울리는 가속도 값
  const unsigned char Vib_Second = 1; //진동이 울리는 시간(초)

  //변수========================================================
  int16_t AcX, AcY, AcZ, Tmp, GyX, GyY, GyZ; // 가속도 센싱 값 
  unsigned char x_count, y_count, z_count;// 어느 방향의 값이 가장 많은지 체크
  String MPU_6050_direction;//mpu6050의 방향
  int MPU_6050_now, MPU_6050_before = 0; // MPU6050의 센싱 시간을 정할 때 사용하는 변수
  float totalAccel = 0;//칫솔의 가속도 
  //================================================================================================

  unsigned int Vib_motor_before = 0;
  unsigned int Vib_motor_now = 0;
  bool Vib_motor_on = false;

  //BLE설정=========================================================================================
  //BLE UUID설정=====================================================
  #define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
  #define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
  //=================================================================

  //BLE 디바이스 이름
  String BLE_Device_name = "Smart_ToothBrush";

  uint32_t value = 0;
  bool deviceConnected = false;//현재 디바이스가 연결되어있으면 true
  bool oldDeviceConnected = false;//과거에 디바이스가 연결되었으면 true
  int reciveValue = 0;//블루투스로 전송 받은 값 int형


  BLEServer* pServer = NULL;
  BLECharacteristic* pCharacteristic = NULL;
  //================================================================================================



  //칫솔 설정========================================================================================
  bool Vib_Motor_on = false; // 모터가 작동하면 true, 작동하지 않으면 false
  unsigned char  brush_time[10]; //0~9 Left_Up ~ Right_front 시간 
  unsigned char motor_count[10]; //0~9 Left_Up ~ Right_front의 각 동작 동안 모터가 울린 카운트 
  int error_time = 0; //검출 불가일 때 카운트 하는 변수 
  int brush_now, brush_before = 0;
 // int teach_now, teach_before = 0;
  bool Brush_mode = true;

  bool mode2_process = false;

  //지도 모드
  unsigned char Data_Packet[4];
  unsigned char dumi[4];
  bool state = false;
  unsigned int teach_now = 0;
  unsigned int teach_before = 0;
  //================================================================================================


  //BLE Class=======================================================================================
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
  //================================================================================================


  //센서 및 기능 설정 함수===========================================================================

  void MPU_6050_init(){//MPU_6050_초기 설정
      Wire.begin(SDA_PIN, SCL_PIN, 100000); // sda, scl
      Wire.beginTransmission(MPU_ADDR);
      Wire.write(0x6B);  // PWR_MGMT_1 register
      Wire.write(0);     // set to zero (wakes up the MPU-6050)
      Wire.endTransmission(true); // I2C 제어권 반환 
      //Serial.println("MPU_6050_Setup complete");
  }

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
  //================================================================================================


  //MPU-6050동작 함수================================================================================
  void MPU_6050_work(unsigned char delay_time_ms/*, unsigned char direction_check_num*/){

      MPU_6050_now = millis();
      if(MPU_6050_now - MPU_6050_before >= delay_time_ms){
          MPU_6050_before = MPU_6050_now;
          Wire.beginTransmission(MPU_ADDR);
          Wire.write(0x3B);  // starting with register 0x3B (ACCEL_XOUT_H)
          Wire.endTransmission(true);
          Wire.beginTransmission(MPU_ADDR);
          Wire.requestFrom(MPU_ADDR, 14, true); // request a total of 14 registers
          AcX = Wire.read() << 8 | Wire.read(); // 0x3B (ACCEL_XOUT_H) & 0x3C (ACCEL_XOUT_L)
          AcY = Wire.read() << 8 | Wire.read(); // 0x3D (ACCEL_YOUT_H) & 0x3E (ACCEL_YOUT_L)
          AcZ = Wire.read() << 8 | Wire.read(); // 0x3F (ACCEL_ZOUT_H) & 0x40 (ACCEL_ZOUT_L)
          //Serial.print("x축 : "); Serial.print(AcX); Serial.print("y축 : "); Serial.print(AcY);
          //Serial.print("z축 : "); Serial.println(AcZ);
          /*if(!Brush_mode){
            int16_t abs_AcX = abs(AcX); int16_t abs_AcY = abs(AcY); int16_t abs_AcZ = abs(AcZ);

            if(abs_AcX > abs_AcY && abs_AcX > abs_AcZ){
              x_count++;
            } 
            else if(abs_AcY > abs_AcX && abs_AcY > abs_AcZ){
              y_count++;
            }
            else{
              z_count++;
            }
            int direction_check_num = 10;
            if(x_count == direction_check_num){
              if(AcX > 0) MPU_6050_direction = "x";
              if(AcX < 0) MPU_6050_direction = "-x";
              x_count = 0; y_count = 0; z_count = 0;
            }
            if(y_count == direction_check_num){
              if(AcY > 0) MPU_6050_direction = "y";
              if(AcY < 0) MPU_6050_direction = "-y";
              x_count = 0; y_count = 0; z_count = 0;
            }
            if(z_count == direction_check_num){
              if(AcZ > 0) MPU_6050_direction = "z";
              if(AcZ < 0) MPU_6050_direction = "-z";
              x_count = 0; y_count = 0; z_count = 0;
            }
          }*/

          float accel_X = (float)AcX / 16384.0;
          float accel_y = (float)AcY / 16384.0;
          float accel_z = (float)AcZ / 16384.0;
          totalAccel = sqrt(pow(accel_X, 2) + pow(accel_y, 2) + pow(accel_z, 2));//가속도 구하기, 세 벡터의 내적
          //Serial.print(totalAccel); Serial.print(MPU_6050_direction); Serial.print("\n");
      }
  }
  //================================================================================================

  //칫솔 기능 동작 함수==============================================================================
  /*void Vib_motor_work(int Work_time_sec, float Brush_accel, float Max_accel){
    
    if((Brush_accel > Max_accel)&& (Vib_motor_on == false)) {//칫솔의 가속도가 Max_accel을 넘으면
      Vib_motor_on = true;
      Vib_motor_now = millis();
      motor_count[reciveValue] = motor_count[reciveValue] + 1;
    }
    if(Vib_motor_on == true){
      if(Vib_motor_now + (Work_time_sec * 1000) > millis()){
        digitalWrite(MOTOR_PIN, HIGH);
      }else{
        digitalWrite(MOTOR_PIN, LOW);
        Vib_motor_on = false;
      }
    }
  }*/

  void Vib_motor_work(int Work_time_sec, float Brush_accel, float Max_accel){
    if(Brush_accel > Max_accel){
      digitalWrite(MOTOR_PIN, HIGH);
      delay(Work_time_sec);
      digitalWrite(MOTOR_PIN, LOW);
      motor_count[reciveValue] = motor_count[reciveValue] + 1;
    }

  }

  void brush_time_return_vib_control(int Data){
    Vib_motor_work(1000, totalAccel, Limit_Accel); // 칫솔의 가속도가 2.5g를 넘을 시 1초동안 진동모터 on
    brush_now = millis(); 
    if(brush_now - brush_before > 1000){
      brush_time[Data] = brush_time[Data] + 1;
      
      unsigned char Data_Pakage[21];
      Data_Pakage[0] = 1;
      for(int i = 1; i < 11; i++){
        Data_Pakage[i] = brush_time[i-1];
        Data_Pakage[i+10] = motor_count[i-1];
      }
      pCharacteristic->setValue(Data_Pakage, sizeof(Data_Pakage));
      //Serial.println(Data_Pakage));
      pCharacteristic->notify();
      brush_before = brush_now;
    }
  }

  void process_brush(int Data){
    if (Data >= 0 && Data < 10) { // GCP_Data가 0에서 9 사이인 경우에만 처리
          brush_time_return_vib_control(Data);
      }
  }

  void teach_mode(int Data, int Switch_cnt, int Data_num){
    if(Switch_cnt == Data_num + 1){
      Data_Packet[0] = Data_num + 4;
      teach_now = millis();
      if(teach_now - teach_before > 1000){
        Data_Packet[1] = Data_Packet[1] + 1;
        if(Data_Packet[1] > 5){
          if(Switch_cnt < 10){
            if(Data_Packet[2] + Data_Packet[3] < 30){

              if(Data == Data_num){
                Data_Packet[2] = Data_Packet[2] + 1;
                //Serial.print("시간 : "); Serial.println(Data_Packet[1]);
              }else{
                Data_Packet[3] = Data_Packet[3] + 1;
              }
            }else{
              digitalWrite(MOTOR_PIN, HIGH);
              delay(2000);
              digitalWrite(MOTOR_PIN, LOW);
              delay(5*1000);
              Data_Packet[1] = 0;
              Data_Packet[2] = 0;
              Data_Packet[3] = 0;
              state = false;
              }
          }else{
            if(brush_now + (1000*5) < millis()){
              Brush_mode = true;
              Switch_times = 0;
            }
          }
        }
        teach_before = teach_now;
      }
    }
  }

  void Brush_teach_mode(int Data, int Switch_cnt){

    if(state == false){
      dumi[0] = 3;
      dumi[1] = 0;
      dumi[2] = 0;
      dumi[3] = 0;
      pCharacteristic->setValue(dumi, sizeof(dumi));
      pCharacteristic->notify();
      delay(100);
      brush_now = millis();
    }
    else{
      for(int i = 0; i < 10; i++){
        teach_mode(Data, Switch_cnt, i);
      }
      pCharacteristic->setValue(Data_Packet, sizeof(Data_Packet));
      // Serial.print("전송하는 값 : "); Serial.print(Data_Packet[0]); Serial.print("/"); Serial.print(Data_Packet[1]); Serial.print("/");
      // Serial.print(Data_Packet[2]); Serial.print("/"); Serial.println(Data_Packet[3]);
      pCharacteristic->notify();
      delay(250);
    }
    
  }

  //================================================================================================


  //스위치 제어======================================================================================
  int Switch_Read(unsigned char PIN){
    if(Switch_Before_Push == false){//스위치 입력이 없었으면
      Switch_now = millis();
      if(digitalRead(PIN) == LOW){//스위치를 눌렀을 때
        Switch_Before_Push = true;//스위치를 눌렀음을 저장
      }
    }else{//스위치 입력이 있었을 때
      if(digitalRead(PIN) == HIGH){//사용자가 스위치에서 손을 때면
        if((state == false)&&(!Brush_mode)){
          state = true;
        }
        Data_Packet[1] = 0;
        Data_Packet[2] = 0;
        Data_Packet[3] = 0;
        Switch_Count++;//스위치를 한번 눌렀음을 ++해서 알림
        brush_now = millis();
        if(Switch_now + 3000 <= millis()){//3초 이상 눌렀을 때
          Brush_mode = !Brush_mode;
          digitalWrite(MOTOR_PIN, HIGH);
          delay(1000);
          digitalWrite(MOTOR_PIN, LOW);
          Switch_Count = 0;
          state = false;
        }
        delay(50);//디바운스
        Switch_Before_Push = false;//스위치 동작이 한 번 이루어졌기에 false로 돌림
      }
    }
    if(Brush_mode){
      if(Switch_Count > 2){
        Switch_Count = 0;
      }
    }else{
      if(Switch_Count > 10){
        Switch_Count = 0;
        Brush_mode = true;
      }
    }
    
    return Switch_Count;
  }


  void setup() {
    //Serial.begin(115200);
    pinMode(MOTOR_PIN, OUTPUT);
    pinMode(SWITCH_PIN, INPUT_PULLUP);
    MPU_6050_init();
    BLE_init();
    brush_before = millis();
  }

  void loop() {
    MPU_6050_work(500);
    if (deviceConnected) { //블루투스가 연결되면
      Switch_times = Switch_Read(SWITCH_PIN);
      if(reciveValue == 44){
        delay(1000);
        ESP.restart();
      }
      if(Brush_mode){// 양치질 검증 모드일 때
        if(Switch_times == 0){
          if(Brush_mode){
            for(int i = 0; i < 10; i++){
              brush_time[i] = 0; 
              motor_count[i] = 0;
            }
            unsigned char Data_dumi[21] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
            pCharacteristic->setValue(Data_dumi, sizeof(Data_dumi));
            pCharacteristic->notify();
            delay(100);
          }
        }
        if(Switch_times == 1){
          if(Brush_mode){
            //Serial.println(reciveValue);
            process_brush(reciveValue);
            //Vib_motor_work(700, totalAccel, Limit_Accel); // 칫솔의 가속도가 2.5g를 넘을 시 1초동안 진동모터 on
            //brush_time_return_vib_control(reciveValue);
          }
        }
        if(Switch_times == 2){
          if(Brush_mode){
            unsigned char End_Data[21];
            End_Data[0] = Switch_times;
            for(int i = 1; i < 11; i++){
              End_Data[i] = brush_time[i-1];
              End_Data[i+10] = motor_count[i-1];
            }
            
            pCharacteristic->setValue(End_Data, sizeof(End_Data));
            pCharacteristic->notify();

          }
        }
      }else{// 양치질 지도 모드일 때
        Brush_teach_mode(reciveValue, Switch_times);
      }
    }
    // disconnecting
    if (!deviceConnected && oldDeviceConnected) {
      delay(500); // give the bluetooth stack the chance to get things ready
      pServer->startAdvertising(); // restart advertising
      //Serial.println("start advertising");
      oldDeviceConnected = deviceConnected;
    }
    // connecting
    if (deviceConnected && !oldDeviceConnected) {
      // do stuff here on connecting
      oldDeviceConnected = deviceConnected;
    }
    delay(20);
  }