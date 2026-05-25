import 'package:flutter/material.dart';
import 'package:datecinity/api/preferences_questions_api.dart';
import 'package:datecinity/api/preferences_answers_api.dart';
import 'package:datecinity/constants/constants.dart';
import 'package:datecinity/datas/preferences_question.dart';
import 'package:datecinity/datas/preferences_answer.dart';
import 'package:datecinity/dialogs/common_dialogs.dart';
import 'package:datecinity/dialogs/progress_dialog.dart';
import 'package:datecinity/helpers/app_localizations.dart';
import 'package:datecinity/models/user_model.dart';
import 'package:datecinity/screens/home_screen.dart';

/// Refactored CompleteProfileScreen with TabBar for 7 sections
/// Supports 4 question types: single, multi, ranking, rating
class CompleteProfileScreen extends StatefulWidget {
  final bool showBackButton;
  const CompleteProfileScreen({super.key, this.showBackButton = false});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PreferencesQuestionsApi _questionsApi = PreferencesQuestionsApi();
  final PreferencesAnswersApi _answersApi = PreferencesAnswersApi();

  Map<int, List<PreferencesQuestion>> _questionsBySection = {};
  late AppLocalizations _i18n;
  late ProgressDialog _pr;

  // Answer storage
  final UserPreferencesAnswers _userAnswers = UserPreferencesAnswers();

  // Controllers for custom answers
  final Map<String, TextEditingController> _customAnswerControllers = {};

  // Controllers for ranking questions
  late Map<String, List<String>> _rankingOrderByQuestion = {};

