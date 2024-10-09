import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../provider/bluetooth_provider.dart';
import '../screen/portable/cameraStream_page.dart';
import '../theme.dart';

class TestBluetoothPage extends HookConsumerWidget {
  const TestBluetoothPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bluetoothNotifier = ref.watch(bluetoothProvider);
    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(
          title: Text('블루투스 연결', style: APPBAR_FONT),
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
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: GestureDetector(
              onTap: bluetoothNotifier.startScan,
              child: Container(
                width: double.maxFinite,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: MAIN_COLOR,
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 7, spreadRadius: 1.5,)],
                ),
                child: Center(child: Text('블루투스 스캔', style: CONTANT_FONT_WHITE_BOLD)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bluetoothNotifier.devices.length,
              itemBuilder: (context, index) {
                final device = bluetoothNotifier.devices[index];
                return ListTile(
                  title: Text(device.name.isEmpty ? 'Unknown device' : device.name),
                  subtitle: Text(device.id.toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
