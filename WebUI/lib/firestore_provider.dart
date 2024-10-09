import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class InfoData {
  final int direction;
  final int motorCount;
  final String time;
  final int mode;
  final String teachTime;

  InfoData({
    required this.direction,
    required this.motorCount,
    required this.time,
    required this.mode,
    required this.teachTime,
  });

  factory InfoData.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InfoData(
      direction: data['UI_Direction'],
      motorCount: data['Motor_Count'],
      time: data['Time'],
      mode: data['Mode'],
      teachTime: data['Teach_Time'],
    );
  }
}

final infoProvider = StreamProvider<InfoData>((ref) {
  final documentStream = FirebaseFirestore.instance
      .collection('UI')
      .doc('Info')
      .snapshots();

  return documentStream.map((snapshot) {
    return InfoData.fromDocument(snapshot);
  });
});

final timeLineProvider = StreamProvider<List<String>>((ref) {
  final firestore = FirebaseFirestore.instance;
  return firestore.collection('date').snapshots().map((snapshot) {
    List<String> allDates = snapshot.docs.map((doc) => doc.id).toList();
    allDates.sort((a, b) => b.compareTo(a)); // 내림차순 정렬
    return allDates.take(3).toList(); // 최근 3개 선택
  });
});