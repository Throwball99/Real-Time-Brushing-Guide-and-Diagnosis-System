import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';

import '../../provider/picture_provider.dart';
import '../../provider/portable_provider.dart';
import '../../theme.dart';
import '../toothCheckDetail_page.dart';

class ToothCheckPage extends HookConsumerWidget {
  const ToothCheckPage({super.key});

  Future<void> updateCavityStatus(bool status) async {
    try {
      await FirebaseFirestore.instance
          .collection('UI')
          .doc('Info')
          .update({'Cavity': status});
    } catch (e) {
      print("Failed to update Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portableNotifier = ref.watch(portableProvider);
    final availableDates = ref.watch(availableDatesProvider);
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Scaffold(
        backgroundColor: BACKGROUND_COLOR,
        appBar: AppBar(
          title: Text("치아 체크️📝", style: APPBAR_FONT),
          centerTitle: false,
          scrolledUnderElevation: 0,
          elevation: 0,
          backgroundColor: BACKGROUND_COLOR,
        ),
        body: portableNotifier.when(
            data: (portableData) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("치아 검진 모드", style: SETTING_CONTANT_FONT_BLACK_BOLD),
                        CupertinoSwitch(
                          value: portableData.cavity,
                          activeColor: MAIN_COLOR,
                          onChanged: (value) async {
                            await updateCavityStatus(value);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: portableData.cavity == true
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: Lottie.asset('assets/images/cavity_mode.json'),
                              ),
                              Text('치아 검진 모드를 실행중입니다.', style: CONTANT_FONT_BLACK_BOLD, textAlign: TextAlign.center,),
                              SizedBox(height: 20,),
                              Text('스마트미러의 치아 검진 카메라로\n검진을 진행해주세요.', style: CONTANT_FONT_BLACK_BOLD, textAlign: TextAlign.center,),
                            ],
                          )
                        : ListView.builder(
                        itemCount: availableDates.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context,
                                    CupertinoPageRoute(builder: (c) => ToothCheckDetailPage(date: availableDates[index]))
                                );
                              },
                              child: Container(
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 7, spreadRadius: 1.5,)],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 30),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Icon(Bootstrap.folder, color: Colors.black, size: 30,),
                                      Text(availableDates[index], style: CONTANT_FONT_BLACK_BOLD,),
                                    ],
                                  ),
                                )
                              ),
                            ),
                          );
                        }
                                            ),
                  )
                ],
              );
            },
            loading: () => Center(child: LoadingAnimationWidget.staggeredDotsWave(color: Colors.white, size: 40)),
            error: (error, stackTrace) => Text("Error: $error")),
      ),
    );
  }
}
