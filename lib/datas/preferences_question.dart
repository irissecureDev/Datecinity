/// Represents a preference question with support for multiple question types:
/// - single: Single select with radio buttons (default)
/// - multi: Multiple select with checkboxes
/// - ranking: Ordered items (drag-drop)
/// - rating: Numeric scale (1-5)
class PreferencesQuestion {
  final String id;
  final String question;
  final Map<String, dynamic> answers; // { "a": "Answer text", ... }
  final List<String> answerKeys; // Order of answer keys for display
  final int order;
  final bool active;

  // New fields for section organization
  final int section; // 1-7
  final String sectionTitle; // e.g., "WHAT YOU WANT IN LOVE"
  final int sectionOrder; // Position within section
  final String type; // "single", "multi", "ranking", "rating"

  PreferencesQuestion({
    required this.id,
    required this.question,
    required this.answers,
    required this.order,
    this.active = true,
    this.section = 1,
    this.sectionTitle = '',
    this.sectionOrder = 0,
    this.type = 'single',
    List<String>? answerKeys,
  }) : answerKeys = answerKeys ?? answers.keys.toList();

  /// Create from Firestore document
  factory PreferencesQuestion.fromDocument(Map<String, dynamic> doc) {
    return PreferencesQuestion(
      id: doc['id'] ?? '',
      question: doc['question'] ?? '',
      answers: Map<String, dynamic>.from(doc['answers'] ?? {}),
      order: doc['order'] ?? doc['questionOrder'] ?? 0,
      active: doc['active'] ?? true,
      section: doc['section'] ?? 1,
      sectionTitle: doc['sectionTitle'] ?? '',
      sectionOrder: doc['sectionOrder'] ?? 0,
      type: doc['type'] ?? 'single',
      // null → constructor fallback to answers.keys.toList()
      answerKeys: doc['answerKeys'] != null
          ? List<String>.from(doc['answerKeys'])
          : null,
    );
  }

  /// Convert to map for storage/serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answers': answers,
      'answerKeys': answerKeys,
      'order': order,
      'active': active,
      'section': section,
      'sectionTitle': sectionTitle,
      'sectionOrder': sectionOrder,
      'type': type,
    };
  }

  /// Copy with modifications
  PreferencesQuestion copyWith({
    String? id,
    String? question,
    Map<String, dynamic>? answers,
    List<String>? answerKeys,
    int? order,
    bool? active,
    int? section,
    String? sectionTitle,
    int? sectionOrder,
    String? type,
  }) {
    return PreferencesQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      answers: answers ?? this.answers,
      answerKeys: answerKeys ?? this.answerKeys,
      order: order ?? this.order,
      active: active ?? this.active,
      section: section ?? this.section,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      sectionOrder: sectionOrder ?? this.sectionOrder,
      type: type ?? this.type,
    );
  }

  /// Check if question type is multi-select
  bool get isMultiSelect => type == 'multi';

  /// Check if question type is ranking
  bool get isRanking => type == 'ranking';

  /// Check if question type is rating
  bool get isRating => type == 'rating';

  /// Check if question type is single select
  bool get isSingleSelect => type == 'single';

  @override
  String toString() =>
      'PreferencesQuestion(id: $id, section: $section, type: $type)';
}
