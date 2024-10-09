import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../theme.dart';

class TopToothShape extends HookWidget {
  final List<int> timeList;  //시간 데이터 리스트
  final List<int> countList;  //불량 횟수 데이터 리스트
  final bool isCount;  //불량 횟수인지 시간인지 구분

  TopToothShape({
    required this.timeList,
    required this.countList,
    required this.isCount
  });

  @override
  Widget build(BuildContext context) {
    List<int> sortedTimeList = List.from(timeList)..sort();

    int minTime = sortedTimeList.first;
    int maxTime = sortedTimeList.last;

    double stepSize = (maxTime - minTime) / 5;

    List<int> timeSteps = timeList.map((time) {
      int timeStep = ((time - minTime) / stepSize).ceil();
      return timeStep.clamp(1, 5); // 1에서 5 사이로 값을 제한
    }).toList();

    List<int> countSteps = countList.map((count) {
      int countStep;
      if (count == 0) {
        countStep = 1;
      } else if (count == 1) {
        countStep = 2;
      } else if (count == 2) {
        countStep = 3;
      } else if (count == 3) {
        countStep = 4;
      } else {
        countStep = 5; // count가 4 이상이면 5단계
      }
      return countStep;
    }).toList();

    print('timeSteps: $timeSteps');
    print('countSteps: $countSteps');

    return Stack(
      children: [
        CustomPaint(
          size: Size(350, 120),
          painter: TopToothShapePainter(
            isCount: isCount,
            timeSteps: timeSteps,
            countSteps: countSteps
          ),
        ),
      ],
    );
  }
}

class TopToothShapePainter extends CustomPainter {
  final bool isCount;  //불량 횟수인지 시간인지 구분
  final List<int> timeSteps;  //시간 데이터 리스트
  final List<int> countSteps;  //불량 횟수 데이터 리스트

  TopToothShapePainter({
    required this.isCount,
    required this.timeSteps,
    required this.countSteps
  }) : super();

