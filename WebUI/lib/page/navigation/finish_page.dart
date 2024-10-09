import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gif/gif.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../firestore_provider.dart';
import '../../theme.dart';

class FinishPage extends HookConsumerWidget {
  FinishPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.delayed(Duration(seconds: 1), () {
        Confetti.launch(
          context,
          options: const ConfettiOptions(
              particleCount: 100, spread: 360, y: 0.4),
        );
      });
      return () {};
    }, []);
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Center(
            child: Container(),
          ),
        ),
        Expanded(
          flex: 8,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 350,
                  height: 100,
                  decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Center(
                    child: Text(
                      "양치가 완료되었습니다!",
                      style: NOTICE_FONT_WHITE_BOLD,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Text('칫솔 버튼을 눌러 종료하세요', style: CONTANT_FONT_WHITE_THIN),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Center(
            child: Container(),
          ),
        ),
      ],
    );
  }
  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (3.14159265359 / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}
