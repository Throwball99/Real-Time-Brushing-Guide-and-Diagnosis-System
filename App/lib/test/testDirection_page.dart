import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../theme.dart';

class TestDirectionPage extends HookConsumerWidget {
  const TestDirectionPage({super.key});

  Future<void> updateDirection(int status) async {
    try {
      await FirebaseFirestore.instance
          .collection('UI')
          .doc('Info')
          .update({'Direction': status});
    } catch (e) {
      print("Failed to update Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(
          title: Text('방향 테스트', style: APPBAR_FONT),
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
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GestureDetector(
                    onTap: () {
                      updateDirection(index);
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
                              Text('방향 변경 ${index}', style: CONTANT_FONT_BLACK_BOLD,),
                              Icon(Icons.arrow_forward_ios, color: Colors.black, size: 30,),
                            ],
                          ),
                        )
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
