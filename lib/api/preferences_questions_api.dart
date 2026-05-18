import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/datas/preferences_question.dart';

class PreferencesQuestionsApi {
  final FirebaseFirestore _firestore;

  // Cache for questions
  final Map<int, List<PreferencesQuestion>> _sectionCache = {};
  List<PreferencesQuestion>? _allQuestionsCache;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 60);

  PreferencesQuestionsApi() : _firestore = FirebaseFirestore.instance;

  /// Get all active questions (legacy method, kept for backward compatibility)
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getQuestions() async {
    try {
      final query = await _firestore
          .collection(PREFERENCES_QUESTIONS)
          .where('active', isEqualTo: true)
          .orderBy('order', descending: true)
          .get();
      return query.docs;
    } catch (e) {
      debugPrint('Error fetching preference questions: $e');
      return [];
    }
  }

  /// Get all active questions as PreferencesQuestion objects
  Future<List<PreferencesQuestion>> getAllQuestions() async {
    try {
      // Check cache
      if (_allQuestionsCache != null && _cacheTimestamp != null) {
        final now = DateTime.now();
        if (now.difference(_cacheTimestamp!) < _cacheDuration) {
          return _allQuestionsCache!;
        }
      }

      final query = await _firestore
          .collection(PREFERENCES_QUESTIONS)
          .where('active', isEqualTo: true)
          .get();

      final questions = query.docs
          .map((doc) => PreferencesQuestion.fromDocument(doc.data()))
          .toList();

      // Sort client-side — handles both 'order' and 'questionOrder' fields
      questions.sort((a, b) => a.order.compareTo(b.order));

      // Update cache
      _allQuestionsCache = questions;
      _cacheTimestamp = DateTime.now();

      return questions;
    } catch (e) {
      debugPrint('Error fetching all preference questions: $e');
      return [];
    }
  }

  /// Get questions by section (1-7)
  Future<List<PreferencesQuestion>> getQuestionsBySection(int section) async {
    try {
      // Check cache
      if (_sectionCache.containsKey(section)) {
        return _sectionCache[section]!;
      }

      final query = await _firestore
          .collection(PREFERENCES_QUESTIONS)
          .where('active', isEqualTo: true)
          .where('section', isEqualTo: section)
          .orderBy('sectionOrder')
          .get();

      final questions = query.docs
          .map((doc) => PreferencesQuestion.fromDocument(doc.data()))
          .toList();

      // Cache this section
      _sectionCache[section] = questions;

      return questions;
    } catch (e) {
      debugPrint('Error fetching section $section questions: $e');
      return [];
    }
  }

  /// Get all questions grouped by section
  /// Returns Map<int, List<PreferencesQuestion>> where int is section number (1-7)
  Future<Map<int, List<PreferencesQuestion>>> getAllQuestionsGrouped() async {
    try {
      final allQuestions = await getAllQuestions();

      final grouped = <int, List<PreferencesQuestion>>{};
      for (int i = 1; i <= 7; i++) {
        grouped[i] = allQuestions.where((q) => q.section == i).toList();
      }

      return grouped;
    } catch (e) {
      debugPrint('Error fetching grouped questions: $e');
      return {};
    }
  }

  /// Get all section metadata (titles, question counts)
  Future<List<SectionInfo>> getSectionMetadata() async {
    try {
      final grouped = await getAllQuestionsGrouped();

      final sections = <SectionInfo>[];
      for (int i = 1; i <= 7; i++) {
        if (grouped.containsKey(i) && grouped[i]!.isNotEmpty) {
          final section = grouped[i]!.first;
          sections.add(
            SectionInfo(
              sectionNumber: i,
              title: section.sectionTitle,
              questionCount: grouped[i]!.length,
            ),
          );
        }
      }

      return sections;
    } catch (e) {
      debugPrint('Error fetching section metadata: $e');
      return [];
    }
  }

  /// Clear all caches
  void clearCache() {
    _sectionCache.clear();
    _allQuestionsCache = null;
    _cacheTimestamp = null;
    debugPrint('PreferencesQuestionsApi cache cleared');
  }

  /// Refresh cache (force reload from Firestore)
  Future<void> refreshCache() async {
    clearCache();
    await getAllQuestions();
    debugPrint('PreferencesQuestionsApi cache refreshed');
  }
}

/// Model for section metadata
class SectionInfo {
  final int sectionNumber;
  final String title;
  final int questionCount;

  SectionInfo({
    required this.sectionNumber,
    required this.title,
    required this.questionCount,
  });

  @override
  String toString() =>
      'SectionInfo(section: $sectionNumber, title: $title, count: $questionCount)';
}