  static const Color _backgroundColor = Color(0xFF120024);
  static const Color _accentColor = Color(0xFFFA7E45);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadQuestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
  }

  /// Load all questions grouped by section
  Future<void> _loadQuestions() async {
    try {
      final grouped = await _questionsApi.getAllQuestionsGrouped();

      if (mounted) {
        setState(() {
          _questionsBySection = grouped;
          // Initialize ranking order maps and pre-populate ranking answers
          for (final section in grouped.values) {
            for (final question in section) {
              if (question.isRanking) {
                final order = List<String>.from(question.answerKeys);
                _rankingOrderByQuestion[question.id] = order;
                // Pre-populate so default order counts as answered
                final rankings = <String, int>{};
                for (int i = 0; i < order.length; i++) {
                  rankings[order[i]] = i + 1;
                }
                _userAnswers.addRankingAnswer(question.id, rankings);
              }
            }
          }
        });
      }

      // Load existing preferences if any
      _loadExistingPreferences();
    } catch (e) {
      debugPrint('Error loading questions: $e');
      if (mounted) {
        errorDialog(
          context,
          message: _i18n.translate('error_loading_questions'),
        );
      }
    }
  }

  /// Load existing user preferences to pre-fill answers
  Future<void> _loadExistingPreferences() async {
    try {
      final userId = UserModel().user.userId;
      final existingAnswers = await _answersApi.getUserAnswers(userId);

      if (existingAnswers != null && mounted) {
        setState(() {
          existingAnswers.forEach((key, value) {
            // Handle different answer types
            if (key.startsWith('q_') && value is String) {
              // Single select answer
              _userAnswers.addSingleAnswer(key, value);
            } else if (key.startsWith('q_') && value is List) {
              // Multi select answer
              _userAnswers.addMultiAnswer(key, Set.from(value));
            } else if (key.startsWith('q_') && value is Map) {
              // Ranking answer (Firestore returns Map<String, dynamic>)
              final ranking = Map<String, int>.from(
                value.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
              );
              _userAnswers.addRankingAnswer(key, ranking);
              // Sync visual order: sort by rank value
              final sorted = ranking.entries.toList()
                ..sort((a, b) => a.value.compareTo(b.value));
              _rankingOrderByQuestion[key] = sorted.map((e) => e.key).toList();
            }
          });
        });
      }
    } catch (e) {
      debugPrint('Error loading existing preferences: $e');
    }
  }

  /// Validate all required questions have answers
  /// Submit all answers to Firestore
  void _submitAnswers() {
    _pr.show(_i18n.translate("processing"));

    final userId = UserModel().user.userId;
    final firestoreFormat = _userAnswers.toFirestoreFormat();

    UserModel().updatePreferences(
      preferences: firestoreFormat,
      onSuccess: () async {
        await UserModel().updateUserData(
          userId: userId,
          data: {USER_HAS_SEEN_WELCOME: true},
        );

        _pr.hide();
        successDialog(
          context,
          message: _i18n.translate("profile_updated_successfully"),
          positiveAction: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
        );
      },
      onFail: (error) {
        _pr.hide();
        debugPrint('Error updating preferences: $error');
        errorDialog(
          context,
          message: _i18n.translate(
            "an_error_occurred_while_updating_your_profile",
          ),
        );
      },
    );
  }

  /// Build question widget based on type
  Widget _buildQuestionWidget(PreferencesQuestion question) {
    switch (question.type) {
      case 'multi':
        return _buildMultiSelectQuestion(question);
      case 'ranking':
        return _buildRankingQuestion(question);
      case 'rating':
        return _buildRatingQuestion(question);
      case 'single':
      default:
        return _buildSingleSelectQuestion(question);
    }
  }

  /// Build single-select question (radio buttons)
  Widget _buildSingleSelectQuestion(PreferencesQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...question.answerKeys.map((key) {
          final answer = question.answers[key] as String;
          final isSelected = _userAnswers.singleAnswers[question.id] == key;

          return GestureDetector(
            onTap: () {
              setState(() {
                _userAnswers.addSingleAnswer(question.id, key);
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? _accentColor : Colors.white24,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? _accentColor.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _accentColor : Colors.white54,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _accentColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      answer,
                      style: TextStyle(
                        fontSize: 15,
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Build multi-select question (checkboxes)
  Widget _buildMultiSelectQuestion(PreferencesQuestion question) {
    final selected = _userAnswers.multiAnswers[question.id] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: question.answerKeys.map((key) {
            final answer = question.answers[key] as String;
            final isSelected = selected.contains(key);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selected.remove(key);
                  } else {
                    selected.add(key);
                  }
                  _userAnswers.addMultiAnswer(question.id, selected);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? _accentColor : Colors.white24,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  color: isSelected
                      ? _accentColor.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? _accentColor : Colors.white54,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isSelected
                          ? Center(
                              child: Icon(
                                Icons.check,
                                size: 14,
                                color: _accentColor,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      answer,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build ranking question (drag-drop reorderable)
  Widget _buildRankingQuestion(PreferencesQuestion question) {
    List<String> rankedOrder =
        _rankingOrderByQuestion[question.id] ?? question.answerKeys;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Drag to reorder',
          style: TextStyle(fontSize: 13, color: Colors.white54),
        ),
        const SizedBox(height: 16),
        ReorderableListView(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = rankedOrder.removeAt(oldIndex);
              rankedOrder.insert(newIndex, item);
              _rankingOrderByQuestion[question.id] = rankedOrder;

              // Update ranking map
              final rankings = <String, int>{};
              for (int i = 0; i < rankedOrder.length; i++) {
                rankings[rankedOrder[i]] = i + 1;
              }
              _userAnswers.addRankingAnswer(question.id, rankings);
            });
          },
          children: rankedOrder.asMap().entries.map((entry) {
            final index = entry.key;
            final key = entry.value;
            final answer = question.answers[key] as String;

            return Container(
              key: ValueKey(key),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.05),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accentColor,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      answer,
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.drag_handle, color: Colors.white54),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build rating question (1-5 scale with buttons)
  Widget _buildRatingQuestion(PreferencesQuestion question) {
    final ratings = _userAnswers.ratingAnswers[question.id] ?? <String, int>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        ...question.answerKeys.map((key) {
          final trait = question.answers[key] as String;
          final rating = ratings[key] ?? 0;

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      trait,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final ratingValue = index + 1;
                      final isSelected = rating == ratingValue;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            ratings[key] = ratingValue;
                            _userAnswers.addRatingAnswer(question.id, ratings);
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? _accentColor : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                            color: isSelected
                                ? _accentColor.withOpacity(0.2)
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: Text(
                              '$ratingValue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? _accentColor
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questionsBySection.isEmpty) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
              ),
              const SizedBox(height: 20),
              Text(
                _i18n.translate("loading"),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get section titles
    final sections = [
      'WHAT YOU\nWANT IN LOVE',
      'HOW YOU\nHANDLE FEELINGS',
      'HOW YOU\nCOMMUNICATE',
      'LOVE &\nCONNECTION',
      'LIFESTYLE &\nHABITS',
      'PERSONALITY &\nCONNECTION',
      'WHAT\nMATTERS MOST',
    ];

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            indicatorColor: const Color(0xFF9B59B6),
            tabs: List.generate(7, (index) {
              return SizedBox(
                height: 60,
                child: Center(
                  child: Text(
                    sections[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(7, (sectionIndex) {
          final sectionNumber = sectionIndex + 1;
          final questions = _questionsBySection[sectionNumber] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                ...questions.map((question) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: _buildQuestionWidget(question),
                  );
                }).toList(),
                const SizedBox(height: 20),
              ],
            ),
          );
        }),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: _backgroundColor,
        child: ElevatedButton(
          onPressed: _submitAnswers,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            _i18n.translate("SAVE"),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
