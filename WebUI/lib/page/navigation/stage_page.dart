import 'dart:async';
import 'dart:math';

import 'package:bubble_box/bubble_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gif/gif.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_animation_progress_bar/simple_animation_progress_bar.dart';

import '../../firestore_provider.dart';
import '../../theme.dart';
import '../../widget/StageStepper.dart';

class StageStartPage extends HookConsumerWidget {
  StageStartPage({super.key});

  var options = ConfettiOptions(
      spread: 360,
      ticks: 50,
      gravity: 0,
      decay: 0.94,
      startVelocity: 30,
      colors: [
        Color(0xffFFE400),
        Color(0xffFFBD00),
        Color(0xffE89400),
        Color(0xffFFCA6C),
        Color(0xffFDFFB8)
      ]);

  double randomInRange(double min, double max) {
    return min + Random().nextDouble() * (max - min);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    useEffect(() {
      Future.delayed(Duration(seconds: 1), () {
        Confetti.launch(
          context,
          particleBuilder: (index) => Star(),
          options: ConfettiOptions(
              startVelocity: 20,
              colors: [
                Color(0xffFFE400),
                Color(0xffFFBD00),
                Color(0xffE89400),
                Color(0xffFFCA6C),
                Color(0xffFDFFB8)
              ],
              x : 0.5,
              y : 0.5,
              particleCount: 30,
              spread: 360,
              ticks: 60,
              gravity: 0),
        );
      });
      return () {};
    }, []);
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BubbleBox(
                maxWidth: double.maxFinite,
                shape: BubbleShapeBorder(
                  radius: BorderRadius.all(Radius.circular(30)),
                  border: BubbleBoxBorder(
                    color: Colors.white,
                    width: 3,
                  ),
                  position: const BubblePosition.center(0),
                  direction: BubbleDirection.bottom,
                ),
                backgroundColor: Colors.white24,
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Text('버튼을 눌러 다음 단계를 시작하세요!', style: TextStyle(color: Colors.white, fontSize: 25, fontFamily: 'NEXON Lv2 Gothic', fontWeight: FontWeight.bold)),
                ),
              ),
              Image.asset('assets/images/tino_view.png', height: 300),
            ],
          ),
        ),
      ],
    );
  }
}

class StageEndPage extends HookConsumerWidget {
  const StageEndPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.delayed(Duration(seconds: 1), () {

        const colors = [
          Colors.blueAccent,
          Color(0xffffffff),
        ];

        int frameTime = 1000 ~/ 24;
        int total = 1 * 1000 ~/ frameTime;
        int progress = 0;

        ConfettiController? controller1;
        ConfettiController? controller2;
        bool isDone = false;

        Timer.periodic(Duration(milliseconds: frameTime), (timer) {
          progress++;

          if (progress >= total) {
            timer.cancel();
            isDone = true;
            return;
          }
          if (controller1 == null) {
            controller1 = Confetti.launch(
              context,
              options: const ConfettiOptions(
                  particleCount: 2,
                  angle: 60,
                  spread: 55,
                  x: 0,
                  colors: colors),
              onFinished: (overlayEntry) {
                if (isDone) {
                  overlayEntry.remove();
                }
              },
            );
          } else {
            controller1!.launch();
          }

          if (controller2 == null) {
            controller2 = Confetti.launch(
              context,
              options: const ConfettiOptions(
                  particleCount: 2,
                  angle: 120,
                  spread: 55,
                  x: 1,
                  colors: colors),
              onFinished: (overlayEntry) {
                if (isDone) {
                  overlayEntry.remove();
                }
              },
            );
          } else {
            controller2!.launch();
          }
        });
      });
      return () {};
    }, []);
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BubbleBox(
                  maxWidth: double.maxFinite,
                  shape: BubbleShapeBorder(
                    radius: BorderRadius.all(Radius.circular(30)),
                    border: BubbleBoxBorder(
                      color: Colors.white,
                      width: 3,
                    ),
                    position: const BubblePosition.center(0),
                    direction: BubbleDirection.bottom,
                  ),
                  backgroundColor: Colors.white24,
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        Text('양치가 완료되었습니다!', style: TextStyle(color: Colors.white, fontSize: 25, fontFamily: 'NEXON Lv2 Gothic', fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                        SizedBox(height: 30),
                        Text('버튼을 누르면 메인 화면으로 돌아갑니다.', style: TextStyle(color: Colors.white, fontSize: 25, fontFamily: 'NEXON Lv2 Gothic', fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ]
                  ),
                ),
                ),
                Image.asset('assets/images/tino_view.png', height: 300),
              ],
            ),
          ),
        ),
      ],
    );
  }

}

class StagePage extends HookConsumerWidget {
  final int activeStep;
  final String instruction1;
  final String instruction2;
  final String image1;
  final String image2;

  const StagePage({
    super.key,
    required this.activeStep,
    required this.instruction1,
    required this.instruction2,
    required this.image1,
    required this.image2,
  });

