import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'firebase_options.dart';
import 'page/home_page.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends HookWidget {
  MyApp({Key? key}) : super(key: key);

  final List<String> imageUrls = [
    'assets/stage/0.gif',
    'assets/stage/1.gif',
    'assets/stage/2.gif',
    'assets/stage/3.gif',
    'assets/stage/4.gif',
    'assets/stage/5.gif',
    'assets/stage/6_up.gif',
    'assets/stage/7_up.gif',
    'assets/stage/8_up.gif',
    'assets/stage/0_inside.gif',
    'assets/stage/1_inside.gif',
    'assets/stage/2_inside.gif',
    'assets/stage/3_inside.gif',
    'assets/stage/4_inside.gif',
    'assets/stage/5_inside.gif',
    'assets/stage/6_down.gif',
    'assets/stage/7_down.gif',
    'assets/stage/8_down.gif',
    'assets/images/confetti.gif',
    'assets/images/teeth.gif',
    'assets/images/tino_bad.png',
    'assets/images/tino_great.png',
    'assets/images/tino_view.png',
  ];

  @override
  Widget build(BuildContext context) {
    imageUrls.forEach((url) => precacheImage(AssetImage(url), context));
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartMirror',
      home: HomePage(),
    );
  }
}