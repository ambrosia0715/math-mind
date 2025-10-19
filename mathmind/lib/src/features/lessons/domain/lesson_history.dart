import 'package:cloud_firestore/cloud_firestore.dart';

class LessonHistory {
  LessonHistory({
    required this.id,
    required this.userId,
    required this.topic,
    required this.learnedAt,
    required this.initialScore,
    required this.reviewDue,
    required this.retentionScore,
    required this.detectedConcept,
    this.conceptExplanation,
  });

  factory LessonHistory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return LessonHistory(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      topic: data['topic'] as String? ?? '',
      learnedAt: (data['learned_at'] as Timestamp?)?.toDate(),
      initialScore: data['initial_score'] as int?,
      reviewDue: (data['review_due'] as Timestamp?)?.toDate(),
      retentionScore: data['retention_score'] as int?,
      detectedConcept: data['detected_concept'] as String?,
      conceptExplanation: data['concept_explanation'] as String?,
    );
  }

  final String id;
  final String userId;
  final String topic;
  final DateTime? learnedAt;
  final int? initialScore;
  final DateTime? reviewDue;
  final int? retentionScore;
  final String? detectedConcept;
  final String? conceptExplanation;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'topic': topic,
      'learned_at': learnedAt != null ? Timestamp.fromDate(learnedAt!) : null,
      'initial_score': initialScore,
      'review_due': reviewDue != null ? Timestamp.fromDate(reviewDue!) : null,
      'retention_score': retentionScore,
      'detected_concept': detectedConcept,
      'concept_explanation': conceptExplanation,
    }..removeWhere((_, value) => value == null);
  }

  LessonHistory copyWith({
    String? id,
    String? userId,
    String? topic,
    DateTime? learnedAt,
    int? initialScore,
    DateTime? reviewDue,
    int? retentionScore,
    String? detectedConcept,
    String? conceptExplanation,
  }) {
    return LessonHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topic: topic ?? this.topic,
      learnedAt: learnedAt ?? this.learnedAt,
      initialScore: initialScore ?? this.initialScore,
      reviewDue: reviewDue ?? this.reviewDue,
      retentionScore: retentionScore ?? this.retentionScore,
      detectedConcept: detectedConcept ?? this.detectedConcept,
      conceptExplanation: conceptExplanation ?? this.conceptExplanation,
    );
  }
}
