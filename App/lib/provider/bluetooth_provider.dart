import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

final bluetoothProvider = ChangeNotifierProvider((ref) => BluetoothNotifier());

class BluetoothNotifier extends ChangeNotifier {
  // CHARACTERISTIC_UUID를 명시적으로 지정
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;
  List<int> _receivedData = [];
  BluetoothCharacteristic? _writeCharacteristic;
  int? _mode;
  int _motorCount = 0;
  int _predictClass = -1;
  // double? _xAccel;
  // double? _yAccel;
  // double? _zAccel;
  // List<int> _dataArray = [];
  bool _mode2Executed = false;


  List<BluetoothDevice> get devices => _devices;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<int> get receivedData => _receivedData;
  int? get mode => _mode;
  int get motorCount => _motorCount;
  int get predictClass => _predictClass;
  bool get mode2Executed => _mode2Executed;
  // double? get xAccel => _xAccel;
  // double? get yAccel => _yAccel;
  // double? get zAccel => _zAccel;
  // List<int> get dataArray => _dataArray;

  BluetoothNotifier() {
    FlutterBluePlus.state.listen((state) {
      if (state == BluetoothState.off) {
        disconnect();
      }
    });

    _monitorConnection();
  }

  void _monitorConnection() {
    Stream.periodic(Duration(seconds: 5)).asyncMap((_) => FlutterBluePlus.connectedDevices).listen((devices) {
      if (_connectedDevice != null && !devices.contains(_connectedDevice)) {
        _reconnect();
      }
    });
  }

  void startScan() async {
    _devices.clear();
    notifyListeners();
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      _devices = results.map((r) => r.device).toSet().toList();
      notifyListeners();
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;
      notifyListeners();
      await discoverServices(device);
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  Future<void> disconnect() async {
    _connectedDevice?.disconnect();
    _connectedDevice = null;
    _receivedData = [];
    _writeCharacteristic = null;
    _mode = null;
    _motorCount = 0;
    _predictClass = -1;
    // _xAccel = null;
    // _yAccel = null;
    // _zAccel = null;
    // _dataArray = [];
    notifyListeners();
  }

  Future<void> _reconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.connect();
        await discoverServices(_connectedDevice!);
        notifyListeners();
      } catch (e) {
        print('Error reconnecting to device: $e');
      }
    }
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
          if (characteristic.properties.read) {
            await characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              _handleReceivedData(value);
            });
          }
          if (characteristic.properties.write) {
            _writeCharacteristic = characteristic;
          }
        }
      }
    }
  }

  int sumList(List<int> list) {
    return list.fold(0, (prev, element) => prev + element);
  }

  // void _handleReceivedData(List<int> data) {
  //   _receivedData = data;
  //   if(receivedData.length < 2) {
  //     return;
  //   } else {
  //     _mode = _receivedData.isNotEmpty ? _receivedData[0] : null;
  //     _dataArray = _receivedData.length > 1 ? _receivedData.sublist(1) : [];
  //
  //     if (_mode == 0) {
  //       print('모드 0, 대기중');
  //       _mode2Executed = false; // 모드 0이 될 때마다 플래그 초기화
  //     } else if (_mode == 1) {
  //       print('Received data: $_dataArray');
  //       _mode2Executed = false; // 모드 1이 될 때마다 플래그 초기화
  //     } else if (_mode == 2 && !_mode2Executed) {
  //       DateTime now = DateTime.now();
  //       List<int> time_array = _dataArray.sublist(0, 10);
  //       List<int> motor_array = _dataArray.sublist(10);
  //       String currentDate = DateFormat('yyyy-MM-ddTHH:mm:ss').format(now);
  //       for (int i = 0; i < 9; i++) {
  //         addCategoryData(currentDate, i.toString(), time_array[i].toString(), motor_array[i].toString());
  //       }
  //       print('업로드 완료');
  //       _mode2Executed = true; // 작업이 실행된 후 플래그를 설정
  //     } else if (_mode != 2) {
  //       print('Unknown mode: $_mode');
  //       _mode2Executed = false; // 모드가 2가 아닐 때 플래그 초기화
  //     }
  //   }
  //   notifyListeners();
  // }

  void _handleReceivedData(List<int> data) {
    // 데이터 배열을 저장
    _receivedData = data;

    // 모드, 스위치 카운트, 모터 카운트, 가속도 데이터를 추출
    _mode = _receivedData[0];   // 스위치 카운트
    int brushMode = _receivedData[1]; // 칫솔 모드
    _motorCount = _receivedData[2]; // 모터 카운트

    // 가속도 데이터를 해석 (각 4바이트의 float 데이터)
    double xAccel = _byteArrayToFloat(_receivedData.sublist(3, 7));
    double yAccel = _byteArrayToFloat(_receivedData.sublist(7, 11));
    double zAccel = _byteArrayToFloat(_receivedData.sublist(11, 15));

    loadModelAndPredict(xAccel, yAccel, zAccel).then((value) {
      _predictClass = value;
    });
    //
    notifyListeners();
  }

  Future<int> loadModelAndPredict(x,y,z) async {
    try {
      // TFLite 인터프리터 생성
      final interpreter = await Interpreter.fromAsset('assets/model.tflite');
      // 입력 데이터 준비 (Float32List로 변환)
      var input = Float32List.fromList([x, y, z]);
      // 출력 텐서 준비 (크기는 모델의 출력 크기에 맞게 설정)
      var output = List.filled(5, 0.0).reshape([1, 5]);
      // 모델 실행
      interpreter.run(input, output);
      // 최대값을 찾고 그 인덱스를 반환
      List<double> outputList = output[0];
      double maxValue = outputList.reduce((a, b) => a > b ? a : b);
      int predictedClass = outputList.indexOf(maxValue);
      print('예측된 클래스: $predictedClass');
      return predictedClass;
    } catch (e) {
      print('모델 로드 또는 예측 오류: $e');
      return -1;
    }
  }

  // 바이트 배열을 float로 변환하는 함수
  double _byteArrayToFloat(List<int> bytes) {
    final byteData = ByteData.sublistView(Uint8List.fromList(bytes));
    return byteData.getFloat32(0, Endian.little);
  }

  Future<void> sendString(String direction) async {
    if (_connectedDevice == null) {
      throw BluetoothException('No device connected');
    }
    if (_writeCharacteristic == null) {
      throw BluetoothException('Write characteristic is not available');
    }
    try {
      String data = direction.toString();
      List<int> encodedData = utf8.encode(data);  // UTF-8 인코딩 사용

      await _writeCharacteristic!.write(encodedData, withoutResponse: false);
      print('Successfully sent: $direction');
    } catch (e) {
      print('Error while sending data: $e');
      throw BluetoothException('Failed to send data: ${e.toString()}');
    }
  }
}

class BluetoothException implements Exception {
  final String message;
  BluetoothException(this.message);

  @override
  String toString() => 'BluetoothException: $message';
}

final FirebaseFirestore db = FirebaseFirestore.instance;

Future<void> addCategoryData(String date, String side, String time, String count) async {
  DocumentReference dateDocRef = db.collection('date').doc(date);
  DocumentReference sideDocRef = dateDocRef.collection('categories').doc(side);

  await dateDocRef.set({'dateField': date});
  Map<String, String> sideData = {
    'side': side,
    'time': time,
    'count': count
  };
  await sideDocRef.set(sideData);
}