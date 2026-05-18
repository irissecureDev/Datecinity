import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/datas/preferences_question.dart';
import 'package:cheers/api/preferences_questions_api.dart';

/// API to handle user preference answers validation and management
class PreferencesAnswersApi {
  final FirebaseFirestore _firestore;
  final PreferencesQuestionsApi _questionsApi;

  PreferencesAnswersApi({
    FirebaseFirestore? firestore,
    PreferencesQuestionsApi? questionsApi,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _questionsApi = questionsApi ?? PreferencesQuestionsApi();

  /// Validate if all required questions have answers
  /// Returns: { valid: bool, missingQuestions: List<String>, errors: List<String> }
  Future<Map<String, dynamic>> validateAnswers(
    Map<String, dynamic> answers,
  ) async {
    try {
      final allQuestions = await _questionsApi.getAllQuestions();

      if (allQuestions.isEmpty) {
        return {
          'valid': false,
          'missingQuestions': <String>[],
          'errors': ['No questions available in Firestore'],
        };
      }

      final missingQuestions = <String>[];
      final errors = <String>[];

      for (final question in allQuestions) {
        // Check if answer exists for this question
        final hasAnswer = _questionHasAnswer(question, answers);

        if (!hasAnswer) {
          missingQuestions.add(question.id);
        }

        // Validate answer format if present
        final validationError = _validateAnswerFormat(question, answers);
        if (validationError != null) {
          errors.add(validationError);
        }
      }

      return {
        'valid': missingQuestions.isEmpty && errors.isEmpty,
        'missingQuestions': missingQuestions,
        'errors': errors,
      };
    } catch (e) {
      debugPrint('Error validating answers: $e');
      return {
        'valid': false,
        'missingQuestions': <String>[],
        'errors': ['Validation error: $e'],
      };
    }
  }

  /// Check if a question has an answer in the answers map
  bool _questionHasAnswer(
    PreferencesQuestion question,
    Map<String, dynamic> answers,
  ) {
    switch (question.type) {
      case 'single':
        return answers.containsKey(question.id);
      case 'multi':
        return answers.containsKey(question.id) &&
            answers[question.id] is List &&
            (answers[question.id] as List).isNotEmpty;
      case 'ranking':
        return answers.containsKey(question.id) && answers[question.id] is Map;
      case 'rating':
        // For rating, check if at least one trait is rated
        // Ratings are stored as "q_7_19_trait": value
        return question.answerKeys.any(
          (key) => answers.containsKey('${question.id}_$key'),
        );
      default:
        return answers.containsKey(question.id);
    }
  }

  /// Validate answer format and values
  /// Returns error message if invalid, null if valid
  String? _validateAnswerFormat(
    PreferencesQuestion question,
    Map<String, dynamic> answers,
  ) {
    if (!answers.containsKey(question.id)) {
      return null; // Already checked by _questionHasAnswer
    }

    final answer = answers[question.id];

    switch (question.type) {
      case 'single':
        if (answer is! String) {
          return '${question.id}: Expected String answer';
        }
        if (!question.answerKeys.contains(answer)) {
          return '${question.id}: Invalid answer key "$answer"';
        }
        break;

      case 'multi':
        if (answer is! List) {
          return '${question.id}: Expected List answer';
        }
        for (final item in answer) {
          if (!question.answerKeys.contains(item)) {
            return '${question.id}: Invalid answer key "$item" in list';
          }
        }
        break;

      case 'ranking':
        if (answer is! Map) {
          return '${question.id}: Expected Map answer';
        }
        // Check all keys are valid
        for (final key in answer.keys) {
          if (!question.answerKeys.contains(key)) {
            return '${question.id}: Invalid ranking key "$key"';
          }
        }
        break;

      case 'rating':
        // Rating validation happens per-trait
        for (final key in question.answerKeys) {
          final ratingKey = '${question.id}_$key';
          if (answers.containsKey(ratingKey)) {
            final rating = answers[ratingKey];
            if (rating is! int || rating < 1 || rating > 5) {
              return '$ratingKey: Expected int 1-5, got $rating';
            }
          }
        }
        break;
    }

    return null;
  }

  /// Update user preferences in Firestore
  /// Automatically validates and stores answers in USER_PREFERENCES field
  Future<void> updateUserAnswers({
    required String userId,
    required Map<String, dynamic> answers,
  }) async {
    try {
      // Validate before saving
      final validation = await validateAnswers(answers);
      if (!validation['valid']) {
        final errors = validation['errors'] as List<String>;
        throw Exception('Invalid answers: ${errors.join(", ")}');
      }

      // Save to Firestore
      await _firestore.collection('Users').doc(userId).update({
        USER_PREFERENCES: answers,
        'preferences_completed_at': FieldValue.serverTimestamp(),
      });

      debugPrint('User preferences updated for $userId');
    } catch (e) {
      debugPrint('Error updating user answers: $e');
      rethrow;
    }
  }

  /// Get user's preference answers from Firestore
  Future<Map<String, dynamic>?> getUserAnswers(String userId) async {
    try {
      final doc = await _firestore.collection('Users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?[USER_PREFERENCES] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user answers: $e');
      return null;
    }
  }

  /// Clear user's preference answers (reset)
  Future<void> clearUserAnswers(String userId) async {
    try {
      await _firestore.collection('Users').doc(userId).update({
        USER_PREFERENCES: {},
      });
      debugPrint('User preferences cleared for $userId');
    } catch (e) {
      debugPrint('Error clearing user answers: $e');
      rethrow;
    }
  }

  /// Get all required question IDs
  Future<List<String>> getRequiredQuestionIds() async {
    try {
      final allQuestions = await _questionsApi.getAllQuestions();
      return allQuestions.map((q) => q.id).toList();
    } catch (e) {
      debugPrint('Error getting required question IDs: $e');
      return [];
    }
  }
}
