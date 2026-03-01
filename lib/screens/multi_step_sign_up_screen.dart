import 'dart:io';

import 'package:cheers/datas/user.dart';
import 'package:cheers/dialogs/common_dialogs.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/screens/sign_in_screen.dart';
import 'package:cheers/screens/update_location_sceen.dart';
import 'package:cheers/widgets/image_source_sheet.dart';
import 'package:cheers/widgets/processing.dart';
import 'package:cheers/widgets/show_scaffold_msg.dart';
import 'package:cheers/widgets/svg_icon.dart';
import 'package:cheers/widgets/terms_of_service_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';
import 'package:scoped_model/scoped_model.dart';

class MultiStepSignUpScreen extends StatefulWidget {
  const MultiStepSignUpScreen({super.key});

  @override
  MultiStepSignUpScreenState createState() => MultiStepSignUpScreenState();
}

class MultiStepSignUpScreenState extends State<MultiStepSignUpScreen> {
  // Variables
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _customHobbyController = TextEditingController();
  final _customPetController = TextEditingController();
  final _customLanguageController = TextEditingController();
  String? _selectedEducation;
  String? _selectedReligion;
  final List<String> _hobbies = [];
  final List<String> _pets = [];
  final List<String> _languages = [];

  /// User Birthday info
  int _userBirthDay = 0;
  int _userBirthMonth = 0;
  int _userBirthYear = DateTime.now().year;
  // End
  DateTime _initialDateTime = DateTime.now();
  String? _birthday;
  File? _imageFile;
  bool _agreeTerms = false;
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female'];
  late AppLocalizations i18n;

  // Multi-step signup variables
  int _currentStep = 0;
  final int _totalSteps = 4;
  final PageController _pageController = PageController();

  // Listes prédéfinies pour améliorer l'UX
  final List<String> _popularHobbies = [
    'Reading',
    'Gaming',
    'Movies',
    'Music',
    'Sports',
    'Cooking',
    'Travel',
    'Photography',
    'Dancing',
    'Fitness',
    'Art',
    'Yoga',
    'Shopping',
    'Nature',
  ];

  final List<String> _popularPets = [
    'Dog',
    'Cat',
    'Fish',
    'Bird',
    'Rabbit',
    'Hamster',
    'Guinea Pig',
    'Reptile',
  ];

