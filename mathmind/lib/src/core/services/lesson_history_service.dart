import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
    final stream = _collection
        .where('userId', isEqualTo: userId)
        .orderBy('learned_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(LessonHistory.fromFirestore).toList(),
        );
    return _guardPermissions(stream, context: 'watchByUser');
  }

  Stream<List<LessonHistory>> watchDueReviews(String userId) {
    final stream = _collection
        .where('userId', isEqualTo: userId)
        .orderBy('review_due')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(LessonHistory.fromFirestore).toList(),
        );
    return _guardPermissions(stream, context: 'watchDueReviews');
  }

  Stream<List<LessonHistory>> _guardPermissions(
    Stream<List<LessonHistory>> stream, {
    required String context,
  }) {
    return stream.transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) {
          if (error is FirebaseException && error.code == 'permission-denied') {
            debugPrint(
              'Firestore permission denied for $context; returning empty stream.',
            );
            sink.add(<LessonHistory>[]);
          } else {
            sink.addError(error, stackTrace);
          }
        },
      ),
    );
  }
}
