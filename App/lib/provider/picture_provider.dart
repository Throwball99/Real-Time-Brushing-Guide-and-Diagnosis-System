import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

final latestPicturesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = FirebaseFirestore.instance;
  final stream = firestore
      .collection('Picture')
      .orderBy('DataField', descending: true)
      .limit(10)
      .snapshots();

  return stream.map((snapshot) =>
      snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
});

final availableDatesProvider = Provider<List<String>>((ref) {
  final picturesAsyncValue = ref.watch(latestPicturesProvider);
  return picturesAsyncValue.when(
    data: (pictures) {
      final dateSet = pictures
          .map((pic) => DateFormat('yyyy-MM-dd').format(DateTime.parse(pic['DataField'] as String)))
          .toSet();
      final sortedDates = dateSet.toList()..sort((a, b) => b.compareTo(a));
      return sortedDates;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final filteredPicturesProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, selectedDateString) {
  final pictures = ref.watch(latestPicturesProvider).value ?? [];

  return pictures.where((pic) {
    final picDateString = (pic['DataField'] as String).substring(0, 10); // yyyy-MM-dd 부분만 추출
    return picDateString == selectedDateString;
  }).map((pic) => {
    'Cavity': pic['Cavity'] as bool,
    'DataField': pic['DataField'] as String,
    'Path': pic['Path'] as String,
    'Plaque': pic['Plaque'] as bool,
  }).toList();
});