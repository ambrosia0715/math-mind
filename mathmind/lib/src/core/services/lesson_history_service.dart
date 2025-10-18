import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/lessons/domain/lesson_history.dart';

class LessonHistoryService {
  LessonHistoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('lesson_history');

  Future<void> save(LessonHistory history) async {
    await _collection.doc(history.id).set(history.toJson());
  }

  Future<String> create(LessonHistory history) async {
    final doc = await _collection.add(history.toJson());
    return doc.id;
  }

  Stream<List<LessonHistory>> watchByUser(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('learned_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(LessonHistory.fromFirestore).toList(),
        );
  }

  Stream<List<LessonHistory>> watchDueReviews(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('review_due')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(LessonHistory.fromFirestore).toList(),
        );
  }
}
