import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:smartmirror_web_ui/theme.dart';

class AnimatedWave extends HookWidget {
  final double height;
  final double speed;
  final double offset;

  AnimatedWave({required this.height, required this.speed, this.offset = 0.0});

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: Duration(milliseconds: (5000 / speed).round()),
    )..repeat();

    final animation = useAnimation(
      Tween(begin: 0.0, end: 2 * pi).animate(animationController),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          width: constraints.biggest.width,
          child: CustomPaint(
            foregroundPainter: CurvePainter(animation + offset),
          ),
        );
      },
    );
  }
}

class CurvePainter extends CustomPainter {
  final double value;

  CurvePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = TOOTH_COLOR.withOpacity(0.2);
    final path = Path();

    final y1 = sin(value);
    final y2 = sin(value + pi / 2);
    final y3 = sin(value + pi);

    final startPointY = size.height * (0.5 + 0.4 * y1);
    final controlPointY = size.height * (0.5 + 0.4 * y2);
    final endPointY = size.height * (0.5 + 0.4 * y3);

    path.moveTo(0, startPointY);
    path.quadraticBezierTo(size.width * 0.5, controlPointY, size.width, endPointY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
