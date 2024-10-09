import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ClockWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final time = useState(DateTime.now());

    useEffect(() {
      final timer = Timer.periodic(Duration(seconds: 1), (timer) {
        time.value = DateTime.now();
      });
      return timer.cancel;
    }, []);

    return Text(
      '${time.value.hour.toString().padLeft(2, '0')}:${time.value.minute.toString().padLeft(2, '0')}:${time.value.second.toString().padLeft(2, '0')}',
      style: TextStyle(
        color: Colors.white,
        fontSize: 80,
        fontFamily: 'NEXON Lv2 Gothic',
        fontWeight: FontWeight.bold,
      ),
    );
  }
}