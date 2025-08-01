class PreferencesQuestion {
  final String question;
  final Map<String, dynamic> answers;
  final int order;
  final bool active;
  final String id;

  PreferencesQuestion({
    required this.id,
    required this.question,
    required this.answers,
    required this.order,
    this.active = true,
  });

  factory PreferencesQuestion.fromDocument(Map<String, dynamic> doc) {
    return PreferencesQuestion(
      id: doc['id'],
      question: doc['question'] ?? '',
      answers: Map<String, dynamic>.from(doc['answers'] ?? {}),
      order: doc['order'] ?? 0,
      active: doc['active'] ?? true,
    );
  }
}
