import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../theme.dart';

class TestModelPage extends HookConsumerWidget {
  TestModelPage({super.key});

  Future<int> loadModelAndPredict() async {
    try {
      // TFLite 인터프리터 생성
      final interpreter = await Interpreter.fromAsset('assets/model.tflite');
      // 입력 데이터 준비 (Float32List로 변환)
      var input = Float32List.fromList([1.112060546875, 0.147705078125, 0.215576171875]);
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
      return -1; // 오류 발생 시 -1 반환
    }
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictData = useState<int>(-1);

    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(
          title: Text('예측 모델 테스트', style: APPBAR_FONT),
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: BACKGROUND_COLOR,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () async {
              Navigator.pop(context);
            },
          )
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: GestureDetector(
              onTap: () async {
                predictData.value = await loadModelAndPredict();
              },
              child: Container(
                width: double.maxFinite,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: MAIN_COLOR,
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 7, spreadRadius: 1.5,)],
                ),
                child: Center(child: Text('예측', style: CONTANT_FONT_WHITE_BOLD)),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('예측 결과: ${predictData.value}', style: CONTANT_FONT_BLACK_BOLD),
            )
          ),
        ],
      ),
    );
  }
}
