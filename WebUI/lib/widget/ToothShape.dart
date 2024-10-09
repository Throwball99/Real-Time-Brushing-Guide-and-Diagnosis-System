import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:smartmirror_web_ui/theme.dart';

class TopToothShape extends HookWidget {
  final int selectedNumber;
  final List<int> timeList;


  const TopToothShape({Key? key, required this.selectedNumber, required this.timeList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(duration: const Duration(seconds: 1));
    final blurAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
      ),
    );
    final isAnimating = useState<List<bool>>(List.generate(15, (index) => false));

    useEffect(() {
      if (timeList[0] == 15 || timeList[1] == 15 || timeList[2] == 15 ||
          timeList[3] == 15 || timeList[4] == 15 || timeList[5] == 15 ||
          timeList[6] == 15 || timeList[7] == 15 || timeList[8] == 15 ||
          timeList[9] == 15 || timeList[10] == 15 || timeList[11] == 15 ||
          timeList[12] == 15) {
        animationController.forward().then((_) {
          animationController.reverse();
        });
      }
      return null;
    }, [timeList]);
    return CustomPaint(
      size: Size(350, 120),
      painter: TopToothShapePainter(
        animation: blurAnimation,
        selectedNumber: selectedNumber,
        timeList: timeList,
        isAnimating: isAnimating.value,
      ),
    );
  }
}

class TopToothShapePainter extends CustomPainter {
  final double animation;
  final int selectedNumber;
  final List<int> timeList;
  final List<bool> isAnimating;

  TopToothShapePainter({required this.selectedNumber, required this.timeList, required this.animation, required this.isAnimating});

  @override
  void paint(Canvas canvas, Size size) {
    double radius = 20.0;

    var shadowPaint = Paint()
      ..color = Color(0xff7882A4)
      ..maskFilter = MaskFilter.blur(BlurStyle.inner, 1);

    var shadowPaint2 = Paint()
      ..color = Color(0xffbbc0d1)
      ..maskFilter = MaskFilter.blur(BlurStyle.inner, 1);

    var shadowPaint3 = Paint()
      ..color = Colors.white
      ..maskFilter = MaskFilter.blur(BlurStyle.inner, 1);

    var glowPaint1 = Paint()
      ..color = MAIN_COLOR
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 20);

