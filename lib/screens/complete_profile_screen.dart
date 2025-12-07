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

  // Special handling for ranking questions (Question 11 and 13)
  final Map<String, Map<String, int>> _rankingAnswersByQuestion =
      {}; // questionId -> {answerKey -> rank}
  bool _isRankingQuestion(PreferencesQuestion question) {
    return question.question.toLowerCase().contains('rank') ||
        question.question.toLowerCase().contains('love language') ||
        question.question.toLowerCase().contains(
          'how important are the following factors',
        );
  }

  /// Function to remove text within parentheses
  String _cleanAnswerText(String text) {
    return text.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  }

  // Helper methods for ranking functionality
  Map<String, int> _getRankingAnswersForQuestion(String questionId) {
    return _rankingAnswersByQuestion[questionId] ?? {};
  }

  void _setRankingAnswersForQuestion(
    String questionId,
    Map<String, int> rankings,
  ) {
    _rankingAnswersByQuestion[questionId] = rankings;
  }

  int _getNextAvailableRank(String questionId) {
    Map<String, int> rankings = _getRankingAnswersForQuestion(questionId);
    for (int i = 1; i <= 5; i++) {
      if (!rankings.values.contains(i)) {
        return i;
      }
    }
    return 6; // All ranks taken
  }

  void _adjustRanksAfterRemoval(String questionId, int removedRank) {
    Map<String, int> rankings = _getRankingAnswersForQuestion(questionId);
    rankings.forEach((key, rank) {
      if (rank > removedRank) {
        rankings[key] = rank - 1;
      }
    });
    _setRankingAnswersForQuestion(questionId, rankings);
  }

  /// Mark ranking question as answered in regular answers
  void _markRankingQuestionAsAnswered(String questionId) {
    _selectedAnswersById[questionId] = 'ranking_completed';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _i18n = AppLocalizations.of(context);
    _pr = ProgressDialog(context, isDismissible: false);

    if (_questions == null) {
      // Load existing user preferences first
      _loadExistingPreferences();

      _api.getQuestions().then((list) {
        if (mounted) {
          setState(() {
            _questions = list
                .map((doc) => PreferencesQuestion.fromDocument(doc.data()!))
                .toList();
            _questions!.sort((a, b) => a.order.compareTo(b.order));
          });
        }
      });
    }
  }

  /// Load existing user preferences to pre-fill the quiz
  void _loadExistingPreferences() {
    final Map<String, dynamic>? userPreferences = UserModel().user.preferences;
    if (userPreferences != null && userPreferences.isNotEmpty) {
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
            _selectedAnswersById[key] = value.toString();
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
        Map<String, int> rankings = _getRankingAnswersForQuestion(
          currentQuestion.id,
        );
        hasSelectedAnswer = rankings.values
            .where((rank) => rank > 0)
            .isNotEmpty;
      } else {
        // For regular questions, check if an answer is selected
        hasSelectedAnswer = _selectedAnswersById[currentQuestion.id] != null;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _i18n.translate('setup_preferences'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_questions != null)
              Text(
                '${_currentPage + 1} of ${_questions!.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [],
      ),
      body: Column(
        children: [
          /// Progress Bar
          if (_questions != null)
            Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_currentPage + 1) / _questions!.length,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

          Expanded(child: _buildQuestions()),

          /// Bottom Navigation
          if (_questions != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: Container(
                        height: 50,
                        margin: const EdgeInsets.only(right: 10),
                        child: OutlinedButton.icon(
                          onPressed: _goToPreviousPage,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text("Previous"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ),

                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: hasSelectedAnswer
                            ? LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.8),
                                ],
                              )
                            : null,
                        color: hasSelectedAnswer ? null : Colors.grey[300],
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: hasSelectedAnswer
                            ? [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.3),
                                  offset: const Offset(0, 4),
                                  blurRadius: 15,
                                ),
                              ]
                            : null,
                      ),
                      child: TextButton.icon(
                        onPressed: hasSelectedAnswer
                            ? (_currentPage == _questions!.length - 1
                                  ? _submitAnswers
                                  : _goToNextPage)
                            : null,
                        icon: Icon(
                          _currentPage == _questions!.length - 1
                              ? Icons.check
                              : Icons.chevron_right,
                          color: hasSelectedAnswer
                              ? Colors.white
                              : Colors.grey[500],
                        ),
                        label: Text(
                          _currentPage == _questions!.length - 1
                              ? _i18n.translate("SAVE")
                              : "Next",
                          style: TextStyle(
                            color: hasSelectedAnswer
                                ? Colors.white
                                : Colors.grey[500],
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestions() {
    if (_questions == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _i18n.translate("loading"),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Preparing your compatibility quiz...",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    /// Build special ranking interface for Question 11 and 13
    Widget buildRankingQuestionPage(PreferencesQuestion question) {
      // Check if question has answers
      if (question.answers.isEmpty) {
        return const Center(
          child: Text(
            'No options available for this question',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      List<String> answerKeys = question.answers.keys.toList();

      // Get or initialize ranking for this question
      Map<String, int> rankings = _getRankingAnswersForQuestion(question.id);

      // Ensure all answer keys are initialized in the rankings map
      for (String key in answerKeys) {
        if (!rankings.containsKey(key)) {
          rankings[key] = 0; // 0 means not ranked yet
        }
      }

      // Update the rankings if we added new keys
      if (rankings.isNotEmpty) {
        _setRankingAnswersForQuestion(question.id, rankings);
      }

      // Get ranked items (items with rank 1-5)
      List<String> rankedKeys = answerKeys
          .where((key) => (rankings[key] ?? 0) > 0)
          .toList();
      rankedKeys.sort((a, b) => (rankings[a] ?? 0).compareTo(rankings[b] ?? 0));

      // Get unranked items
      List<String> unrankedKeys = answerKeys
          .where((key) => (rankings[key] ?? 0) == 0)
          .toList();

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Question Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// Ranked Items (1-5)
            if (rankedKeys.isNotEmpty) ...[
              Text(
                'Ranked Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              ...rankedKeys.asMap().entries.map((entry) {
                String key = entry.value;
                int rank = rankings[key] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        offset: const Offset(0, 2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        /// Rank Number
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              rank.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        /// Answer Text
                        Expanded(
                          child: Text(
                            _cleanAnswerText(
                              (question.answers[key] ?? '').toString(),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                              height: 1.4,
                            ),
                          ),
                        ),

                        /// Remove button
                        IconButton(
                          onPressed: () {
                            setState(() {
                              rankings[key] = 0;
                              // Adjust other ranks
                              _adjustRanksAfterRemoval(question.id, rank);
                              _setRankingAnswersForQuestion(
                                question.id,
                                rankings,
                              );

                              // Check if no items are ranked anymore
                              bool hasRankedItems = rankings.values.any(
                                (r) => r > 0,
                              );
                              if (!hasRankedItems) {
                                // Remove the question from answered list
                                _selectedAnswersById.remove(question.id);
                              }
                            });
                          },
                          icon: Icon(
                            Icons.remove_circle,
                            color: Colors.red[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            /// Unranked Items
            if (unrankedKeys.isNotEmpty) ...[
              Text(
                'Available Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              ...unrankedKeys.map((key) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      // Add to ranking
                      setState(() {
                        int nextRank = _getNextAvailableRank(question.id);
                        if (nextRank <= 5) {
                          rankings[key] = nextRank;
                          _setRankingAnswersForQuestion(question.id, rankings);
                          // Mark question as answered
                          _markRankingQuestionAsAnswered(question.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          /// Add Icon
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),

                          /// Answer Text
                          Expanded(
                            child: Text(
                              _cleanAnswerText(
                                (question.answers[key] ?? '').toString(),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2D3748),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 100), // Space for bottom navigation
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

        // Check if this is the ranking question (Question 11)
        if (_isRankingQuestion(question)) {
          return buildRankingQuestionPage(question);
        }

        final selectedAnswerKey = _selectedAnswersById[question.id];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Question Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 4),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Question Number Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'Question ${idx + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Question Text
                    Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the answer that best matches you',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Answers
              ...question.answers.entries.map((entry) {
                final bool isSelected = selectedAnswerKey == entry.key;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 10,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAnswersById[question.id] = entry.key;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          /// Custom Radio Button
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),

                          /// Answer Text
                          Expanded(
                            child: Text(
                              _cleanAnswerText(entry.value.toString()),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : const Color(0xFF2D3748),
                                height: 1.4,
                              ),
                            ),
                          ),

                          /// Selected Indicator
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 100), // Space for bottom navigation
            ],
          ),
        );
      },
    );
  }
}
