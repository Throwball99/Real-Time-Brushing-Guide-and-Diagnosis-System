import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gif/gif.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_animation_progress_bar/simple_animation_progress_bar.dart';
import 'package:smartmirror_web_ui/theme.dart';

import '../../firestore_provider.dart';
import '../../widget/ToothShape.dart';

class BrushPage extends HookConsumerWidget {
  const BrushPage({super.key});

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
        final timeList = parseTimeString(infoData.time);
        final totalTime = timeList.reduce((value, element) => value + element);

        Widget progressBar(int time, String text) {
          return Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: timeList[time] >= 15 ? Colors.yellowAccent: Colors.transparent, // 그림자 색상
                      spreadRadius: 3, // 그림자의 퍼짐 정도
                      blurRadius: 10, // 그림자의 흐림 정도
                    ),
                  ],
                ),
                child: SimpleAnimationProgressBar(
                  height: 200,
                  width: 10,
                  direction: Axis.vertical,
                  backgroundColor: Colors.grey.shade800,
                  foregrondColor: time >= 9
                      ? SUB_COLOR
                      : time >= 6
                      ? Colors.white
                      : TOOTH_COLOR,
                  ratio: timeList[time] > 15 ? 1 : timeList[time] / 15,
                  curve: Curves.fastLinearToSlowEaseIn,
                  duration: const Duration(seconds: 3),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              SizedBox(height: 10),
              Text(text, style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'NEXON Lv2 Gothic')),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(),
            ),
            Expanded(
              flex: 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Gif(
                            autostart: Autostart.loop,
                            placeholder: (context) => Container(),
                            image: const AssetImage('assets/images/teeth.gif'),
                            width: 70,
                            height: 70,
                          ),
                          Text('칫솔 버튼을 눌러 종료', style: NOTICE_FONT_WHITE_BOLD),
                        ],
                      ),
                      SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final  offsetAnimation =
                          Tween<Offset>(begin: Offset(0.0, 0.0), end: Offset(0.0, -0.3)).animate(animation);
                          return SlideTransition(position: offsetAnimation, child: child);
                        },
                        child: Text(
                          infoData.motorCount == 0
                              ? '양치를 시작해주세요'
                              : '강한 양치질 ${infoData.motorCount.toString()}회',
                          key: ValueKey<int>(infoData.motorCount),
                          style: CONTANT_FONT_WHITE_BOLD,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 350,
                        height: 120,
                        color: Colors.transparent,
                        child: TopToothShape(
                          selectedNumber: infoData.direction,
                          timeList: timeList,
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: 350,
                        height: 120,
                        color: Colors.transparent,
                        child: DownToothShape(
                          selectedNumber: infoData.direction,
                          timeList: timeList,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('윗니', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'NEXON Lv2 Gothic', fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                progressBar(0, '좌측\n상단'),
                                progressBar(1, '중앙\n상단'),
                                progressBar(2, '우측\n상단'),
                                progressBar(3, '좌측\n하단'),
                                progressBar(4, '중앙\n하단'),
                                progressBar(5, '우측\n하단'),                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('앞니', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'NEXON Lv2 Gothic', fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                progressBar(6, '좌측\n'),
                                progressBar(7, '중앙\n'),
                                progressBar(8, '우측\n'),                           ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('뒷니', style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'NEXON Lv2 Gothic', fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                progressBar(9, '좌측\n상단'),
                                progressBar(10, '우측\n상단'),
                                progressBar(11, '좌측\n하단'),
                                progressBar(12, '우측\n하단'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SimpleAnimationProgressBar(
                    height: MediaQuery.of(context).size.height,
                    width: 5,
                    direction: Axis.vertical,
                    backgroundColor: Colors.grey.shade800,
                    foregrondColor: Colors.white,
                    ratio: totalTime > 195 ? 1 : totalTime / 195,
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
            )
          ]
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text("Error: $error"),
    );
  }
}
