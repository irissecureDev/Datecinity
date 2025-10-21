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
    UserModel().updatePreferences(
      preferences: _selectedAnswersById,
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
    final bool hasSelectedAnswer =
        _questions != null &&
        _selectedAnswersById[_questions![_currentPage].id] != null;

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
        actions: [
          if (_currentPage > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _goToPreviousPage,
                icon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  "Previous",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
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
                          label: const Text("Précédent"),
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
                    flex: 2,
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
                              : "Suivant",
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

    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _questions!.length,
      itemBuilder: (ctx, idx) {
        final PreferencesQuestion question = _questions![idx];
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
                              entry.value.toString(),
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
