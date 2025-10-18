import 'package:flutter/material.dart';
import 'package:cheers/api/preferences_questions_api.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/datas/preferences_question.dart';
import 'package:cheers/dialogs/common_dialogs.dart';
import 'package:cheers/dialogs/progress_dialog.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/screens/home_screen.dart';
import 'package:cheers/widgets/processing.dart';

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
      appBar: AppBar(
        backgroundColor: APP_PRIMARY_COLOR,
        automaticallyImplyLeading: widget.showBackButton,
        title: Text(
          _i18n.translate('setup_preferences'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _currentPage > 0 ? _goToPreviousPage : null,
            child: const Text("Prev", style: TextStyle(color: Colors.white)),
          ),
          if (_questions != null && _currentPage == _questions!.length - 1)
            TextButton(
              onPressed: hasSelectedAnswer ? _submitAnswers : null,
              child: Text(
                _i18n.translate("SAVE"),
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: hasSelectedAnswer ? _goToNextPage : null,
              child: const Text("Next", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(children: [Expanded(child: _buildQuestions())]),
    );
  }

  Widget _buildQuestions() {
    if (_questions == null) {
      return Processing(text: _i18n.translate("loading"));
    }

    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _questions!.length,
      itemBuilder: (ctx, idx) {
        final PreferencesQuestion question = _questions![idx];
        final selectedAnswerKey = _selectedAnswersById[question.id];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${idx + 1}. ${question.question}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ...question.answers.entries.map(
                  (entry) => ListTile(
                    title: Text(entry.value.toString()),
                    leading: Radio<String>(
                      value: entry.key,
                      groupValue: selectedAnswerKey,

                      onChanged: (value) {
                        setState(() {
                          _selectedAnswersById[question.id] = value!;
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _selectedAnswersById[question.id] = entry.key;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
