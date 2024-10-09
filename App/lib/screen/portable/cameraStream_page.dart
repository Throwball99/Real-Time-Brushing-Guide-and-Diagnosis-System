import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:simple_animation_progress_bar/simple_animation_progress_bar.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../provider/bluetooth_provider.dart';
import '../../provider/portable_provider.dart';
import '../../theme.dart';
import '../../widget/PortableToothShape.dart';

class CameraStreamingPage extends HookConsumerWidget {
  const CameraStreamingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bluetoothNotifier = ref.watch(bluetoothProvider);
    final portableNotifier = ref.watch(portableProvider);
    final controller = useState<CameraController?>(null);
    final isStreaming = useState(false);
    final lastImage = useState<CameraImage?>(null);
    final isolate = useState<Isolate?>(null);
    final sendPort = useState<SendPort?>(null);

    Future<void> _initializeIsolate() async {
      final receivePort = ReceivePort();
      isolate.value = await Isolate.spawn(isolateEntry, receivePort.sendPort);
      sendPort.value = await receivePort.first;
    }

    Future<void> _processAndSendFrame(CameraImage image) async {
      try {
        if (sendPort.value != null) {
          final responsePort = ReceivePort();
          sendPort.value!.send([image, responsePort.sendPort]);
          await responsePort.first;
          responsePort.close();
          print('프레임 전송 완료');
        }
      } catch (e) {
        print('프레임 전송 에러: $e');
      }
    }

    Future<void> _processFrames() async {
      while (isStreaming.value) {
        if (lastImage.value != null) {
          await _processAndSendFrame(lastImage.value!);
        }
        await Future.delayed(Duration(milliseconds: 250));
      }
    }

    void _startStreaming() {
      isStreaming.value = true;
      controller.value?.startImageStream((CameraImage image) {
        lastImage.value = image;
      });

      _processFrames();
    }

    Future<void> _stopStreaming() async {
      isStreaming.value = false;
      controller.value?.stopImageStream();
      lastImage.value = null;
      if (isolate.value != null) {
        isolate.value!.kill(priority: Isolate.immediate);
        isolate.value = null;
      }
    }

    useEffect(() {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft,]);
      Future<void> _initializeCamera() async {
        final cameras = await availableCameras();
        final firstCamera = cameras[1];
        final cameraController = CameraController(
          firstCamera,
          ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.bgra8888, // RGBA 포맷 사용
        );
        await cameraController.initialize();
        await cameraController.lockCaptureOrientation(
            DeviceOrientation.landscapeRight
        );
        if (context.mounted) {
          controller.value = cameraController;
        }
      }

