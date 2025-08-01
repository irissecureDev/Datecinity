import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:soulmate/constants/constants.dart';

class PreferencesQuestionsApi {
  final FirebaseFirestore _firestore;

  PreferencesQuestionsApi() : _firestore = FirebaseFirestore.instance;

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
}
