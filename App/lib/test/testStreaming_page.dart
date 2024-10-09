import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:image/image.dart' as img;

import '../theme.dart';
import '../widget/PortableToothShape.dart';

class TestStreamingPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
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
          print('프레임 전송 완료'); // 프레임 전송 확인 메시지 추가
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
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);

      Future<void> _initializeCamera() async {
        final cameras = await availableCameras();
        final firstCamera = cameras[1];
        final cameraController = CameraController(
          firstCamera,
          ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.bgra8888,
        );
        await cameraController.initialize();
        await cameraController.lockCaptureOrientation(DeviceOrientation.landscapeRight);
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: controller.value == null || !controller.value!.value.isInitialized
          ? Center(child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 40))
          : Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: (){
                _stopStreaming();
                Navigator.pop(context);
              },
              child: Container(
                color: MAIN_COLOR,
                child: Center(
                  child: Text('테스트 종료', style: CONTANT_FONT_WHITE_BOLD),
                ),
              ),
            )
          ),
          Column(
            children: [
              Expanded(
                child: CameraPreview(controller.value!))
            ],
          ),
        ],
      ),
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
    final socket = await Socket.connect('34.64.188.216', 8080, timeout: Duration(seconds: 5));

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