import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme.dart';

final allCategoriesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final firestore = FirebaseFirestore.instance;
  return firestore.collection('date').snapshots().asyncMap((snapshot) async {
    List<Map<String, dynamic>> categoriesJson = [];
    for (var doc in snapshot.docs) {
      var dateId = doc.id;
      var categoriesSnapshot = await doc.reference.collection('categories').get();
      for (var categoryDoc in categoriesSnapshot.docs) {
        Map<String, dynamic> categoryData = {
          'id': dateId,
          'side': categoryDoc['side'],
          'time': categoryDoc['time'],
          'count': categoryDoc['count']
        };
        categoriesJson.add(categoryData);
      }
    }
    return categoriesJson;
  });
});

final latestCategoryProvider = StreamProvider<List<Map<String, dynamic>>?>((ref) {
  final firestore = FirebaseFirestore.instance;
  return firestore.collection('date')
      .orderBy('dateField', descending: true)
      .limit(1)
      .snapshots()
      .asyncMap((snapshot) async {
    if (snapshot.docs.isEmpty) return null;

    var doc = snapshot.docs.first;
    var dateId = doc.id;
    var dateField = doc['dateField'];
    var categoriesSnapshot = await doc.reference.collection('categories').get();

    // 최신 문서에 대한 카테고리 데이터만 가져옴
    List<Map<String, dynamic>> categoriesJson = categoriesSnapshot.docs.map((categoryDoc) {
      return {
        'id': dateId,
        'dateField': dateField,
        'side': categoryDoc['side'],
        'time': categoryDoc['time'],
        'count': categoryDoc['count']
      };
    }).toList();

    return categoriesJson;  // List<Map<String, dynamic>> 반환
  });
});
