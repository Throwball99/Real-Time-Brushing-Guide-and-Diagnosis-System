import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> updatePortableStatus(bool status) async {
  try {
    await FirebaseFirestore.instance
        .collection('UI')
        .doc('Info')
        .update({'Portable': status});
  } catch (e) {
    print("Failed to update Firestore: $e");
  }
}

final portableProvider = StreamProvider<PortableData>((ref) {
  final documentStream = FirebaseFirestore.instance
      .collection('UI')
      .doc('Info')
      .snapshots();

  return documentStream.map((snapshot) {
    return PortableData.fromDocument(snapshot);
  });
});

class PortableData {
  final int direction;
  final int motorCount;
  final String time;
  final int mode;
  final String teachTime;
  final bool cavity;

  PortableData({
    required this.direction,
    required this.motorCount,
    required this.time,
    required this.mode,
    required this.teachTime,
    required this.cavity,
  });

  factory PortableData.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PortableData(
      direction: data['Direction'],
      motorCount: data['Motor_Count'],
      time: data['Time'],
      mode: data['Mode'],
      teachTime: data['Teach_Time'],
      cavity: data['Cavity'],
    );
  }
}