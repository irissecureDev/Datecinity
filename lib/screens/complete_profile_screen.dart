import 'package:flutter/material.dart';
import 'package:cheers/api/preferences_questions_api.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/datas/preferences_question.dart';
import 'package:cheers/dialogs/common_dialogs.dart';
import 'package:cheers/dialogs/progress_dialog.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/screens/home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final bool showBackButton;
  const CompleteProfileScreen({super.key, this.showBackButton = false});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  final PreferencesQuestionsApi _api = PreferencesQuestionsApi();
  List<PreferencesQuestion>? _questions;
  late AppLocalizations _i18n;
  int _currentPage = 0;
  late ProgressDialog _pr;

  final Map<String, String> _selectedAnswersById = {};
  final Map<String, TextEditingController> _customAnswerControllers = {};

  // For multi-select questions (activities)
  final Map<String, Set<String>> _multiSelectAnswersById = {};

  // Special handling for ranking questions (Question 11 and 13)
  final Map<String, Map<String, int>> _rankingAnswersByQuestion = {};

  // For drag and drop ranking
  final Map<String, List<String>> _rankedOrderByQuestion = {};

  // Background color
  static const Color _backgroundColor = Color(0xFF120024);

  bool _isRankingQuestion(PreferencesQuestion question) {
    return question.question.toLowerCase().contains('rank') ||
        question.question.toLowerCase().contains('love language') ||
        question.question.toLowerCase().contains(
          'how important are the following factors',
        );
  }

  bool _isMultiSelectQuestion(PreferencesQuestion question) {
    return question.question.toLowerCase().contains('activities') ||
        question.question.toLowerCase().contains('pick all') ||
        question.question.toLowerCase().contains('select all');
  }

  /// Function to remove text within parentheses
  String _cleanAnswerText(String text) {
    return text.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }

  void _setRankingAnswersForQuestion(
    String questionId,
    Map<String, int> rankings,
  ) {
    _rankingAnswersByQuestion[questionId] = rankings;
  }

  /// Mark ranking question as answered in regular answers
  void _markRankingQuestionAsAnswered(String questionId) {
    _selectedAnswersById[questionId] = 'ranking_completed';
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _customAnswerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _i18n = AppLocalizations.of(context);
    _pr = ProgressDialog(context, isDismissible: false);

    if (_questions == null) {
      // Load existing user preferences first
      // We need to wait for questions to be loaded to check for custom answers vs keys
      _api.getQuestions().then((list) {
        if (mounted) {
          setState(() {
            _questions = list
                .map((doc) => PreferencesQuestion.fromDocument(doc.data()!))
                .toList();
            _questions!.sort((a, b) => a.order.compareTo(b.order));

            // Now load preferences effectively
            _loadExistingPreferences();
          });
        }
      });
    }
  }

  /// Load existing user preferences to pre-fill the quiz
  void _loadExistingPreferences() {
    final Map<String, dynamic>? userPreferences = UserModel().user.preferences;
    if (userPreferences != null &&
        userPreferences.isNotEmpty &&
        _questions != null) {
      setState(() {
        // Convert existing preferences to the expected format
        userPreferences.forEach((key, value) {
          if (key.startsWith('ranking_')) {
            // Handle ranking data: format is ranking_questionId_answerKey
            List<String> parts = key.split('_');
            if (parts.length >= 3) {
              String questionId = parts[1];
              String answerKey = parts
                  .sublist(2)
                  .join(
                    '_',
                  ); // Join back in case answerKey contains underscores
              int rank = int.tryParse(value.toString()) ?? 0;

              // Initialize ranking map for this question if not exists
              if (!_rankingAnswersByQuestion.containsKey(questionId)) {
                _rankingAnswersByQuestion[questionId] = {};
              }

              // Set the ranking
              _rankingAnswersByQuestion[questionId]![answerKey] = rank;

              // Mark question as answered
              _selectedAnswersById[questionId] = 'ranking_completed';
            }
          } else {
            // Regular answer
            String answerValue = value.toString();
            _selectedAnswersById[key] = answerValue;

            // Check if it is a custom answer (not in predefined keys)
            // Find the question matching this key
            try {
              final question = _questions!.firstWhere((q) => q.id == key);
              if (!question.answers.containsKey(answerValue)) {
                // It's a custom answer, initialize controller
                if (!_customAnswerControllers.containsKey(key)) {
                  _customAnswerControllers[key] = TextEditingController(
                    text: answerValue,
                  );
                } else {
                  _customAnswerControllers[key]!.text = answerValue;
                }
              }
            } catch (e) {
              // Question might have been removed or id mismatch
            }
          }
        });
      });
      debugPrint('Loaded existing preferences: $_selectedAnswersById');
      debugPrint('Loaded existing rankings: $_rankingAnswersByQuestion');
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage < (_questions!.length - 1)) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
      setState(() {
        _currentPage++;
      });
    }
  }

  void _submitAnswers() {
    _pr.show(_i18n.translate("processing"));

    // Prepare final preferences including ranking data
    Map<String, String> finalPreferences = Map.from(_selectedAnswersById);

    // Add ranking data for all ranking questions
    if (_rankingAnswersByQuestion.isNotEmpty) {
      _rankingAnswersByQuestion.forEach((questionId, rankings) {
        rankings.forEach((answerKey, rank) {
          if (rank > 0) {
            finalPreferences['ranking_${questionId}_$answerKey'] = rank
                .toString();
          }
        });
      });
    }

    UserModel().updatePreferences(
      preferences: finalPreferences,
      onSuccess: () async {
        // Mark user as having seen welcome screen
        await UserModel().updateUserData(
          userId: UserModel().user.userId,
          data: {USER_HAS_SEEN_WELCOME: true},
        );

        _pr.hide();

        /// Show success message
        successDialog(
          context,
          message: _i18n.translate("profile_updated_successfully"),
          positiveAction: () {
            /// Close dialog
            Future(
              () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              ),
            );
          },
        );
      },
      onFail: (error) {
        _pr.hide();
        // Debug error
        debugPrint(error);
        // Show error message
        errorDialog(
          context,
          message: _i18n.translate(
            "an_error_occurred_while_updating_your_profile",
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasSelectedAnswer = false;

    if (_questions != null) {
      PreferencesQuestion currentQuestion = _questions![_currentPage];

      if (_isRankingQuestion(currentQuestion)) {
        // For ranking questions, check if at least 1 item is ranked
        List<String>? rankedOrder = _rankedOrderByQuestion[currentQuestion.id];
        hasSelectedAnswer = rankedOrder != null && rankedOrder.isNotEmpty;
      } else if (_isMultiSelectQuestion(currentQuestion)) {
        // For multi-select questions
        Set<String>? selected = _multiSelectAnswersById[currentQuestion.id];
        hasSelectedAnswer = selected != null && selected.isNotEmpty;
      } else {
        // For regular questions, check if an answer is selected
        hasSelectedAnswer = _selectedAnswersById[currentQuestion.id] != null;
      }
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(child: _buildQuestions(hasSelectedAnswer)),
    );
  }

  Widget _buildProgressHeader() {
    if (_questions == null) return const SizedBox();

    return Row(
      children: [
        if (widget.showBackButton || _currentPage > 0)
          GestureDetector(
            onTap: _currentPage > 0
                ? _goToPreviousPage
                : () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white70,
                size: 22,
              ),
            ),
          )
        else
          const SizedBox(width: 38),

        Expanded(
          child: Column(
            children: [
              // Progress indicator
              Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_currentPage + 1) / _questions!.length,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFA7E45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_currentPage + 1} / ${_questions!.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 38),
      ],
    );
  }

  Widget _buildContinueButton(bool hasSelectedAnswer) {
    if (_questions == null) return const SizedBox();

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: hasSelectedAnswer
            ? (_currentPage == _questions!.length - 1
                  ? _submitAnswers
                  : _goToNextPage)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasSelectedAnswer
              ? const Color(0xFFFA7E45)
              : Colors.white.withOpacity(0.2),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withOpacity(0.1),
          disabledForegroundColor: Colors.white.withOpacity(0.5),
          elevation: hasSelectedAnswer ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          _currentPage == _questions!.length - 1
              ? _i18n.translate("SAVE")
              : "Continue",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildQuestions(bool hasSelectedAnswer) {
    if (_questions == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              _i18n.translate("loading"),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _questions!.length,
      itemBuilder: (ctx, idx) {
        final PreferencesQuestion question = _questions![idx];

        // Check if this is the ranking question
        if (_isRankingQuestion(question)) {
          return _buildRankingQuestionPage(question, hasSelectedAnswer);
        }

        // Check if this is a multi-select question (activities)
        if (_isMultiSelectQuestion(question)) {
          return _buildMultiSelectQuestionPage(question, hasSelectedAnswer);
        }

        // Regular single-select question
        return _buildSingleSelectQuestionPage(question, hasSelectedAnswer);
      },
    );
  }

  /// Build ranking question with drag and drop
  Widget _buildRankingQuestionPage(
    PreferencesQuestion question,
    bool hasSelectedAnswer,
  ) {
    List<String> answerKeys = question.answers.keys.toList();

    // Initialize ranked order if not exists
    if (!_rankedOrderByQuestion.containsKey(question.id)) {
      _rankedOrderByQuestion[question.id] = List.from(answerKeys);
    }

    List<String> rankedOrder = _rankedOrderByQuestion[question.id]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Progress bar
          _buildProgressHeader(),

          const SizedBox(height: 20),

          // Question Title
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'drag and drop',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 20),

          // Ranking items (non-scrollable list within scroll view)
          ...rankedOrder.asMap().entries.map((entry) {
            int index = entry.key;
            String key = entry.value;
            String answerText = _cleanAnswerText(
              (question.answers[key] ?? '').toString(),
            );

            return GestureDetector(
              onVerticalDragUpdate: (details) {
                // Handle drag to reorder
                if (details.delta.dy.abs() > 5) {
                  int newIndex = index;
                  if (details.delta.dy > 0 && index < rankedOrder.length - 1) {
                    newIndex = index + 1;
                  } else if (details.delta.dy < 0 && index > 0) {
                    newIndex = index - 1;
                  }
                  if (newIndex != index) {
                    setState(() {
                      final item = rankedOrder.removeAt(index);
                      rankedOrder.insert(newIndex, item);
                      _rankedOrderByQuestion[question.id] = rankedOrder;

                      Map<String, int> rankings = {};
                      for (int i = 0; i < rankedOrder.length; i++) {
                        rankings[rankedOrder[i]] = i + 1;
                      }
                      _setRankingAnswersForQuestion(question.id, rankings);
                      _markRankingQuestionAsAnswered(question.id);
                    });
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D2050).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Rank number badge with gradient
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFA7E45), Color(0xFFE8824A)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Answer text
                      Expanded(
                        child: Text(
                          answerText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Drag handle
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.menu,
                          color: Colors.white.withOpacity(0.5),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Bottom button
          _buildContinueButton(hasSelectedAnswer),

          const SizedBox(height: 20),

          // Logo
          Image.asset('assets/images/logo-no-bg.png', width: 50, height: 50),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Get icon for answer text based on content analysis
  IconData _getIconForAnswer(String answerText, String answerKey) {
    String lowerText = answerText.toLowerCase();
    String lowerKey = answerKey.toLowerCase();

    // ============ QUESTION 1: What role should a romantic relationship play in your life? ============
    if (lowerText.contains('flows naturally') ||
        lowerText.contains('without pressure')) {
      return Icons.water_drop;
    }
    if (lowerText.contains('partnership') ||
        lowerText.contains('unity') ||
        lowerText.contains('build and grow') ||
        lowerText.contains('grow together')) {
      return Icons.handshake;
    }
    if (lowerText.contains('deep emotional') ||
        lowerText.contains('emotional connection')) {
      return Icons.favorite;
    }
    if (lowerText.contains('supportive base') ||
        lowerText.contains('pursue my personal') ||
        lowerText.contains('goals/career') ||
        lowerText.contains('career')) {
      return Icons.work_outline;
    }

    // ============ QUESTION 2: How do you usually respond when you're upset? ============
    if (lowerText.contains('distract') || lowerText.contains('suppress')) {
      return Icons.visibility_off;
    }
    if (lowerText.contains('reassurance') ||
        lowerText.contains('closeness') ||
        lowerText.contains('seek reassurance')) {
      return Icons.favorite_border;
    }
    if (lowerText.contains('openly communicate') ||
        lowerText.contains('communicate how i feel')) {
      return Icons.chat;
    }
    if (lowerText.contains('need space') || lowerText.contains('process alone')) {
      return Icons.person_outline;
    }

    // ============ QUESTION 3: Communication style in conflict ============
    if (lowerText.contains('strong emotional') ||
        lowerText.contains('emotional responses')) {
      return Icons.whatshot;
    }
    if (lowerText.contains('overwhelmed') ||
        lowerText.contains('want resolution')) {
      return Icons.psychology_alt;
    }
    if (lowerText.contains('avoid the topic') ||
        lowerText.contains('shut down')) {
      return Icons.block;
    }
    if (lowerText.contains('level head') ||
        lowerText.contains('logically') ||
        lowerText.contains('approach conflict logically')) {
      return Icons.psychology;
    }

    // ============ QUESTION 4: Physical intimacy importance ============
    if (lowerText.contains('slower') || lowerText.contains('less frequent')) {
      return Icons.hourglass_bottom;
    }
    if (lowerText.contains('important, but not everything') ||
        lowerText.contains('not everything')) {
      return Icons.star_half;
    }
    if (lowerText.contains('depends on the emotional') ||
        lowerText.contains('emotional connection')) {
      return Icons.link;
    }
    if (lowerText.contains('extremely important')) return Icons.star;

    // ============ QUESTION 5: Ideal life goal with a partner ============
    if (lowerText.contains('uplift') ||
        lowerText.contains('encourage') ||
        lowerText.contains('personal growth')) {
      return Icons.trending_up;
    }
    if (lowerText.contains('career ambition') ||
        lowerText.contains('financial stability')) {
      return Icons.business_center;
    }
    if (lowerText.contains('meaningful experiences') ||
        lowerText.contains('explore the world')) {
      return Icons.explore;
    }
    if (lowerText.contains('build a family')) return Icons.family_restroom;

    // ============ QUESTION 6: Personality type ============
    if (lowerText.contains('extrovert') || lowerKey.contains('extrovert')) {
      return Icons.groups;
    }
    if (lowerText.contains('introvert') && !lowerText.contains('extrovert')) {
      return Icons.person;
    }
    if (lowerText.contains('both extrovert') ||
        lowerText.contains('and introverted')) {
      return Icons.swap_horiz;
    }

    // ============ QUESTION 7: Similarity or complementarity ============
    if (lowerText.contains("don't know") ||
        lowerText.contains('depends on the vibe') ||
        lowerText.contains('vibe')) {
      return Icons.help_outline;
    }
    if (lowerText.contains('complementary') ||
        lowerText.contains('balance my strengths') ||
        lowerText.contains('weaknesses')) {
      return Icons.balance;
    }
    if (lowerText.contains('a mix') || lowerText.contains('common ground')) {
      return Icons.compare_arrows;
    }
    if (lowerText.contains('similar') ||
        lowerText.contains('same interests') ||
        lowerText.contains('same energy')) {
      return Icons.people;
    }

    // ============ QUESTION 8: How do you make decisions? ============
    if (lowerText.contains('second-guess') ||
        lowerText.contains('seek a lot of reassurance')) {
      return Icons.help_center;
    }
    if (lowerText.contains('joint decision') ||
        lowerText.contains('decision-making')) {
      return Icons.group_work;
    }
    if (lowerText.contains('go with the flow')) return Icons.waves;
    if (lowerText.contains('take the lead') ||
        lowerText.contains('prefer to take')) {
      return Icons.military_tech;
    }

    // ============ QUESTION 9: Essential in a long-term partner ============
    if (lowerText.contains('dependability') ||
        lowerText.contains('consistency')) {
      return Icons.verified;
    }
    if (lowerText.contains('shared ambition')) return Icons.rocket_launch;
    if (lowerText.contains('humor') || lowerText.contains('playfulness')) {
      return Icons.sentiment_very_satisfied;
    }
    if (lowerText.contains('emotional stability')) {
      return Icons.self_improvement;
    }

    // ============ QUESTION 10: Independence in a relationship ============
    if (lowerText.contains('needs changes') ||
        lowerText.contains("partner's role")) {
      return Icons.change_circle;
    }
    if (lowerText.contains('balanced') ||
        lowerText.contains('closeness and space')) {
      return Icons.compare_arrows;
    }
    if (lowerText.contains('prefer closeness') ||
        lowerText.contains('daily connection')) {
      return Icons.people_alt;
    }
    if (lowerText.contains('a lot') ||
        lowerText.contains('freedom') ||
        lowerText.contains('independence') ||
        lowerText.contains('value freedom')) {
      return Icons.flight_takeoff;
    }

    // ============ QUESTION 12: Love languages ============
    if (lowerText.contains('acts of service') || lowerKey.contains('service')) {
      return Icons.handshake_outlined;
    }
    if (lowerText.contains('physical touch') || lowerKey.contains('touch')) {
      return Icons.pan_tool_outlined;
    }
    if (lowerText == 'gift' || lowerKey.contains('gift')) {
      return Icons.card_giftcard;
    }
    if (lowerText.contains('quality time') || lowerKey.contains('quality')) {
      return Icons.schedule;
    }
    if (lowerText.contains('words of affirmation') ||
        lowerKey.contains('affirmation')) {
      return Icons.chat_bubble_outline;
    }

    // ============ OTHER/SPECIFY option ============
    if (lowerText.contains('other') || lowerText.contains('specify')) {
      return Icons.edit;
    }

    // ============ GENERAL FALLBACKS ============
    // Family
    if (lowerText.contains('family')) return Icons.family_restroom;

    // Career/Work
    if (lowerText.contains('career') ||
        lowerText.contains('work') ||
        lowerText.contains('ambition') ||
        lowerText.contains('profession')) {
      return Icons.work;
    }

    // Spiritual
    if (lowerText.contains('spiritual') ||
        lowerText.contains('faith') ||
        lowerText.contains('religious')) {
      return Icons.auto_awesome;
    }

    // Health/Fitness
    if (lowerText.contains('health') ||
        lowerText.contains('fitness') ||
        lowerText.contains('workout') ||
        lowerText.contains('gym')) {
      return Icons.fitness_center;
    }

    // Education
    if (lowerText.contains('education') ||
        lowerText.contains('learning') ||
        lowerText.contains('reading') ||
        lowerText.contains('study')) {
      return Icons.school;
    }

    // Travel
    if (lowerText.contains('travel') || lowerText.contains('adventure')) {
      return Icons.flight;
    }

    // Money
    if (lowerText.contains('money') ||
        lowerText.contains('financial') ||
        lowerText.contains('wealth')) {
      return Icons.attach_money;
    }

    // Cooking
    if (lowerText.contains('cook') || lowerText.contains('food')) {
      return Icons.restaurant;
    }

    // Time of day
    if (lowerText.contains('morning') || lowerText.contains('early')) {
      return Icons.wb_sunny;
    }
    if (lowerText.contains('night') ||
        lowerText.contains('evening') ||
        lowerText.contains('owl')) {
      return Icons.nightlight_round;
    }

    // Location
    if (lowerText.contains('city') || lowerText.contains('urban')) {
      return Icons.location_city;
    }
    if (lowerText.contains('rural') ||
        lowerText.contains('country') ||
        lowerText.contains('nature') ||
        lowerText.contains('outdoor')) {
      return Icons.park;
    }
    if (lowerText.contains('suburb') || lowerText.contains('house')) {
      return Icons.home;
    }

    // Interests
    if (lowerText.contains('pet') ||
        lowerText.contains('animal') ||
        lowerText.contains('dog') ||
        lowerText.contains('cat')) {
      return Icons.pets;
    }
    if (lowerText.contains('children') || lowerText.contains('kids')) {
      return Icons.child_care;
    }
    if (lowerText.contains('music') || lowerText.contains('concert')) {
      return Icons.music_note;
    }
    if (lowerText.contains('game') || lowerText.contains('gaming')) {
      return Icons.sports_esports;
    }
    if (lowerText.contains('sport') || lowerText.contains('athletic')) {
      return Icons.sports_soccer;
    }
    if (lowerText.contains('movie') ||
        lowerText.contains('film') ||
        lowerText.contains('cinema') ||
        lowerText.contains('netflix')) {
      return Icons.movie;
    }
    if (lowerText.contains('book') || lowerText.contains('read')) {
      return Icons.menu_book;
    }
    if (lowerText.contains('art') || lowerText.contains('museum')) {
      return Icons.palette;
    }
    if (lowerText.contains('dance') || lowerText.contains('dancing')) {
      return Icons.nightlife;
    }
    if (lowerText.contains('photo') || lowerText.contains('camera')) {
      return Icons.camera_alt;
    }

    // Social preferences
    if (lowerText.contains('alone') || lowerText.contains('solo')) {
      return Icons.person_outline;
    }
    if (lowerText.contains('together') || lowerText.contains('partner')) {
      return Icons.people_alt;
    }
    if (lowerText.contains('social') ||
        lowerText.contains('party') ||
        lowerText.contains('event')) {
      return Icons.celebration;
    }
    if (lowerText.contains('quiet') || lowerText.contains('stay home')) {
      return Icons.weekend;
    }

    // Frequency scales
    if (lowerText.contains('very') ||
        lowerText.contains('extremely') ||
        lowerText.contains('always') ||
        lowerText.contains('essential')) {
      return Icons.star;
    }
    if (lowerText.contains('somewhat') ||
        lowerText.contains('moderate') ||
        lowerText.contains('sometimes')) {
      return Icons.star_half;
    }
    if (lowerText.contains('not important') ||
        lowerText.contains('never') ||
        lowerText.contains('rarely')) {
      return Icons.star_border;
    }

    // Yes/No
    if (lowerText == 'yes' ||
        lowerText.contains('agree') ||
        lowerText.contains('absolutely')) {
      return Icons.check_circle_outline;
    }
    if (lowerText == 'no' || lowerText.contains('disagree')) {
      return Icons.cancel_outlined;
    }
    if (lowerText.contains('maybe') ||
        lowerText.contains('unsure') ||
        lowerText.contains('depend')) {
      return Icons.help_outline;
    }

    // Volunteering
    if (lowerText.contains('volunteer') ||
        lowerText.contains('charity') ||
        lowerText.contains('community')) {
      return Icons.volunteer_activism;
    }

    // Default - radio button for unmatched answers
    return Icons.radio_button_unchecked;
  }

  /// Build multi-select question (activities)
  Widget _buildMultiSelectQuestionPage(
    PreferencesQuestion question,
    bool hasSelectedAnswer,
  ) {
    Set<String> selectedKeys = _multiSelectAnswersById[question.id] ?? {};
    final answerEntries = question.answers.entries.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Progress bar
          _buildProgressHeader(),

          const SizedBox(height: 20),

          // Question Title
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            '(Pick all that apply)',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 24),

          // Options list with icons
          ...answerEntries.map((entry) {
            String key = entry.key;
            String answerText = _cleanAnswerText(entry.value.toString());
            bool isSelected = selectedKeys.contains(key);
            final IconData icon = _getIconForAnswer(answerText, key);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (!_multiSelectAnswersById.containsKey(question.id)) {
                    _multiSelectAnswersById[question.id] = {};
                  }
                  if (isSelected) {
                    _multiSelectAnswersById[question.id]!.remove(key);
                  } else {
                    _multiSelectAnswersById[question.id]!.add(key);
                  }
                  // Also update single answer for compatibility
                  if (_multiSelectAnswersById[question.id]!.isNotEmpty) {
                    _selectedAnswersById[question.id] =
                        _multiSelectAnswersById[question.id]!.join(',');
                  } else {
                    _selectedAnswersById.remove(question.id);
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFE8824A),
                            Color(0xFFB84A5A),
                            Color(0xFF6B2D5C),
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : const Color(0xFF3D2050).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      // Icon based on answer text
                      Icon(
                        icon,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        size: 26,
                      ),

                      const SizedBox(width: 16),

                      // Answer text
                      Expanded(
                        child: Text(
                          answerText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Bottom button
          _buildContinueButton(hasSelectedAnswer),

          const SizedBox(height: 20),

          // Logo
          Image.asset('assets/images/logo-no-bg.png', width: 50, height: 50),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Build single-select question
  Widget _buildSingleSelectQuestionPage(
    PreferencesQuestion question,
    bool hasSelectedAnswer,
  ) {
    final selectedAnswerKey = _selectedAnswersById[question.id];
    final answerEntries = question.answers.entries.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Progress Header
          _buildProgressHeader(),

          const SizedBox(height: 30),

          // Question Title
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Choose the answer that best matches you',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 24),

          // Options list with icons
          ...answerEntries.map((entry) {
            final bool isSelected = selectedAnswerKey == entry.key;
            final String answerText = _cleanAnswerText(entry.value.toString());
            final IconData icon = _getIconForAnswer(answerText, entry.key);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAnswersById[question.id] = entry.key;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFE8824A),
                            Color(0xFFB84A5A),
                            Color(0xFF6B2D5C),
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : const Color(0xFF3D2050).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      // Icon based on answer text
                      Icon(
                        icon,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        size: 26,
                      ),

                      const SizedBox(width: 16),

                      // Answer text
                      Expanded(
                        child: Text(
                          answerText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Custom answer option
          _buildCustomAnswerOption(question, selectedAnswerKey),

          const SizedBox(height: 30),

          // Continue Button
          _buildContinueButton(hasSelectedAnswer),

          const SizedBox(height: 30),

          // Logo at bottom
          Image.asset('assets/images/logo-no-bg.png', width: 60, height: 60),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCustomAnswerOption(
    PreferencesQuestion question,
    String? selectedAnswerKey,
  ) {
    final bool isCustomSelected =
        selectedAnswerKey != null &&
        !question.answers.containsKey(selectedAnswerKey);

    // Initialize controller if needed
    if (!_customAnswerControllers.containsKey(question.id)) {
      _customAnswerControllers[question.id] = TextEditingController();
      if (isCustomSelected) {
        _customAnswerControllers[question.id]!.text = selectedAnswerKey;
      }
    }

    final controller = _customAnswerControllers[question.id]!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAnswersById[question.id] = controller.text;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: isCustomSelected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFE8824A),
                    Color(0xFFB84A5A),
                    Color(0xFF6B2D5C),
                  ],
                )
              : null,
          color: isCustomSelected
              ? null
              : const Color(0xFF3D2050).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCustomSelected
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon
              Icon(
                Icons.edit_outlined,
                color: isCustomSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
                size: 24,
              ),

              const SizedBox(width: 16),

              // Custom Input
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: _i18n.translate("other_specify"),
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCustomSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedAnswersById[question.id] = value;
                    });
                  },
                  onTap: () {
                    setState(() {
                      _selectedAnswersById[question.id] = controller.text;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