      _initializeCamera().then((_) => _initializeIsolate()).then((_) => _startStreaming());
      return () {
        controller.value?.dispose();
        SystemChrome.setPreferredOrientations([]);
      };
    }, []);


    return portableNotifier.when(
      data: (portableData) {
        final timeList = useState<List<int>>([0,0,0,0,0,0,0,0,0,0,0,0,0]);
        final motorCountList = useState<List<int>>([0,0,0,0,0,0,0,0,0,0,0,0,0]);
        final Brush_Direction = useState<int>(0); // 현재 방향
        final previousMoterCount = useState<int>(0); // 이전 모터 카운트
        final modeExecuted = useState(false); // 모드 0 실행 여부
        final streamController = useRef<StreamController<void>?>(null); // StreamController를 useRef로 관리

        useEffect(() {
          // StreamController 초기화
          streamController.value = StreamController<void>.broadcast();
          // bluetoothNotifier.mode의 변화를 감지하기 위해 의존성 배열에 추가
          final stream = Stream.periodic(Duration(seconds: 1));
          StreamSubscription? subscription;
          void startListening() {
            subscription = stream.listen((_) {
              if (Brush_Direction.value >= 0 && Brush_Direction.value < timeList.value.length) {
                timeList.value[Brush_Direction.value] += 1; // 1초마다 값 증가
                print(timeList.value);
              }
            });
          }
          // bluetoothNotifier.mode에 따라 스트림을 시작하거나 중지
          if (bluetoothNotifier.mode == 1) {
            startListening();
          } else {
            subscription?.cancel();
          }
          // Cleanup 함수: useEffect가 클린업을 할 때 호출됨
          return () {
            subscription?.cancel(); // Stream 구독 취소
            streamController.value?.close(); // StreamController 닫기
          };
        }, [bluetoothNotifier.mode]); // bluetoothNotifier.mode의 변화를 감지

        useEffect(() {
          if(bluetoothNotifier.mode == 0) {
            print('모드 0, 대기중');
            modeExecuted.value = false;
          } else if (bluetoothNotifier.mode == 1) {
            print('모드 1, 실행중');
            modeExecuted.value = false;
          } else if (bluetoothNotifier.mode == 2 && modeExecuted.value == false) {
            DateTime now = DateTime.now();
            List<double> timeArray = timeList.value.map((e) => e.toDouble()).toList(); // time_array
            List<double> motorArray = motorCountList.value.map((e) => e.toDouble()).toList(); // motor_array
            String currentDate = DateFormat('yyyy-MM-ddTHH:mm:ss').format(now);

            // 데이터 업로드 작업
            for (int i = 0; i < timeArray.length; i++) {
              addCategoryData(currentDate, i.toString(), timeArray[i].toString(), motorArray[i].toString());
            }
            print('업로드 완료');
            print(timeArray);
            print(motorArray);
            modeExecuted.value = true; // 작업이 실행된 후 플래그를 설정
          } else {
            print('잘못된 모드입니다.');
            modeExecuted.value = false; // 모드가 2가 아닐 때 플래그 초기화
          }
        }, [bluetoothNotifier.mode]);

        useEffect(() {
          int Video_Direction = portableData.direction;
          int MPU_6050_Direction = bluetoothNotifier.predictClass;

          if(bluetoothNotifier.mode ==1) {
            if(Video_Direction >= 6 && Video_Direction <= 8){
              Brush_Direction.value = Video_Direction;
            } else {
              if(MPU_6050_Direction == 0){
                Brush_Direction.value = Video_Direction;
              } else {
                Brush_Direction.value = MPU_6050_Direction + 8;
              }
            }
          }
        }, [portableData.direction, bluetoothNotifier.predictClass]);

        useEffect(() {
          if(bluetoothNotifier.mode == 1) {
            if(bluetoothNotifier.motorCount > previousMoterCount.value){
              motorCountList.value[Brush_Direction.value] = bluetoothNotifier.motorCount;
            }
            previousMoterCount.value = bluetoothNotifier.motorCount;
          }
        }, [bluetoothNotifier.motorCount]);

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: controller.value == null || !controller.value!.value.isInitialized
                ? Center(child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 40))
                : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: bluetoothNotifier.mode == 0
                      ? Container(
                          decoration: BoxDecoration(
                          color: MAIN_COLOR,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    _stopStreaming();
                                    try {
                                      await bluetoothNotifier.sendString('44');
                                    } catch (e) {
                                      print('블루투스 종료 에러: $e');
                                    } finally {
                                      await Future.delayed(Duration(seconds: 1));
                                      bluetoothNotifier.disconnect();
                                    }
                                    Navigator.pop(context);
                                    updatePortableStatus(false);
                                  },
                                  icon: Icon(Icons.arrow_back_ios_new, color: Colors.white,),
                                ),
                                Text('칫솔 버튼을\n눌러 시작', style: CONTANT_FONT_WHITE_BOLD, textAlign: TextAlign.center,),
                                Text('')
                              ],
                            ),
                          )
                         )
                      :
                  bluetoothNotifier.mode == 1
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Container(
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: Colors.white12,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 7, spreadRadius: 1.5,)],),
                              child: Center(child: Text('칫솔 버튼을\n눌러 종료', style: CONTANT_FONT_WHITE_BOLD, textAlign: TextAlign.center,)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: FittedBox(
                                fit: BoxFit.fill,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 350,
                                      height: 120,
                                      color: Colors.transparent,
                                      child: PortableTopToothShape(
                                        selectedNumber: Brush_Direction.value,
                                        timeList: timeList.value,
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Container(
                                      width: 350,
                                      height: 120,
                                      color: Colors.transparent,
                                      child: PortableDownToothShape(
                                        selectedNumber: Brush_Direction.value,
                                        timeList: timeList.value,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      :
                  GestureDetector(
                    onTap: () async {
                      _stopStreaming();
                      try {
                        await bluetoothNotifier.sendString('44');
                      } catch (e) {
                        print('블루투스 종료 에러: $e');
                      } finally {
                        await Future.delayed(Duration(seconds: 1));
                        bluetoothNotifier.disconnect();
                      }
                      Navigator.pop(context);
                      updatePortableStatus(false);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: MAIN_COLOR,),
                      child: Center(child: Text('종료하기', style: CONTANT_FONT_WHITE_BOLD)),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Expanded(
                        child: CameraPreview(controller.value!))
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Center(child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 40)),
      error: (error, stackTrace) => Text("Error: $error"),
    );
  }
}

void isolateEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is List && message.length == 2 && message[0] is CameraImage) {
      final CameraImage image = message[0];
      final SendPort responsePort = message[1];

      processFrame(image).then((_) {
        responsePort.send(null);  // 처리 완료 신호
      });
    }
  });
}

Future<void> processFrame(CameraImage image) async {
  try {
    final socket = await Socket.connect('', 8080, timeout: Duration(seconds: 5));

    img.Image capturedImage = convertBGRA8888toImage(image);
    img.Image resizedImage = img.copyResize(capturedImage, width: 640, height: 480);
    Uint8List pngBytes = Uint8List.fromList(img.encodePng(resizedImage));
    String base64Image = base64Encode(pngBytes);

    socket.add(utf8.encode(base64Image));
    await socket.flush();
    socket.close();
    print('Isolate: 프레임 처리 및 전송 완료');
  } catch (e) {
    print('프레임 전송 에러: $e');
  }
}

img.Image convertBGRA8888toImage(CameraImage image) {
  return img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: image.planes[0].bytes.buffer,
    order: img.ChannelOrder.bgra,
  );
}