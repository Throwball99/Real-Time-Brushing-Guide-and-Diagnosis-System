import 'dart:ui';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:smartmirror_renewal/theme.dart';

import '../provider/picture_provider.dart';

class ToothCheckDetailPage extends HookConsumerWidget {
  const ToothCheckDetailPage({required this.date});

  final String date;


  Future<String> _getDownloadUrl(String path) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredPictures = ref.watch(filteredPicturesProvider(date));

    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(
        title: Text('치아 검진 상세', style: APPBAR_FONT),
        backgroundColor: Colors.white.withAlpha(100),
        elevation: 0.0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaY: 10, sigmaX: 10),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          Expanded(
            child: filteredPictures.isEmpty
                ? Center(child: Text('데이터가 없습니다.'))
                : Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ListView.builder(
                                itemCount: filteredPictures.length,
                                itemBuilder: (context, index) {
                  final picture = filteredPictures[index];
                  return FutureBuilder<String>(
                    future: _getDownloadUrl(picture['Path']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: LoadingAnimationWidget.staggeredDotsWave(color: MAIN_COLOR, size: 40));
                      } else if (snapshot.hasError) {
                        return ListTile(
                          leading: Icon(Icons.error),
                          title: Text('이미지 로딩 에러'),
                        );
                      } else if (snapshot.hasData) {
                        DateTime dateTime = DateTime.parse(picture['DataField']);
                        DateFormat dateFormatter = DateFormat('MM/dd HH:mm');
                        String dateString = dateFormatter.format(dateTime);
                        return Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Column(
                                  children: [
                                    Image.network(
                                      snapshot.data!,
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                        color: Colors.white,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                              dateString,
                                              style: SETTING_CONTANT_FONT_BLACK_BOLD,
                                            ),
                                            Row(
                                              children: [
                                                picture['Cavity'] == true
                                                    ? Text('충치 : ❗️', style: SETTING_CONTANT_FONT_BLACK_BOLD)
                                                    : Text('충치 : ❎', style: SETTING_CONTANT_FONT_BLACK_BOLD),
                                                picture['Plaque'] == true
                                                    ? Text('  치석 : ❗️', style: SETTING_CONTANT_FONT_BLACK_BOLD)
                                                    : Text('  치석 : ❎', style: SETTING_CONTANT_FONT_BLACK_BOLD),
                                              ],
                                            )
                                          ],
                                        )
                                    ),
                                  ],
                                ),
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 7, spreadRadius: 1.5,)],
                              )
                          ),
                        );
                      } else {
                        return ListTile(
                          leading: Icon(Icons.broken_image),
                          title: Text('이미지가 없습니다.'),
                        );
                      }
                    },
                  );
                                },
                              ),
                ),
          ),
        ],
      ),
    );
  }
}
