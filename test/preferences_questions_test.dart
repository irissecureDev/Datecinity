import 'package:flutter_test/flutter_test.dart';
import 'package:cheers/datas/preferences_question.dart';
import 'package:cheers/datas/preferences_answer.dart';

void main() {
  group('PreferencesQuestion', () {
    test('fromDocument creates question with all fields', () {
      final doc = {
        'id': 'q_1_1',
        'question': 'What do you want?',
        'section': 1,
        'sectionTitle': 'WHAT YOU WANT',
        'sectionOrder': 1,
        'questionOrder': 1,
        'type': 'single',
        'answers': {'a': 'Answer A', 'b': 'Answer B'},
        'answerKeys': ['a', 'b'],
        'order': 1,
        'active': true,
      };

      final question = PreferencesQuestion.fromDocument(doc);

      expect(question.id, 'q_1_1');
      expect(question.question, 'What do you want?');
      expect(question.section, 1);
      expect(question.sectionTitle, 'WHAT YOU WANT');
      expect(question.type, 'single');
      expect(question.isSingleSelect, true);
      expect(question.isMultiSelect, false);
      expect(question.isRanking, false);
      expect(question.isRating, false);
    });

    test('copyWith creates modified copy', () {
      final original = PreferencesQuestion(
        id: 'q_1_1',
        question: 'Original',
        answers: {'a': 'A'},
        order: 1,
        section: 1,
        type: 'single',
      );

      final modified = original.copyWith(question: 'Modified');

      expect(original.question, 'Original');
      expect(modified.question, 'Modified');
      expect(modified.id, original.id);
    });

    test('toMap converts to serializable format', () {
      final question = PreferencesQuestion(
        id: 'q_1_1',
        question: 'Test',
        answers: {'a': 'Answer A'},
        order: 1,
        section: 1,
        type: 'single',
      );

      final map = question.toMap();

      expect(map['id'], 'q_1_1');
      expect(map['question'], 'Test');
      expect(map['section'], 1);
      expect(map['type'], 'single');
    });

    test('Ranking question detected correctly', () {
      final ranking = PreferencesQuestion(
        id: 'q_4_11',
        question: 'Rank items',
        answers: {'a': 'Item A'},
        order: 11,
        type: 'ranking',
      );

      expect(ranking.isRanking, true);
      expect(ranking.isSingleSelect, false);
    });

    test('Multi question detected correctly', () {
      final multi = PreferencesQuestion(
        id: 'q_5_13',
        question: 'Select many',
        answers: {'workout': 'Working out'},
        order: 13,
        type: 'multi',
      );

      expect(multi.isMultiSelect, true);
      expect(multi.isSingleSelect, false);
    });

    test('Rating question detected correctly', () {
      final rating = PreferencesQuestion(
        id: 'q_7_19',
        question: 'Rate items',
        answers: {'trait1': 'Trait 1'},
        order: 19,
        type: 'rating',
      );

      expect(rating.isRating, true);
      expect(rating.isSingleSelect, false);
    });
  });

  group('UserPreferencesAnswers', () {
    test('addSingleAnswer stores answer', () {
      final answers = UserPreferencesAnswers();
      answers.addSingleAnswer('q_1_1', 'a');

      expect(answers.singleAnswers['q_1_1'], 'a');
    });

    test('addMultiAnswer stores set', () {
      final answers = UserPreferencesAnswers();
      answers.addMultiAnswer('q_5_13', {'workout', 'reading'});

      expect(answers.multiAnswers['q_5_13']?.length, 2);
      expect(answers.multiAnswers['q_5_13']?.contains('workout'), true);
    });

    test('addRankingAnswer stores ranking', () {
      final answers = UserPreferencesAnswers();
      final ranking = {'words': 1, 'touch': 2};
      answers.addRankingAnswer('q_4_11', ranking);

      expect(answers.rankingAnswers['q_4_11'], ranking);
    });

    test('addRatingAnswer stores ratings', () {
      final answers = UserPreferencesAnswers();
      final ratings = {'emotional': 5, 'political': 3};
      answers.addRatingAnswer('q_7_19', ratings);

      expect(answers.ratingAnswers['q_7_19'], ratings);
    });

    test('toFirestoreFormat flattens answers', () {
      final answers = UserPreferencesAnswers();
      answers.addSingleAnswer('q_1_1', 'a');
      answers.addMultiAnswer('q_5_13', {'workout'});

      final firestore = answers.toFirestoreFormat();

      expect(firestore['q_1_1'], 'a');
      expect(firestore['q_5_13'], ['workout']);
    });

    test('isComplete detects missing answers', () {
      final answers = UserPreferencesAnswers();
      answers.addSingleAnswer('q_1_1', 'a');

      final complete = answers.isComplete(['q_1_1', 'q_1_2']);

      expect(complete, false);
    });

    test('isComplete passes when all answered', () {
      final answers = UserPreferencesAnswers();
      answers.addSingleAnswer('q_1_1', 'a');
      answers.addSingleAnswer('q_1_2', 'b');

      final complete = answers.isComplete(['q_1_1', 'q_1_2']);

      expect(complete, true);
    });

    test('getAnsweredQuestionIds returns all answered', () {
      final answers = UserPreferencesAnswers();
      answers.addSingleAnswer('q_1_1', 'a');
      answers.addMultiAnswer('q_5_13', {'workout'});

      final ids = answers.getAnsweredQuestionIds();

      expect(ids.length, 2);
      expect(ids.contains('q_1_1'), true);
      expect(ids.contains('q_5_13'), true);
    });

    test('clear resets all answers', () {
      final answers = UserPreferencesAnswers();
      answers.addSingleAnswer('q_1_1', 'a');
      answers.clear();

      expect(answers.singleAnswers.isEmpty, true);
      expect(answers.multiAnswers.isEmpty, true);
    });
  });

  // Integration tests examples
  group('PreferencesQuestion Integration', () {
    test('Question with all types can be created', () {
      final single = PreferencesQuestion(
        id: 'q_1_1',
        question: 'Single?',
        answers: {'a': 'A'},
        order: 1,
        type: 'single',
      );

      final multi = PreferencesQuestion(
        id: 'q_5_13',
        question: 'Multi?',
        answers: {'a': 'A'},
        order: 13,
        type: 'multi',
      );

      final ranking = PreferencesQuestion(
        id: 'q_4_11',
        question: 'Rank?',
        answers: {'a': 'A'},
        order: 11,
        type: 'ranking',
      );

      final rating = PreferencesQuestion(
        id: 'q_7_19',
        question: 'Rate?',
        answers: {'a': 'A'},
        order: 19,
        type: 'rating',
      );

      expect([single, multi, ranking, rating].length, 4);
    });

    test('Answers can be created and converted', () {
      final answers = UserPreferencesAnswers();

      answers.addSingleAnswer('q_1_1', 'a');
      answers.addMultiAnswer('q_5_13', {'workout', 'reading'});
      answers.addRankingAnswer('q_4_11', {'a': 1, 'b': 2});
      answers.addRatingAnswer('q_7_19', {'emotional': 5});

      final firestore = answers.toFirestoreFormat();

      expect(firestore['q_1_1'], 'a');
      expect(firestore['q_5_13'].length, 2);
      expect(firestore['q_4_11']['a'], 1);
      expect(firestore['q_7_19_emotional'], 5);
    });
  });
}