  List<int> parseTimeString(String timeString) {
    return timeString.split('/')
        .map((str) => double.parse(str).toInt()) // 소수점 포함 형식을 int로 변환
        .toList();
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsyncValue = ref.watch(infoProvider);
    return infoAsyncValue.when(
        data: (infoData) {
          final greatOrBad = useState(-1);
          final previousTimeList = useRef<List<int>>([]);
          final newTimeList = parseTimeString(infoData.teachTime);

          useEffect(() {
            if (newTimeList.length >= 3 && previousTimeList.value.length >= 3) {
              if (newTimeList[1] > previousTimeList.value[1]) {
                greatOrBad.value = 0;
              } else if (newTimeList[2] > previousTimeList.value[2]) {
                greatOrBad.value = 1;
              }
            }
            previousTimeList.value = newTimeList;

            return () {};
          }, [newTimeList]);

          Widget progressBar(int time, String text) {
            return Column(
              children: [
                Text(text, style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'NEXONLv1Gothic', fontWeight: FontWeight.bold)),
                SimpleAnimationProgressBar(
                  height: 20,
                  width: 200,
                  direction: Axis.horizontal,
                  backgroundColor: Colors.grey.shade800,
                  foregrondColor: time >= 2 ? SUB_COLOR : TOOTH_COLOR,
                  ratio: newTimeList[time] > 30 ? 1 : newTimeList[time] / 30,
                  curve: Curves.fastLinearToSlowEaseIn,
                  duration: const Duration(seconds: 3),
                  borderRadius: BorderRadius.circular(30),
                ),
              ],
            );
          }
          return Column(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.all(Radius.circular(35))),
                      height: 100,
                      child: newTimeList[0] < 5
                          ? Center(child: Text('${5 - newTimeList[0]}초 뒤 시작됩니다.', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'NEXON Lv2 Gothic', fontWeight: FontWeight.bold)))
                          : newTimeList[0] >= 35
                          ? Center(child: Text('버튼을 눌러 단계를 종료하세요.', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'NEXON Lv2 Gothic', fontWeight: FontWeight.bold)))
                          : greatOrBad.value == 0
                          ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset('assets/images/tino_great.png'),
                            ),
                            Expanded(child:
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(''),
                                  Text('GREAT!', style: TextStyle(color: GREAT_COLOR, fontSize: 30, fontFamily: 'NEXONLv1Gothic', fontWeight: FontWeight.bold)),
                                  Text('+${(newTimeList[1]/30 * 100).toInt()}점', style: TextStyle(color: GREAT_COLOR, fontSize: 30, fontFamily: 'NEXONLv1Gothic', fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )),
                          ],
                        ),
                      )
                          : greatOrBad.value == 1
                          ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset('assets/images/tino_bad.png'),
                            ),
                            Expanded(child:
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(''),
                                  Text('BAD!', style: TextStyle(color: BAD_COLOR, fontSize: 30, fontFamily: 'NEXONLv1Gothic', fontWeight: FontWeight.bold)),
                                  Text('+${(newTimeList[1]/30 * 100).toInt()}점', style: TextStyle(color: BAD_COLOR, fontSize: 30, fontFamily: 'NEXONLv1Gothic', fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )),
                          ],
                        ),
                      )
                          : Center(child: Text('양치 인식 중입니다.', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'NEXON Lv2 Gothic', fontWeight: FontWeight.bold))),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 100),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        progressBar(1, "GREAT"),
                        progressBar(2, "BAD")
                      ],
                    ),
                  )
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Container(
                            child: StageStepper(activeStep: activeStep),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 150,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            borderRadius: BorderRadius.all(Radius.circular(30))),
                                        child: Center(
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.greenAccent, size: 50),
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(20.0),
                                                  child: Center(
                                                    child: Text(instruction1
                                                        , style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'NEXON Lv2 Gothic', fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(28),
                                          child: Gif(
                                            height: 150,
                                            width: 150,
                                            image: AssetImage(image1,),
                                            fps: 30,
                                            autostart: Autostart.loop,
                                            placeholder: (context) => const Text('Loading...'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 150,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            borderRadius: BorderRadius.all(Radius.circular(30))),
                                        child: Center(
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.greenAccent, size: 50),
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(20.0),
                                                  child: Center(
                                                    child: Text(instruction2
                                                        , style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'NEXON Lv2 Gothic', fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(28),
                                          child: Gif(
                                            height: 150,
                                            width: 150,
                                            image: AssetImage(image2),
                                            fps: 30,
                                            autostart: Autostart.loop,
                                            placeholder: (context) => const Text('Loading...'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SimpleAnimationProgressBar(
                              height: double.maxFinite,
                              width: 5,
                              direction: Axis.vertical,
                              backgroundColor: Colors.grey.shade800,
                              foregrondColor: Colors.white,
                              ratio: newTimeList[0] <= 5
                                  ? 0
                                  : (newTimeList[0]-5) / 30,
                              curve: Curves.fastLinearToSlowEaseIn,
                              duration: const Duration(seconds: 3),
                              borderRadius: BorderRadius.circular(30),
                              gradientColor: LinearGradient(
                                colors: [TOOTH_COLOR, SUB_COLOR],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )

                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.white))),
    );
  }
}