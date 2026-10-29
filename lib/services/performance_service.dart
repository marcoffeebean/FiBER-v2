import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';
import 'data_service.dart';

class StudentActivityCounts {
  final int quizzes;
  final int mockExams;
  final int games;

  const StudentActivityCounts({
    required this.quizzes,
    required this.mockExams,
    required this.games,
  });

  int get total => quizzes + mockExams + games;

  static const empty = StudentActivityCounts(
    quizzes: 0,
    mockExams: 0,
    games: 0,
  );
}
class SubjectPerformance {
  final String subject;
  final double averagePercent;
  final int attempts;
  final int totalScore;
  final int totalPossible;

  const SubjectPerformance({
    required this.subject,
    required this.averagePercent,
    required this.attempts,
    required this.totalScore,
    required this.totalPossible,
  });

  Map<String, dynamic> toMap() => {
    'subject': subject,
    'averagePercent': averagePercent,
    'attempts': attempts,
    'totalScore': totalScore,
    'totalPossible': totalPossible,
  };
}

class StudentPerformanceSummary {
  final List<SubjectPerformance> subjects;
  final double overallAverage;
  final String? bestSubject;
  final double? bestAverage;
  final String? lowestSubject;
  final double? lowestAverage;
  final int completedAssessments;
  final DateTime? capturedAt;

  const StudentPerformanceSummary({
    required this.subjects,
    required this.overallAverage,
    this.bestSubject,
    this.bestAverage,
    this.lowestSubject,
    this.lowestAverage,
    required this.completedAssessments,
    this.capturedAt,
  });

  bool get hasData => subjects.isNotEmpty;

  String get summaryLabel {
    if (!hasData) return 'No subject data yet';
    final best = bestSubject ?? 'N/A';
    final lowest = lowestSubject ?? 'N/A';
    return 'Best: $best • Lowest: $lowest';
  }

  static StudentPerformanceSummary empty() => const StudentPerformanceSummary(
    subjects: [],
    overallAverage: 0,
    completedAssessments: 0,
  );
}

class StatisticsHistoryEntry {
  final String? id;
  final DateTime savedAt;
  final Map<String, double> subjectAverages;
  final String? bestSubject;
  final double? bestAverage;
  final String? lowestSubject;
  final double? lowestAverage;
  final double overallAverage;
  final int completedAssessments;

  const StatisticsHistoryEntry({
    this.id,
    required this.savedAt,
    required this.subjectAverages,
    this.bestSubject,
    this.bestAverage,
    this.lowestSubject,
    this.lowestAverage,
    required this.overallAverage,
    required this.completedAssessments,
  });

  String get formattedTimestamp {
    final local = savedAt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} • '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() => {
    'savedAt': Timestamp.fromDate(savedAt.toUtc()),
    'subjectAverages': subjectAverages.map(
      (key, value) => MapEntry(key, value),
    ),
    'bestSubject': bestSubject,
    'bestAverage': bestAverage,
    'lowestSubject': lowestSubject,
    'lowestAverage': lowestAverage,
    'overallAverage': overallAverage,
    'completedAssessments': completedAssessments,
  };

  factory StatisticsHistoryEntry.fromMap(
    Map<String, dynamic> map, {
    String? id,
  }) {
    final subjectAverages = <String, double>{};
    final rawSubjects = map['subjectAverages'];
    if (rawSubjects is Map) {
      rawSubjects.forEach((key, value) {
        final parsed = value is num
            ? value.toDouble()
            : double.tryParse(value.toString()) ?? 0.0;
        subjectAverages[key.toString()] = parsed;
      });
    }

    final rawSavedAt = map['savedAt'];
    final savedAt = rawSavedAt is Timestamp
        ? rawSavedAt.toDate()
        : DateTime.tryParse(rawSavedAt?.toString() ?? '') ?? DateTime.now();

    return StatisticsHistoryEntry(
      id: id,
      savedAt: savedAt,
      subjectAverages: subjectAverages,
      bestSubject: map['bestSubject']?.toString(),
      bestAverage: (map['bestAverage'] is num)
          ? (map['bestAverage'] as num).toDouble()
          : null,
      lowestSubject: map['lowestSubject']?.toString(),
      lowestAverage: (map['lowestAverage'] is num)
          ? (map['lowestAverage'] as num).toDouble()
          : null,
      overallAverage: (map['overallAverage'] is num)
          ? (map['overallAverage'] as num).toDouble()
          : 0.0,
      completedAssessments: (map['completedAssessments'] is num)
          ? (map['completedAssessments'] as num).toInt()
          : 0,
    );
  }
}

class PerformanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String _normalizeSubject(String? subject, {String? fallback}) {
    final value = (subject ?? fallback ?? 'General').trim();
    return value.isEmpty ? 'General' : value;
  }

  static double _toPercent(int score, int total) {
    if (total <= 0) return 0;
    return ((score / total) * 100.0).clamp(0.0, 100.0);
  }

  static Future<StudentActivityCounts> loadStudentActivityCounts({
    String? uid,
  }) async {
    final userId = uid ?? AuthService.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return StudentActivityCounts(
        quizzes: DataService.quizzesTaken,
        mockExams: DataService.examsTaken,
        games: DataService.gamesPlayed,
      );
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('assessment_results')
          .get();

      int quizzes = 0;
      int mockExams = 0;
      int games = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final type = (data['type'] ?? '').toString().toLowerCase();

        switch (type) {
          case 'quiz':
            quizzes++;
            break;
          case 'mock_exam':
            mockExams++;
            break;
          case 'game':
          case 'word_hunt':
            games++;
            break;
          default:
            break;
        }
      }

      return StudentActivityCounts(
        quizzes: quizzes == 0 ? DataService.quizzesTaken : quizzes,
        mockExams: mockExams == 0 ? DataService.examsTaken : mockExams,
        games: games == 0 ? DataService.gamesPlayed : games,
      );
    } catch (e) {
      debugPrint('Error loading activity counts: $e');
      return StudentActivityCounts(
        quizzes: DataService.quizzesTaken,
        mockExams: DataService.examsTaken,
        games: DataService.gamesPlayed,
      );
    }
  }
  static Future<StudentPerformanceSummary?> loadLatestSummary({
    String? uid,
  }) async {
    final userId = uid ?? AuthService.currentUser?.id;
    if (userId == null || userId.isEmpty) return null;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('assessment_results')
          .get();

      final entries = snapshot.docs
          .map((doc) => doc.data())
          .whereType<Map<String, dynamic>>()
          .toList();

      if (entries.isEmpty) {
        return StudentPerformanceSummary.empty();
      }

      final grouped = <String, List<double>>{};
      final aggregatedPossible = <String, int>{};
      final aggregatedScore = <String, int>{};
      final allPercentages = <double>[];

      for (final entry in entries) {
        final scoreValue = entry['score'];
        final totalValue = entry['total'];
        final score = scoreValue is num ? scoreValue.toInt() : 0;
        final total = totalValue is num ? totalValue.toInt() : 0;
        if (total <= 0) continue;

        final subject = _normalizeSubject(
          entry['subject']?.toString(),
          fallback: entry['moduleTitle']?.toString(),
        );
        final percent = _toPercent(score, total);
        grouped.putIfAbsent(subject, () => []).add(percent);
        allPercentages.add(percent);
        aggregatedScore[subject] = (aggregatedScore[subject] ?? 0) + score;
        aggregatedPossible[subject] =
            (aggregatedPossible[subject] ?? 0) + total;
      }

      if (grouped.isEmpty) {
        return StudentPerformanceSummary.empty();
      }

      final subjects =
          grouped.entries.map((entry) {
            final values = entry.value;
            final avg = values.reduce((a, b) => a + b) / values.length;
            final subjectName = entry.key;
            final totalScore = aggregatedScore[subjectName] ?? 0;
            final totalPossibleValue = aggregatedPossible[subjectName] ?? 0;
            return SubjectPerformance(
              subject: subjectName,
              averagePercent: avg,
              attempts: values.length,
              totalScore: totalScore,
              totalPossible: totalPossibleValue,
            );
          }).toList()..sort(
            (a, b) =>
                a.subject.toLowerCase().compareTo(b.subject.toLowerCase()),
          );

      final best = subjects.reduce(
        (a, b) => a.averagePercent >= b.averagePercent ? a : b,
      );
      final lowest = subjects.reduce(
        (a, b) => a.averagePercent <= b.averagePercent ? a : b,
      );
      final overallAverage = allPercentages.isEmpty
          ? 0.0
          : allPercentages.reduce((a, b) => a + b) / allPercentages.length;

      return StudentPerformanceSummary(
        subjects: subjects,
        overallAverage: overallAverage,
        bestSubject: best.subject,
        bestAverage: best.averagePercent,
        lowestSubject: lowest.subject,
        lowestAverage: lowest.averagePercent,
        completedAssessments: allPercentages.length,
        capturedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error loading performance summary: $e');
      return StudentPerformanceSummary.empty();
    }
  }

  static Future<List<StatisticsHistoryEntry>> loadStatisticsHistory({
    String? uid,
  }) async {
    final userId = uid ?? AuthService.currentUser?.id;
    if (userId == null || userId.isEmpty) return const [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('statistics_history')
          .orderBy('savedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StatisticsHistoryEntry.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading history: $e');
      return const [];
    }
  }

  static Future<StudentPerformanceSummary?> refreshStudentPerformance({
    String? uid,
  }) async {
    final userId = uid ?? AuthService.currentUser?.id;
    if (userId == null || userId.isEmpty) return null;

    try {
      final current = await loadLatestSummary(uid: userId);
      if (current == null || !current.hasData) {
        return current;
      }

      final historyQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('statistics_history')
          .orderBy('savedAt', descending: true)
          .limit(1)
          .get();

      final newestDoc = historyQuery.docs.isNotEmpty
          ? historyQuery.docs.first
          : null;
      final lastBest = newestDoc?.data()['bestSubject']?.toString();
      final lastWorst = newestDoc?.data()['lowestSubject']?.toString();
      final lastAverage = (newestDoc?.data()['overallAverage'] is num)
          ? (newestDoc!.data()['overallAverage'] as num).toDouble()
          : null;

      final sameSummary =
          lastBest == current.bestSubject &&
          lastWorst == current.lowestSubject &&
          lastAverage != null &&
          (lastAverage - current.overallAverage).abs() < 0.01;

      if (sameSummary) {
        return current;
      }

      final newHistoryEntry = StatisticsHistoryEntry(
        savedAt: DateTime.now(),
        subjectAverages: {
          for (final subject in current.subjects)
            subject.subject: subject.averagePercent,
        },
        bestSubject: current.bestSubject,
        bestAverage: current.bestAverage,
        lowestSubject: current.lowestSubject,
        lowestAverage: current.lowestAverage,
        overallAverage: current.overallAverage,
        completedAssessments: current.completedAssessments,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('statistics_history')
          .add(newHistoryEntry.toMap());

      return current;
    } catch (e) {
      debugPrint('Error refreshing performance history: $e');
      return null;
    }
  }

  static Future<void> recordAssessmentResult({
    required String type,
    required int score,
    required int total,
    String? subject,
    String? moduleId,
    String? moduleTitle,
    DateTime? completedAt,
  }) async {
    final userId = AuthService.currentUser?.id;
    if (userId == null || userId.isEmpty) return;
    if (total <= 0 || score < 0 || score > total) return;

    final safeSubject = _normalizeSubject(subject, fallback: moduleTitle);
    final timestamp = (completedAt ?? DateTime.now()).toUtc();

    final payload = {
      'type': type,
      'subject': safeSubject,
      'moduleId': moduleId ?? '',
      'moduleTitle': moduleTitle ?? safeSubject,
      'score': score,
      'total': total,
      'percentage': _toPercent(score, total),
      'completedAt': Timestamp.fromDate(timestamp),
      'savedAt': FieldValue.serverTimestamp(),
      'attemptKey':
          '${type}_${safeSubject}_${timestamp.millisecondsSinceEpoch}',
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('assessment_results')
        .add(payload);

    unawaited(refreshStudentPerformance(uid: userId));
  }
}
