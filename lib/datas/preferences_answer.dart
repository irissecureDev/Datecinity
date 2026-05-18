/// Stores a user's answer to a preference question
/// Stored in User document under 'user_preferences' field
/// Format: { "q_1_1": "a", "q_4_11_0": 0, "q_5_13": ["workout", "reading"], "q_7_19_emotional_intelligence": 5 }
class PreferencesAnswer {
  final String questionId; // e.g., "q_1_1"
  final dynamic value; // String, int, List<String>, Map<String, int>
  final String answerType; // "single", "multi", "ranking", "rating"

  PreferencesAnswer({
    required this.questionId,
    required this.value,
    required this.answerType,
  });

  /// Convert answer to map for storage
  Map<String, dynamic> toMap() {
    return {'questionId': questionId, 'value': value, 'answerType': answerType};
  }

  @override
  String toString() =>
      'PreferencesAnswer(questionId: $questionId, value: $value)';
}

/// Helper class to manage user preferences answers
class UserPreferencesAnswers {
  /// Single select answers: { "q_1_1": "a" }
  final Map<String, String> singleAnswers = {};

  /// Multi-select answers: { "q_5_13": {"workout", "reading"} }
  final Map<String, Set<String>> multiAnswers = {};

  /// Ranking answers: { "q_4_11": {"words": 1, "touch": 2, ...} }
  final Map<String, Map<String, int>> rankingAnswers = {};

  /// Rating answers: { "q_7_19": {"emotional_intelligence": 5, ...} }
  final Map<String, Map<String, int>> ratingAnswers = {};

  /// Add a single select answer
  void addSingleAnswer(String questionId, String answer) {
    singleAnswers[questionId] = answer;
  }

  /// Add a multi-select answer
  void addMultiAnswer(String questionId, Set<String> answers) {
    multiAnswers[questionId] = answers;
  }

  /// Add a ranking answer
  void addRankingAnswer(String questionId, Map<String, int> ranking) {
    rankingAnswers[questionId] = ranking;
  }

  /// Add a rating answer
  void addRatingAnswer(String questionId, Map<String, int> ratings) {
    ratingAnswers[questionId] = ratings;
  }

  /// Convert all answers to Firestore format
  /// Returns flat map: { "q_1_1": "a", "q_5_13": ["workout", "reading"], "q_7_19_emotional_intelligence": 5 }
  Map<String, dynamic> toFirestoreFormat() {
    final result = <String, dynamic>{};

    // Single answers
    result.addAll(singleAnswers);

    // Multi answers (stored as lists)
    for (final entry in multiAnswers.entries) {
      result[entry.key] = entry.value.toList();
    }

    // Ranking answers (stored as nested map or flattened)
    for (final entry in rankingAnswers.entries) {
      result[entry.key] = entry.value;
    }

    // Rating answers (stored as nested map or flattened)
    for (final entry in ratingAnswers.entries) {
      // Flatten rating answers: "q_7_19_emotional_intelligence": 5
      final questionId = entry.key;
      for (final ratingEntry in entry.value.entries) {
        result["${questionId}_${ratingEntry.key}"] = ratingEntry.value;
      }
    }

    return result;
  }

  /// Check if all required questions have answers
  /// requiredQuestionIds: list of question IDs that must have answers
  bool isComplete(List<String> requiredQuestionIds) {
    for (final qId in requiredQuestionIds) {
      if (!singleAnswers.containsKey(qId) &&
          !multiAnswers.containsKey(qId) &&
          !rankingAnswers.containsKey(qId) &&
          !ratingAnswers.containsKey(qId)) {
        return false;
      }
    }
    return true;
  }

  /// Get all question IDs that have answers
  Set<String> getAnsweredQuestionIds() {
    final ids = <String>{};
    ids.addAll(singleAnswers.keys);
    ids.addAll(multiAnswers.keys);
    ids.addAll(rankingAnswers.keys);
    ids.addAll(ratingAnswers.keys);
    return ids;
  }

  /// Clear all answers
  void clear() {
    singleAnswers.clear();
    multiAnswers.clear();
    rankingAnswers.clear();
    ratingAnswers.clear();
  }

  @override
  String toString() {
    return 'UserPreferencesAnswers(single: ${singleAnswers.length}, multi: ${multiAnswers.length}, ranking: ${rankingAnswers.length}, rating: ${ratingAnswers.length})';
  }
}