  final List<String> _popularLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Chinese',
    'Japanese',
  ];

  /// Add predefined item to list (for suggestions)
  void _addPredefinedToList(String value, List<String> list) {
    if (!list.contains(value)) {
      setState(() {
        list.add(value);
      });
    }
  }

  /// Add custom item to list
  void _addCustomToList(
    String value,
    List<String> list,
    TextEditingController controller,
  ) {
    if (value.trim().isNotEmpty && !list.contains(value.trim())) {
      setState(() {
        list.add(value.trim());
      });
      controller.clear();
    }
  }

  /// Remove item from a list
  void _removeFromList(String value, List<String> list) {
    setState(() {
      list.remove(value);
    });
  }

  /// Navigation methods for multi-step signup
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Get image from camera / gallery
  void _getImage(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageSourceSheet(
        onImageSelected: (image) {
          if (image != null) {
            setState(() {
              _imageFile = image;
            });
            // close modal
            Future(() => Navigator.of(context).pop());
          }
        },
      ),
    );
  }

  void _updateUserBithdayInfo(DateTime date) {
    setState(() {
      // Update the inicial date
      _initialDateTime = date;
      // Set for label
      _birthday = date.toString().split(' ')[0];
      // User birthday info
      _userBirthDay = date.day;
      _userBirthMonth = date.month;
      _userBirthYear = date.year;
    });
  }

  // Get Date time picker app locale
  DateTimePickerLocale _getDatePickerLocale() {
    // Pour simplifier, utilisons toujours en_us
    // TODO: Implémenter la localisation complète plus tard
    return DateTimePickerLocale.en_us;
  }

  /// Display date picker.
  void _showDatePicker() {
    DatePicker.showDatePicker(
      context,
      onMonthChangeStartWithFirstDate: true,
      pickerTheme: DateTimePickerTheme(
        showTitle: true,
        confirm: Text(
          i18n.translate('DONE'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      minDateTime: DateTime(1920, 1, 1),
      maxDateTime: DateTime.now(),
      initialDateTime: _initialDateTime,
      dateFormat: 'yyyy-MMMM-dd', // Date format
      locale: _getDatePickerLocale(), // Set your App Locale here
      onClose: () => debugPrint("----- onClose -----"),
      onCancel: () => debugPrint('onCancel'),
      onConfirm: (dateTime, List<int> index) {
        _updateUserBithdayInfo(dateTime);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    i18n = AppLocalizations.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: true,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          i18n.translate("sign_up"),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          // LOGOUT BUTTON
          TextButton(
            child: Text(
              i18n.translate('sign_out'),
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              // Log out
              UserModel().signOut().then((_) {
                /// Go to login screen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ScopedModelDescendant<UserModel>(
          builder: (context, child, userModel) {
            /// Check loading status
            if (userModel.isLoading) return const Processing();

            return Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(),

                // PageView for multi-step form
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentStep = index;
                      });
                    },
                    children: [
                      _buildStep1(), // Basic info
                      _buildStep2(), // Profile details
                      _buildStep3(), // Interests
                      _buildStep4(), // Bio and terms
                    ],
                  ),
                ),

                // Navigation buttons
                _buildNavigationButtons(userModel),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build progress indicator
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              bool isActive = index <= _currentStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < _totalSteps - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build Step 1: Basic Information
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Let's Get Started!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tell us about yourself",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),

          /// Profile Image
          GestureDetector(
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              radius: 60,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : null,
              child: _imageFile == null
                  ? const Icon(Icons.camera_alt, size: 30, color: Colors.white)
                  : null,
            ),
            onTap: () => _getImage(context),
          ),
          const SizedBox(height: 12),
          Text(
            "Add Photo",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 30),

          /// FullName field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: i18n.translate("fullname"),
              hintText: i18n.translate("enter_your_fullname"),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: SvgIcon("assets/icons/user_icon.svg"),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// User gender
          DropdownButtonFormField<String>(
            items: _genders.map((gender) {
              return DropdownMenuItem(
                value: gender,
                child: i18n.translate("lang") != 'en'
                    ? Text(
                        '${gender.toString()} - ${i18n.translate(gender.toString().toLowerCase())}',
                      )
                    : Text(gender.toString()),
              );
            }).toList(),
            hint: Text(i18n.translate("select_gender")),
            decoration: InputDecoration(
              labelText: i18n.translate("gender"),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            onChanged: (gender) {
              setState(() {
                _selectedGender = gender;
              });
            },
          ),

          const SizedBox(height: 20),

          /// Birthday field
          InkWell(
            onTap: _showDatePicker,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: "Date of birth",
                floatingLabelBehavior: FloatingLabelBehavior.always,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SvgIcon("assets/icons/calendar_icon.svg"),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              child: Text(
                _birthday ?? i18n.translate("tap_to_select_birthday"),
                style: TextStyle(
                  color: _birthday == null
                      ? Colors.grey.shade600
                      : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w400, // Matching other fields usually
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Step 2: Profile Details
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Profile Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Help others get to know you better",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),

          /// School field
          DropdownButtonFormField<String>(
            value: _selectedEducation,
            decoration: InputDecoration(
              labelText: i18n.translate("education"),
              hintText: i18n.translate("choose_your_education_level"),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(9.0),
                child: SvgIcon("assets/icons/university_icon.svg"),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            items: educationLevels
                .map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text(
                      level,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedEducation = value),
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: _selectedReligion,
            decoration: InputDecoration(
              labelText: i18n.translate("religion"),
              hintText: i18n.translate("choose_your_religion"),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(9.0),
                child: Icon(Icons.list, color: Colors.black38),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            items: religions
                .map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text(
                      level,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedReligion = value),
          ),
        ],
      ),
    );
  }

  /// Build Step 3: Interests
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Interests",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Share what you love to do",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),

          // Hobbies Section
          Text(
            i18n.translate("hobbies"),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Quick suggestions:",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _popularHobbies
                .where((hobby) => !_hobbies.contains(hobby))
                .take(8)
                .map(
                  (hobby) => InkWell(
                    onTap: () => _addPredefinedToList(hobby, _hobbies),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        hobby,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          // Add custom hobby field
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customHobbyController,
                  decoration: InputDecoration(
                    hintText: "Add your own hobby...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (value) =>
                      _addCustomToList(value, _hobbies, _customHobbyController),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addCustomToList(
                  _customHobbyController.text,
                  _hobbies,
                  _customHobbyController,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text("Add", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),

          if (_hobbies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _hobbies
                  .map(
                    (hobby) => Chip(
                      label: Text(
                        hobby,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.blue.shade600,
                      deleteIconColor: Colors.white,
                      onDeleted: () => _removeFromList(hobby, _hobbies),
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 30),

          // Pets Section
          Text(
            i18n.translate("pets"),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Quick suggestions:",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _popularPets
                .where((pet) => !_pets.contains(pet))
                .map(
                  (pet) => InkWell(
                    onTap: () => _addPredefinedToList(pet, _pets),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        pet,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          // Add custom pet field
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customPetController,
                  decoration: InputDecoration(
                    hintText: "Add your own pet...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (value) =>
                      _addCustomToList(value, _pets, _customPetController),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addCustomToList(
                  _customPetController.text,
                  _pets,
                  _customPetController,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text("Add", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),

          if (_pets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _pets
                  .map(
                    (pet) => Chip(
                      label: Text(
                        pet,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.green.shade600,
                      deleteIconColor: Colors.white,
                      onDeleted: () => _removeFromList(pet, _pets),
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 30),

          // Languages Section
          Text(
            i18n.translate("languages"),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Quick suggestions:",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _popularLanguages
                .where((lang) => !_languages.contains(lang))
                .take(6)
                .map(
                  (lang) => InkWell(
                    onTap: () => _addPredefinedToList(lang, _languages),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.purple.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        lang,
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          // Add custom language field
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customLanguageController,
                  decoration: InputDecoration(
                    hintText: "Add your own language...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (value) => _addCustomToList(
                    value,
                    _languages,
                    _customLanguageController,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addCustomToList(
                  _customLanguageController.text,
                  _languages,
                  _customLanguageController,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text("Add", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),

          if (_languages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _languages
                  .map(
                    (language) => Chip(
                      label: Text(
                        language,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.purple.shade600,
                      deleteIconColor: Colors.white,
                      onDeleted: () => _removeFromList(language, _languages),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Build Step 4: Bio and Terms
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Almost Done!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tell us about yourself",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 30),

          /// Bio field
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: i18n.translate("bio"),
              hintText: i18n.translate("write_your_bio"),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 30),

          /// Terms & Privacy Policy
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFF7F3BBF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF7F3BBF), width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeTerms = value ?? false;
                        });
                      },
                      activeColor: Color(0xFF7F3BBF),
                      checkColor: Colors.white,
                      side: BorderSide(color: Color(0xFF7F3BBF), width: 2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreeTerms = !_agreeTerms;
                          });
                        },
                        child: Text(
                          "${i18n.translate("i_agree_with")}${i18n.translate("terms_of_service")} & ${i18n.translate("privacy_policy")}",
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TermsOfServiceRow(color: Color(0xFF7F3BBF)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build navigation buttons
  Widget _buildNavigationButtons(UserModel userModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Previous button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Previous",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          // Next/Create button
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: () {
                if (_currentStep < _totalSteps - 1) {
                  _nextStep();
                } else {
                  _createUserAccount(userModel);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep < _totalSteps - 1 ? "Next" : "Create Account",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Create user account
  void _createUserAccount(UserModel userModel) {
    debugPrint("🚀 _createUserAccount called");

    /// Validate form
    if (_imageFile == null) {
      debugPrint("❌ No image file selected");
      showScaffoldMessage(
        context: context,
        message: i18n.translate("please_select_your_profile_photo"),
      );
      return;
    }
    debugPrint("✅ Image file OK");

    if (_nameController.text.trim().isEmpty) {
      debugPrint("❌ Name is empty");
      showScaffoldMessage(
        context: context,
        message: i18n.translate("please_enter_your_fullname"),
      );
      return;
    }
    debugPrint("✅ Name OK: ${_nameController.text.trim()}");

    if (_selectedGender == null) {
      debugPrint("❌ No gender selected");
      showScaffoldMessage(
        context: context,
        message: i18n.translate("please_select_your_gender"),
      );
      return;
    }
    debugPrint("✅ Gender OK: $_selectedGender");

    if (_birthday == null) {
      debugPrint("❌ No birthday selected");
      showScaffoldMessage(
        context: context,
        message: i18n.translate("please_select_your_birthday"),
      );
      return;
    }
    debugPrint("✅ Birthday OK: $_birthday");

    if (_bioController.text.trim().isEmpty) {
      debugPrint("❌ Bio is empty");
      showScaffoldMessage(
        context: context,
        message: i18n.translate("please_write_your_bio"),
      );
      return;
    }
    debugPrint("✅ Bio OK: ${_bioController.text.trim()}");

    // Validate age (must be 18 or older)
    final int userAge = UserModel().calculateUserAge(_initialDateTime);
    debugPrint("🎂 User age calculated: $userAge years old");

    if (userAge < 18) {
      debugPrint("❌ User under 18 years old");
      errorDialog(
        context,
        message: i18n.translate(
          "only_18_years_old_and_above_are_allowed_to_create_an_account",
        ),
      );
      return;
    }
    debugPrint("✅ Age validation passed");

    if (!_agreeTerms) {
      debugPrint("❌ Terms not agreed");
      errorDialog(
        context,
        message: i18n.translate("you_must_agree_to_our_privacy_policy"),
      );
      return;
    }
    debugPrint("✅ Terms agreed");

    debugPrint("🎯 All validations passed, calling signUp...");

    /// Create user account
    userModel.signUp(
      userPhotoFile: _imageFile!,
      userFullName: _nameController.text.trim(),
      userGender: _selectedGender!,
      userBirthDay: _userBirthDay,
      userBirthMonth: _userBirthMonth,
      userBirthYear: _userBirthYear,
      educationLevel: _selectedEducation ?? '',
      religion: _selectedReligion ?? '',
      pets: _pets,
      hobbies: _hobbies,
      languages: _languages,
      userBio: _bioController.text.trim(),
      onSuccess: () async {
        debugPrint("🎉 SignUp successful!");

        // Show success message
        successDialog(
          context,
          message: i18n.translate("your_account_has_been_created_successfully"),
          positiveAction: () {
            // Go to get the user device's current location
            Future(() {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const UpdateLocationScreen(),
                ),
                (route) => false,
              );
            });
          },
        );
      },
      onFail: (error) {
        debugPrint("💥 SignUp failed: $error");

        // Show error message
        errorDialog(
          context,
          message:
              "${i18n.translate("an_error_occurred_while_creating_your_account")}Error: $error",
        );
      },
    );
  }
}
