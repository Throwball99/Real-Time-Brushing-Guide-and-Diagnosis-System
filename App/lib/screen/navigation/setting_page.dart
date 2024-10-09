import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../test/testBluetooth_page.dart';
import '../../test/testDirection_page.dart';
import '../../test/testModel_page.dart';
import '../../test/testStreaming_page.dart';
import '../../theme.dart';

class SettingPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Scaffold(
        backgroundColor: BACKGROUND_COLOR,
        appBar: AppBar(
            title: Text("앱 설정🛠️", style: APPBAR_FONT),
          centerTitle: false,
          backgroundColor: BACKGROUND_COLOR,
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              SizedBox(height: 20,),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (c) => TestStreamingPage())
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
                          Text('카메라 테스트 페이지', style: SETTING_CONTANT_FONT_BLACK_BOLD,),
                          Icon(Icons.arrow_forward_ios, color: Colors.black, size: 30,),
                        ],
                      ),
                    )
                ),
              ),
              SizedBox(height: 20,),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (c) => TestBluetoothPage())
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
                          Text('블루투스 테스트 페이지', style: SETTING_CONTANT_FONT_BLACK_BOLD,),
                          Icon(Icons.arrow_forward_ios, color: Colors.black, size: 30,),
                        ],
                      ),
                    )
                ),
              ),
              SizedBox(height: 20,),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (c) => TestDirectionPage())
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
                          Text('방향 입력 테스트 페이지', style: SETTING_CONTANT_FONT_BLACK_BOLD,),
                          Icon(Icons.arrow_forward_ios, color: Colors.black, size: 30,),
                        ],
                      ),
                    )
                ),
              ),
              SizedBox(height: 20,),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (c) => TestModelPage())
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
                          Text('예측 모델 테스트 페이지', style: SETTING_CONTANT_FONT_BLACK_BOLD,),
                          Icon(Icons.arrow_forward_ios, color: Colors.black, size: 30,),
                        ],
                      ),
                    )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}