    var glowPaint2 = Paint()
      ..color = Colors.lightBlueAccent
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);

    var toothPaint = Paint()
      ..color = Color(0xffb3b4b7)
      ..style = PaintingStyle.fill;

    var toothPaint2 = Paint()
      ..color = Color(0xffe3e3e5)
      ..style = PaintingStyle.fill;

    var toothPaint3 = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    List<Offset> middleTop = [
      Offset(size.width * 0.28, radius + 15),
      Offset(size.width * 0.37, radius + 7),
      Offset(size.width * 0.46, radius),
      Offset(size.width * 0.54, radius),
      Offset(size.width * 0.63, radius + 7),
      Offset(size.width * 0.72, radius + 15),
    ];

    List<Offset> leftTop = [
      Offset(radius + 38, size.height * 0.65 - radius),
      Offset(radius + 15, size.height * 0.80 - radius),
      Offset(radius, size.height - radius),
    ];

    List<Offset> rightTop = [
      Offset(size.width - radius - 38, size.height * 0.65 - radius),
      Offset(size.width - radius - 15, size.height * 0.8 - radius),
      Offset(size.width - radius, size.height - radius),
    ];

    Path createCirclePath(List<Offset> centers, double radius) {
      var path = Path();
      for (var center in centers) {
        path.addOval(Rect.fromCircle(center: center, radius: radius));
      }
      return path;
    }

    var middleTopPath = createCirclePath(middleTop, radius);
    if(selectedNumber == 1) {
      canvas.drawPath(middleTopPath, glowPaint1);
      canvas.drawPath(middleTopPath, glowPaint1);
      canvas.drawPath(middleTopPath, glowPaint1);
    } else if(selectedNumber == 7) {
      canvas.drawPath(middleTopPath.shift(Offset(0, -12)), glowPaint2);
      canvas.drawPath(middleTopPath.shift(Offset(0, -12)), glowPaint2);
      canvas.drawPath(middleTopPath.shift(Offset(0, -12)), glowPaint2);
    }

    if(timeList[7] >= 15) {
      if(timeList[7] == 15 && selectedNumber == 7){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(middleTopPath, blurredPaint);
        canvas.drawPath(middleTopPath, blurredPaint);
        canvas.drawPath(middleTopPath.shift(Offset(0, -6)), shadowPaint3);
      }
      else { canvas.drawPath(middleTopPath.shift(Offset(0, -6)), shadowPaint3); }
    }
    else if (timeList[7] >= 8) { canvas.drawPath(middleTopPath.shift(Offset(0, -6)), shadowPaint2); }
    else { canvas.drawPath(middleTopPath.shift(Offset(0, -6)), shadowPaint); }

    if (timeList[1] >= 15) {
      if(timeList[1] == 15 && selectedNumber == 1){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(middleTopPath, blurredPaint);
        canvas.drawPath(middleTopPath, blurredPaint);
        canvas.drawPath(middleTopPath.shift(Offset(0, 6)), toothPaint3);
        canvas.drawPath(middleTopPath, toothPaint3);
      }
      else {
        canvas.drawPath(middleTopPath.shift(Offset(0, 6)), toothPaint3);
        canvas.drawPath(middleTopPath, toothPaint3);
      }
    }
    else if (timeList[1] >= 8) {
      canvas.drawPath(middleTopPath.shift(Offset(0, 6)), toothPaint2);
      canvas.drawPath(middleTopPath, toothPaint2);
    }
    else {
      canvas.drawPath(middleTopPath.shift(Offset(0, 6)), toothPaint);
      canvas.drawPath(middleTopPath, toothPaint);
    }

    var leftTopPath = createCirclePath(leftTop, radius);
    if(selectedNumber == 0) {
      canvas.drawPath(leftTopPath, glowPaint1);
      canvas.drawPath(leftTopPath, glowPaint1);
      canvas.drawPath(leftTopPath, glowPaint1);
    } else if(selectedNumber == 6) {
      canvas.drawPath(leftTopPath.shift(Offset(-10, -10)), glowPaint2);
      canvas.drawPath(leftTopPath.shift(Offset(-10, -10)), glowPaint2);
      canvas.drawPath(leftTopPath.shift(Offset(-10, -10)), glowPaint2);
    } else if(selectedNumber == 9) {
      canvas.drawPath(leftTopPath.shift(Offset(10, 10)), glowPaint2);
      canvas.drawPath(leftTopPath.shift(Offset(10, 10)), glowPaint2);
      canvas.drawPath(leftTopPath.shift(Offset(10, 10)), glowPaint2);
    }

    if(timeList[9] >= 15) {
      if(timeList[9] == 15 && selectedNumber == 9){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(leftTopPath, blurredPaint);
        canvas.drawPath(leftTopPath, blurredPaint);
        canvas.drawPath(leftTopPath.shift(Offset(6, 6)), shadowPaint3);
      }
      else {canvas.drawPath(leftTopPath.shift(Offset(6, 6)), shadowPaint3);}
    }
    else if (timeList[9] >= 8) {canvas.drawPath(leftTopPath.shift(Offset(6, 6)), shadowPaint2);}
    else {canvas.drawPath(leftTopPath.shift(Offset(6, 6)), shadowPaint);}

    if(timeList[6] >= 15) {
      if(timeList[6] == 15 && selectedNumber == 6){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(leftTopPath, blurredPaint);
        canvas.drawPath(leftTopPath, blurredPaint);
        canvas.drawPath(leftTopPath.shift(Offset(-6, -6)), shadowPaint3);
      }
      else {canvas.drawPath(leftTopPath.shift(Offset(-6, -6)), shadowPaint3);}
    }
    else if (timeList[6] >= 8) {canvas.drawPath(leftTopPath.shift(Offset(-6, -6)), shadowPaint2);}
    else {canvas.drawPath(leftTopPath.shift(Offset(-6, -6)), shadowPaint);}

    if (timeList[0] >= 15) {
      if(timeList[0] == 15 && selectedNumber == 0){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(leftTopPath, blurredPaint);
        canvas.drawPath(leftTopPath, blurredPaint);
        canvas.drawPath(leftTopPath, toothPaint3);
      }
      else {canvas.drawPath(leftTopPath, toothPaint3);}
    }
    else if (timeList[0] >= 8) {canvas.drawPath(leftTopPath, toothPaint2);}
    else {canvas.drawPath(leftTopPath, toothPaint);}

    var rightTopPath = createCirclePath(rightTop, radius);
    if(selectedNumber == 2) {
      canvas.drawPath(rightTopPath, glowPaint1);
      canvas.drawPath(rightTopPath, glowPaint1);
      canvas.drawPath(rightTopPath, glowPaint1);
    } else if(selectedNumber == 8 ) {
      canvas.drawPath(rightTopPath.shift(Offset(10, -10)), glowPaint2);
      canvas.drawPath(rightTopPath.shift(Offset(10, -10)), glowPaint2);
      canvas.drawPath(rightTopPath.shift(Offset(10, -10)), glowPaint2);
    } else if(selectedNumber == 10) {
      canvas.drawPath(rightTopPath.shift(Offset(-10, 10)), glowPaint2);
      canvas.drawPath(rightTopPath.shift(Offset(-10, 10)), glowPaint2);
      canvas.drawPath(rightTopPath.shift(Offset(-10, 10)), glowPaint2);
    }

    if(timeList[10] >= 15) {
      if(timeList[10] == 15 && selectedNumber == 10){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(rightTopPath, blurredPaint);
        canvas.drawPath(rightTopPath, blurredPaint);
        canvas.drawPath(rightTopPath.shift(Offset(-6, 6)), shadowPaint3);
      }
      else {canvas.drawPath(rightTopPath.shift(Offset(-6, 6)), shadowPaint3);}
    }
    else if (timeList[10] >= 8) {canvas.drawPath(rightTopPath.shift(Offset(-6, 6)), shadowPaint2);}
    else {canvas.drawPath(rightTopPath.shift(Offset(-6, 6)), shadowPaint);}

    if(timeList[8] >= 15) {
      if(timeList[8] == 15 && selectedNumber == 8){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(rightTopPath, blurredPaint);
        canvas.drawPath(rightTopPath, blurredPaint);
        canvas.drawPath(rightTopPath.shift(Offset(6, -6)), shadowPaint3);
      }
      else {canvas.drawPath(rightTopPath.shift(Offset(6, -6)), shadowPaint3);}
    }
    else if (timeList[8] >= 8) {canvas.drawPath(rightTopPath.shift(Offset(6, -6)), shadowPaint2);}
    else {canvas.drawPath(rightTopPath.shift(Offset(6, -6)), shadowPaint);}

    if(timeList[2] >= 15) {
      if(timeList[2] == 15 && selectedNumber == 2){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(rightTopPath, blurredPaint);
        canvas.drawPath(rightTopPath, blurredPaint);
        canvas.drawPath(rightTopPath, toothPaint3);
      }
      else {canvas.drawPath(rightTopPath, toothPaint3);}
    }
    else if (timeList[2] >= 8) {canvas.drawPath(rightTopPath, toothPaint2);}
    else {canvas.drawPath(rightTopPath, toothPaint);}
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class DownToothShape extends HookWidget {
  final int selectedNumber;
  final List<int> timeList;

  const DownToothShape({Key? key, required this.selectedNumber, required this.timeList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(duration: const Duration(seconds: 1));
    final blurAnimation = useAnimation(
      Tween<double>(begin: 0, end: 1.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
      ),
    );

    useEffect(() {
      if (timeList[0] == 15 || timeList[1] == 15 || timeList[2] == 15 ||
          timeList[3] == 15 || timeList[4] == 15 || timeList[5] == 15 ||
          timeList[6] == 15 || timeList[7] == 15 || timeList[8] == 15 ||
          timeList[9] == 15 || timeList[10] == 15 || timeList[11] == 15 ||
          timeList[12] == 15) {
        animationController.forward().then((_) {
          animationController.reverse();
        });
      }
      return null;
    }, [timeList]);

    return CustomPaint(
      size: Size(350, 120),
      painter: DownToothShapePainter(
        animation: blurAnimation,
        selectedNumber: selectedNumber,
        timeList: timeList,
      ),
    );
  }
}

class DownToothShapePainter extends CustomPainter {
  final int selectedNumber;
  final List<int> timeList;
  final double animation;

  DownToothShapePainter({required this.selectedNumber, required this.timeList, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    double radius = 20.0;

    var shadowPaint = Paint()
      ..color = Color(0xff7882A4)
      ..maskFilter = MaskFilter.blur(BlurStyle.inner, 1);

    var shadowPaint2 = Paint()
      ..color = Color(0xffbbc0d1)
      ..maskFilter = MaskFilter.blur(BlurStyle.inner, 1);

    var shadowPaint3 = Paint()
      ..color = Colors.white
      ..maskFilter = MaskFilter.blur(BlurStyle.inner, 1);

    var glowPaint1 = Paint()
      ..color = MAIN_COLOR
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 20);

    var glowPaint2 = Paint()
      ..color = Colors.lightBlueAccent
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);

    var toothPaint = Paint()
      ..color = Color(0xffb3b4b7)
      ..style = PaintingStyle.fill;

    var toothPaint2 = Paint()
      ..color = Color(0xffe3e3e5)
      ..style = PaintingStyle.fill;

    var toothPaint3 = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    List<Offset> middleDown = [
      Offset(size.width * 0.28, size.height - (radius + 15)),
      Offset(size.width * 0.37, size.height - (radius + 7)),
      Offset(size.width * 0.46, size.height - radius),
      Offset(size.width * 0.54, size.height - radius),
      Offset(size.width * 0.63, size.height - (radius + 7)),
      Offset(size.width * 0.72, size.height - (radius + 15)),
    ];

    List<Offset> leftDown = [
      Offset(radius + 38, size.height - (size.height * 0.65 - radius)),
      Offset(radius + 15, size.height - (size.height * 0.80 - radius)),
      Offset(radius, size.height - (size.height - radius)),
    ];

    List<Offset> rightDown = [
      Offset(size.width - radius - 38, size.height - (size.height * 0.65 - radius)),
      Offset(size.width - radius - 15, size.height - (size.height * 0.8 - radius)),
      Offset(size.width - radius, size.height - (size.height - radius)),
    ];

    Path createCirclePath(List<Offset> centers, double radius) {
      var path = Path();
      for (var center in centers) {
        path.addOval(Rect.fromCircle(center: center, radius: radius));
      }
      return path;
    }

    var middleDownPath = createCirclePath(middleDown, radius);
    if(selectedNumber == 4) {
      canvas.drawPath(middleDownPath, glowPaint1);
      canvas.drawPath(middleDownPath, glowPaint1);
      canvas.drawPath(middleDownPath, glowPaint1);
    } else if(selectedNumber == 7) {
      canvas.drawPath(middleDownPath.shift(Offset(0, 12)), glowPaint2);
      canvas.drawPath(middleDownPath.shift(Offset(0, 12)), glowPaint2);
      canvas.drawPath(middleDownPath.shift(Offset(0, 12)), glowPaint2);
    }

    if(timeList[7] >= 15) {
      if(timeList[7] == 15 && selectedNumber == 7){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(middleDownPath, blurredPaint);
        canvas.drawPath(middleDownPath, blurredPaint);
        canvas.drawPath(middleDownPath.shift(Offset(0, 6)), shadowPaint3);
      }
      else {canvas.drawPath(middleDownPath.shift(Offset(0, 6)), shadowPaint3);}
    }
    else if (timeList[7] >= 8) {canvas.drawPath(middleDownPath.shift(Offset(0, 6)), shadowPaint2);}
    else {canvas.drawPath(middleDownPath.shift(Offset(0, 6)), shadowPaint);}

    if(timeList[4] >= 15) {
      if(timeList[4] == 15 && selectedNumber == 4){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(middleDownPath, blurredPaint);
        canvas.drawPath(middleDownPath, blurredPaint);
        canvas.drawPath(middleDownPath.shift(Offset(0,-6)), toothPaint3);
        canvas.drawPath(middleDownPath, toothPaint3);
      }
      else {
        canvas.drawPath(middleDownPath.shift(Offset(0,-6)), toothPaint3);
        canvas.drawPath(middleDownPath, toothPaint3);}
    }
    else if (timeList[4] >= 8) {
      canvas.drawPath(middleDownPath.shift(Offset(0,-6)), toothPaint2);
      canvas.drawPath(middleDownPath, toothPaint2);}
    else {
      canvas.drawPath(middleDownPath.shift(Offset(0,-6)), toothPaint);
      canvas.drawPath(middleDownPath, toothPaint);}

    var leftDownPath = createCirclePath(leftDown, radius);
    if(selectedNumber == 3) {
      canvas.drawPath(leftDownPath, glowPaint1);
      canvas.drawPath(leftDownPath, glowPaint1);
      canvas.drawPath(leftDownPath, glowPaint1);
    } else if(selectedNumber == 6) {
      canvas.drawPath(leftDownPath.shift(Offset(-10, 10)), glowPaint2);
      canvas.drawPath(leftDownPath.shift(Offset(-10, 10)), glowPaint2);
      canvas.drawPath(leftDownPath.shift(Offset(-10, 10)), glowPaint2);
    } else if(selectedNumber == 11) {
      canvas.drawPath(leftDownPath.shift(Offset(10, -10)), glowPaint2);
      canvas.drawPath(leftDownPath.shift(Offset(10, -10)), glowPaint2);
      canvas.drawPath(leftDownPath.shift(Offset(10, -10)), glowPaint2);
    }

    if(timeList[11] >= 15) {
      if(timeList[11] == 15 && selectedNumber == 11){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(leftDownPath, blurredPaint);
        canvas.drawPath(leftDownPath, blurredPaint);
        canvas.drawPath(leftDownPath.shift(Offset(6, -6)), shadowPaint3);
      }
      else {canvas.drawPath(leftDownPath.shift(Offset(6, -6)), shadowPaint3);}
    }
    else if (timeList[11] >= 8) {canvas.drawPath(leftDownPath.shift(Offset(6, -6)), shadowPaint2);}
    else {canvas.drawPath(leftDownPath.shift(Offset(6, -6)), shadowPaint);}

    if(timeList[6] >= 15) {
      if(timeList[6] == 15 && selectedNumber == 6){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(leftDownPath, blurredPaint);
        canvas.drawPath(leftDownPath, blurredPaint);
        canvas.drawPath(leftDownPath.shift(Offset(-6, 6)), shadowPaint3);
      }
      else {canvas.drawPath(leftDownPath.shift(Offset(-6, 6)), shadowPaint3);}
    }
    else if (timeList[6] >= 8) {canvas.drawPath(leftDownPath.shift(Offset(-6, 6)), shadowPaint2);}
    else {canvas.drawPath(leftDownPath.shift(Offset(-6, 6)), shadowPaint);}

    if(timeList[3] >= 15) {
      if(timeList[3] == 15 && selectedNumber == 3){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(leftDownPath, blurredPaint);
        canvas.drawPath(leftDownPath, blurredPaint);
        canvas.drawPath(leftDownPath, toothPaint3);
      }
      else {canvas.drawPath(leftDownPath, toothPaint3);}
    }
    else if (timeList[3] >= 8) {canvas.drawPath(leftDownPath, toothPaint2);}
    else {canvas.drawPath(leftDownPath, toothPaint);}

    var rightDownPath = createCirclePath(rightDown, radius);
    if(selectedNumber == 5) {
      canvas.drawPath(rightDownPath, glowPaint1);
      canvas.drawPath(rightDownPath, glowPaint1);
      canvas.drawPath(rightDownPath, glowPaint1);
    } else if(selectedNumber == 8) {
      canvas.drawPath(rightDownPath.shift(Offset(10, 10)), glowPaint2);
      canvas.drawPath(rightDownPath.shift(Offset(10, 10)), glowPaint2);
      canvas.drawPath(rightDownPath.shift(Offset(10, 10)), glowPaint2);
    } else if (selectedNumber == 12) {
      canvas.drawPath(rightDownPath.shift(Offset(-10, -10)), glowPaint2);
      canvas.drawPath(rightDownPath.shift(Offset(-10, -10)), glowPaint2);
      canvas.drawPath(rightDownPath.shift(Offset(-10, -10)), glowPaint2);
    }

    if(timeList[12] >= 15) {
      if(timeList[12] == 15 && selectedNumber == 12){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(rightDownPath, blurredPaint);
        canvas.drawPath(rightDownPath, blurredPaint);
        canvas.drawPath(rightDownPath.shift(Offset(-6, -6)), shadowPaint3);
      }
      else {canvas.drawPath(rightDownPath.shift(Offset(-6, -6)), shadowPaint3);}
    }
    else if (timeList[12] >= 8) {canvas.drawPath(rightDownPath.shift(Offset(-6, -6)), shadowPaint2);}
    else {canvas.drawPath(rightDownPath.shift(Offset(-6, -6)), shadowPaint);}

    if(timeList[8] >= 15) {
      if(timeList[8] == 15 && selectedNumber == 8){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(rightDownPath, blurredPaint);
        canvas.drawPath(rightDownPath, blurredPaint);
        canvas.drawPath(rightDownPath.shift(Offset(6, 6)), shadowPaint3);
      }
      else {canvas.drawPath(rightDownPath.shift(Offset(6, 6)), shadowPaint3);}
    }
    else if (timeList[8] >= 8) {canvas.drawPath(rightDownPath.shift(Offset(6, 6)), shadowPaint2);}
    else {canvas.drawPath(rightDownPath.shift(Offset(6, 6)), shadowPaint);}

    if(timeList[5] >= 15) {
      if(timeList[5] == 15 && selectedNumber == 5){
        final blurredPaint = Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(
            BlurStyle.outer,
            20 * animation, // animationValue에 따라 blur 정도가 변화
          );
        canvas.drawPath(rightDownPath, blurredPaint);
        canvas.drawPath(rightDownPath, blurredPaint);
        canvas.drawPath(rightDownPath, toothPaint3);
      }
      else {canvas.drawPath(rightDownPath, toothPaint3);}
    }
    else if (timeList[5] >= 8) {canvas.drawPath(rightDownPath, toothPaint2);}
    else {canvas.drawPath(rightDownPath, toothPaint);}
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}