  @override
  void paint(Canvas canvas, Size size) {
    double radius = 20.0;

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

    void drawRowTooth(Path path, int timeSteps, int countSteps, {double x = 0, double y = 0}) {
      var toothPaint = Paint()
        ..color = isCount
            ? countSteps == 5
            ? TOOTH_COUNT_COLOR5
            : countSteps == 4
            ? TOOTH_COUNT_COLOR4
            : countSteps == 3
            ? TOOTH_COUNT_COLOR3
            : countSteps == 2
            ? TOOTH_COUNT_COLOR2
            : TOOTH_COUNT_COLOR1
            : timeSteps == 5
            ? TOOTH_COLOR5
            : timeSteps == 4
            ? TOOTH_COLOR4
            : timeSteps == 3
            ? TOOTH_COLOR3
            : timeSteps == 2
            ? TOOTH_COLOR2
            : TOOTH_COLOR1
        ..style = PaintingStyle.fill;

      canvas.drawPath(path.shift(Offset(x, y)), toothPaint);
    }

    void drawRowSide(Path path, int timeSteps, int countSteps, double x, double y) {
      var shadowPaint = Paint()
        ..color = isCount
            ? countSteps == 5
            ? TOOTH_SUB_COUNT_COLOR5
            : countSteps == 4
            ? TOOTH_SUB_COUNT_COLOR4
            : countSteps == 3
            ? TOOTH_SUB_COUNT_COLOR3
            : countSteps == 2
            ? TOOTH_SUB_COUNT_COLOR2
            : TOOTH_SUB_COUNT_COLOR1
            : timeSteps == 5
            ? TOOTH_SUB_COLOR5
            : timeSteps == 4
            ? TOOTH_SUB_COLOR4
            : timeSteps == 3
            ? TOOTH_SUB_COLOR3
            : timeSteps == 2
            ? TOOTH_SUB_COLOR2
            : TOOTH_SUB_COLOR1
        ..maskFilter = MaskFilter.blur(BlurStyle.inner, 1);

      canvas.drawPath(path.shift(Offset(x, y)), shadowPaint);
    }

    Path createCirclePath(List<Offset> centers, double radius) {
      var path = Path();
      for (var center in centers) {
        path.addOval(Rect.fromCircle(center: center, radius: radius));
      }
      return path;
    }

    var middleTopPath = createCirclePath(middleTop, radius);
    drawRowSide(middleTopPath, timeSteps[7], countSteps[7], 0, -6);
    drawRowTooth(middleTopPath, timeSteps[1], countSteps[1], x: 0, y: 6);
    drawRowTooth(middleTopPath, timeSteps[1], countSteps[1]);

    var leftTopPath = createCirclePath(leftTop, radius);
    drawRowSide(leftTopPath, timeSteps[9], countSteps[9], 6, 6);
    drawRowSide(leftTopPath, timeSteps[6], countSteps[6], -6, -6);
    drawRowTooth(leftTopPath, timeSteps[0], countSteps[0]);

    var rightTopPath = createCirclePath(rightTop, radius);
    drawRowSide(rightTopPath, timeSteps[10], countSteps[10], -6, 6);
    drawRowSide(rightTopPath, timeSteps[8], countSteps[8], 6, -6);
    drawRowTooth(rightTopPath, timeSteps[2], countSteps[2]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DownToothShape extends HookWidget {
  final List<int> timeList;  //시간 데이터 리스트
  final List<int> countList;  //불량 횟수 데이터 리스트
  final bool isCount;  //불량 횟수인지 시간인지 구분

  DownToothShape({
    required this.timeList,
    required this.countList,
    required this.isCount
  });

  @override
  Widget build(BuildContext context) {
    List<int> sortedTimeList = List.from(timeList)..sort();

    int minTime = sortedTimeList.first;
    int maxTime = sortedTimeList.last;

    double stepSize = (maxTime - minTime) / 5;

    List<int> timeSteps = timeList.map((time) {
      int timeStep = ((time - minTime) / stepSize).ceil();
      return timeStep.clamp(1, 5); // 1에서 5 사이로 값을 제한
    }).toList();

    List<int> countSteps = countList.map((count) {
      int countStep;
      if (count == 0) {
        countStep = 1;
      } else if (count == 1) {
        countStep = 2;
      } else if (count == 2) {
        countStep = 3;
      } else if (count == 3) {
        countStep = 4;
      } else {
        countStep = 5; // count가 4 이상이면 5단계
      }
      return countStep;
    }).toList();

    return Stack(
      children: [
        CustomPaint(
          size: Size(350, 120),
          painter: DownToothShapePainter(
            isCount: isCount,
            timeSteps: timeSteps,
            countSteps: countSteps
          ),
        ),
      ],
    );
  }
}

class DownToothShapePainter extends CustomPainter {
  final bool isCount;  //불량 횟수인지 시간인지 구분
  final List<int> timeSteps;  //시간 데이터 리스트
  final List<int> countSteps;  //불량 횟수 데이터 리스트

  DownToothShapePainter({
    required this.isCount,
    required this.timeSteps,
    required this.countSteps
  }) : super();


  @override
  void paint(Canvas canvas, Size size) {
    double radius = 20.0;

    void drawRowTooth(Path path, int timeSteps, int countSteps, {double x = 0, double y = 0}) {
      var toothPaint = Paint()
        ..color = isCount
            ? countSteps == 5
            ? TOOTH_COUNT_COLOR5
            : countSteps == 4
            ? TOOTH_COUNT_COLOR4
            : countSteps == 3
            ? TOOTH_COUNT_COLOR3
            : countSteps == 2
            ? TOOTH_COUNT_COLOR2
            : TOOTH_COUNT_COLOR1
            : timeSteps == 5
            ? TOOTH_COLOR5
            : timeSteps == 4
            ? TOOTH_COLOR4
            : timeSteps == 3
            ? TOOTH_COLOR3
            : timeSteps == 2
            ? TOOTH_COLOR2
            : TOOTH_COLOR1
        ..style = PaintingStyle.fill;

      canvas.drawPath(path.shift(Offset(x, y)), toothPaint);
    }

    void drawRowSide(Path path, int timeSteps, int countSteps, double x, double y) {
      var shadowPaint = Paint()
        ..color = isCount
            ? countSteps == 5
            ? TOOTH_SUB_COUNT_COLOR5
            : countSteps == 4
            ? TOOTH_SUB_COUNT_COLOR4
            : countSteps == 3
            ? TOOTH_SUB_COUNT_COLOR3
            : countSteps == 2
            ? TOOTH_SUB_COUNT_COLOR2
            : TOOTH_SUB_COUNT_COLOR1
            : timeSteps == 5
            ? TOOTH_SUB_COLOR5
            : timeSteps == 4
            ? TOOTH_SUB_COLOR4
            : timeSteps == 3
            ? TOOTH_SUB_COLOR3
            : timeSteps == 2
            ? TOOTH_SUB_COLOR2
            : TOOTH_SUB_COLOR1
        ..maskFilter = MaskFilter.blur(BlurStyle.inner, 1);

      canvas.drawPath(path.shift(Offset(x, y)), shadowPaint);
    }

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
    drawRowSide(middleDownPath, timeSteps[7], countSteps[7], 0, 6);
    drawRowTooth(middleDownPath, timeSteps[4], countSteps[4], x: 0, y: -6);
    drawRowTooth(middleDownPath, timeSteps[4], countSteps[4]);

    var leftDownPath = createCirclePath(leftDown, radius);
    drawRowSide(leftDownPath, timeSteps[11], countSteps[11], 6, -6);
    drawRowSide(leftDownPath, timeSteps[6], countSteps[6], -6, 6);
    drawRowTooth(leftDownPath, timeSteps[3], countSteps[3]);

    var rightDownPath = createCirclePath(rightDown, radius);
    drawRowSide(rightDownPath, timeSteps[12], countSteps[12], -6, -6);
    drawRowSide(rightDownPath, timeSteps[8], countSteps[8], 6, 6);
    drawRowTooth(rightDownPath, timeSteps[5], countSteps[5]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}