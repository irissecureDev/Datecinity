import 'dart:io';

import 'package:datecinity/datas/user.dart';
import 'package:datecinity/dialogs/common_dialogs.dart';
import 'package:datecinity/helpers/app_localizations.dart';
import 'package:datecinity/models/user_model.dart';
import 'package:datecinity/screens/sign_in_screen.dart';
import 'package:datecinity/screens/update_location_sceen.dart';
import 'package:datecinity/widgets/image_source_sheet.dart';
import 'package:datecinity/widgets/processing.dart';
import 'package:datecinity/widgets/show_scaffold_msg.dart';
import 'package:datecinity/widgets/svg_icon.dart';
import 'package:datecinity/widgets/terms_of_service_row.dart';
import 'package:flutter/material.dart';
import 'package:datecinity/widgets/default_button.dart';
import 'package:flutter_cupertino_datetime_picker/flutter_cupertino_datetime_picker.dart';
import 'package:scoped_model/scoped_model.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  // Variables
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedEducation;
  String? _selectedReligion;
  final List<String> _hobbies = [];
  final List<String> _pets = [];
  final List<String> _languages = [];
  final _hobbyController = TextEditingController();
  final _petController = TextEditingController();
  final _languagesController = TextEditingController();

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
  late AppLocalizations _i18n;

  /// Add item to a list
  void _addToList(
    String value,
    List<String> list,
    TextEditingController controller,
  ) {
    if (value.trim().isEmpty) return;
    if (!list.contains(value.trim())) {
      setState(() {
        list.add(value.trim());
      });
    }
    controller.clear();
  }

  /// Remove item from a list
  void _removeFromList(String value, List<String> list) {
    setState(() {
      list.remove(value);
    });
  }

  /// Set terms
  void _setAgreeTerms(bool value) {
    setState(() {
      _agreeTerms = value;
    });
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
    // Inicial value
    DateTimePickerLocale locale = DateTimePickerLocale.en_us;
    // Get the name of the current locale.
    switch (_i18n.translate('lang')) {
      // Handle your Supported Languages below:
      case 'en': // English
        locale = DateTimePickerLocale.en_us;
        break;
    }
    return locale;
  }

  /// Display date picker.
  void _showDatePicker() {
    DatePicker.showDatePicker(
      context,
      onMonthChangeStartWithFirstDate: true,
      pickerTheme: DateTimePickerTheme(
        showTitle: true,
        confirm: Text(
          _i18n.translate('DONE'),
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
      onChange: (dateTime, List<int> index) {
        // Get birthday info
        _updateUserBithdayInfo(dateTime);
      },
      onConfirm: (dateTime, List<int> index) {
        // Get birthday info
        _updateUserBithdayInfo(dateTime);
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Initialization
    _i18n = AppLocalizations.of(context);
    _birthday = _i18n.translate("select_your_birthday");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE6DBD0),
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
          _i18n.translate("sign_up"),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          // LOGOUT BUTTON
          TextButton(
            child: Text(
              _i18n.translate('sign_out'),
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            onPressed: () {
              // Log out button
              UserModel().signOut().then((_) {
                /// Go to login screen
                Future(() {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                  );
                });
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: <Widget>[
                  Text(
                    _i18n.translate("create_account"),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// Profile photo
                  GestureDetector(
                    child: Center(
                      child: _imageFile == null
                          ? CircleAvatar(
                              radius: 60,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const SvgIcon(
                                "assets/icons/camera_icon.svg",
                                width: 40,
                                height: 40,
                                color: Colors.white,
                              ),
                            )
                          : CircleAvatar(
                              radius: 60,
                              backgroundImage: FileImage(_imageFile!),
                            ),
                    ),
                    onTap: () {
                      /// Get profile image
                      _getImage(context);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _i18n.translate("profile_photo"),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 22),

                  /// Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        /// FullName field
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: _i18n.translate("fullname"),
                            hintText: _i18n.translate("enter_your_fullname"),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SvgIcon("assets/icons/user_icon.svg"),
                            ),
                          ),
                          validator: (name) {
                            // Basic validation
                            if (name?.isEmpty ?? false) {
                              return _i18n.translate(
                                "please_enter_your_fullname",
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        /// User gender
                        DropdownButtonFormField<String>(
                          items: _genders.map((gender) {
                            return DropdownMenuItem(
                              value: gender,
                              child: _i18n.translate("lang") != 'en'
                                  ? Text(
                                      '${gender.toString()} - ${_i18n.translate(gender.toString().toLowerCase())}',
                                    )
                                  : Text(gender.toString()),
                            );
                          }).toList(),
                          hint: Text(_i18n.translate("select_gender")),
                          onChanged: (gender) {
                            setState(() {
                              _selectedGender = gender;
                            });
                          },
                          validator: (String? value) {
                            if (value == null) {
                              return _i18n.translate(
                                "please_select_your_gender",
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        /// Birthday card
                        Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: BorderSide(color: Colors.grey[350] as Color),
                          ),
                          child: ListTile(
                            leading: const SvgIcon(
                              "assets/icons/calendar_icon.svg",
                            ),
                            title: Text(
                              _birthday!,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: const Icon(Icons.arrow_drop_down),
                            onTap: () {
                              /// Select birthday
                              _showDatePicker();
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        /// School field
                        DropdownButtonFormField<String>(
                          value: _selectedEducation,
                          decoration: InputDecoration(
                            labelText: _i18n.translate("education"),
                            hintText: _i18n.translate(
                              "choose_your_education_level",
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(9.0),
                              child: SvgIcon(
                                "assets/icons/university_icon.svg",
                              ),
                            ),
                          ),
                          items: educationLevels
                              .map(
                                (level) => DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedEducation = value),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _selectedReligion,
                          decoration: InputDecoration(
                            labelText: _i18n.translate("religion"),
                            hintText: _i18n.translate("choose_your_religion"),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(9.0),
                              child: const Icon(
                                Icons.list,
                                color: Colors.black38,
                              ),
                            ),
                          ),
                          items: religions
                              .map(
                                (level) => DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedReligion = value),
                        ),

                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _hobbyController,
                                    decoration: InputDecoration(
                                      hintText: _i18n.translate("add_hobby"),
                                      labelText: _i18n.translate("hobbies"),
                                    ),
                                    onSubmitted: (value) => _addToList(
                                      value,
                                      _hobbies,
                                      _hobbyController,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _addToList(
                                    _hobbyController.text,
                                    _hobbies,
                                    _hobbyController,
                                  ),
                                  child: Text(_i18n.translate("add")),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _hobbies
                                  .map(
                                    (hobby) => Chip(
                                      label: Text(
                                        hobby,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onDeleted: () =>
                                          _removeFromList(hobby, _hobbies),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Pets (free input)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _petController,
                                    decoration: InputDecoration(
                                      hintText: _i18n.translate("app_pet"),
                                      labelText: _i18n.translate("pets"),
                                    ),
                                    onSubmitted: (value) => _addToList(
                                      value,
                                      _pets,
                                      _petController,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _addToList(
                                    _petController.text,
                                    _pets,
                                    _petController,
                                  ),
                                  child: Text(_i18n.translate("add")),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _pets
                                  .map(
                                    (pet) => Chip(
                                      label: Text(
                                        pet,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onDeleted: () =>
                                          _removeFromList(pet, _pets),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _languagesController,
                                    decoration: InputDecoration(
                                      hintText: _i18n.translate("add_language"),
                                      labelText: _i18n.translate("languages"),
                                    ),
                                    onSubmitted: (value) => _addToList(
                                      value,
                                      _languages,
                                      _languagesController,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _addToList(
                                    _languagesController.text,
                                    _languages,
                                    _languagesController,
                                  ),
                                  child: Text(_i18n.translate("add")),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _languages
                                  .map(
                                    (language) => Chip(
                                      label: Text(
                                        language,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onDeleted: () =>
                                          _removeFromList(language, _languages),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20.0),

                        /// Bio field
                        TextFormField(
                          controller: _bioController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: _i18n.translate("bio"),
                            hintText: _i18n.translate("please_write_your_bio"),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SvgIcon("assets/icons/info_icon.svg"),
                            ),
                          ),
                          validator: (bio) {
                            if (bio?.isEmpty ?? false) {
                              return _i18n.translate("please_write_your_bio");
                            }
                            return null;
                          },
                        ),

                        /// Agree terms
                        const SizedBox(height: 5),
                        _agreePrivacy(),
                        const SizedBox(height: 20),

                        /// Sign Up button
                        SizedBox(
                          width: double.maxFinite,
                          child: DefaultButton(
                            child: Text(
                              _i18n.translate("CREATE_ACCOUNT"),
                              style: const TextStyle(fontSize: 18),
                            ),
                            onPressed: () {
                              /// Sign up
                              _createAccount();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Handle Create account
  void _createAccount() async {
    /// check image file
    if (_imageFile == null) {
      // Show error message
      showScaffoldMessage(
        context: context,
        message: _i18n.translate("please_select_your_profile_photo"),
        bgcolor: Colors.red,
      );
      // validate terms
    } else if (!_agreeTerms) {
      // Show error message
      showScaffoldMessage(
        context: context,
        message: _i18n.translate("you_must_agree_to_our_privacy_policy"),
        bgcolor: Colors.red,
      );

      /// Validate form
    } else if (UserModel().calculateUserAge(_initialDateTime) < 18) {
      // Show error message
      showScaffoldMessage(
        context: context,
        duration: const Duration(seconds: 7),
        message: _i18n.translate(
          "only_18_years_old_and_above_are_allowed_to_create_an_account",
        ),
        bgcolor: Colors.red,
      );
    } else if (!_formKey.currentState!.validate()) {
    } else {
      /// Call all input onSaved method
      _formKey.currentState!.save();

      /// Call sign up method
      UserModel().signUp(
        userPhotoFile: _imageFile!,
        userFullName: _nameController.text.trim(),
        userGender: _selectedGender!,
        userBirthDay: _userBirthDay,
        userBirthMonth: _userBirthMonth,
        userBirthYear: _userBirthYear,
        hobbies: _hobbies,
        pets: _pets,
        languages: _languages,
        userBio: _bioController.text.trim(),
        religion: _selectedReligion ?? '',
        educationLevel: _selectedEducation ?? '',
        onSuccess: () async {
          // Show success message
          successDialog(
            context,
            message: _i18n.translate(
              "your_account_has_been_created_successfully",
            ),
            positiveAction: () {
              // Execute action
              // Go to get the user device's current location
              Future(() {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const UpdateLocationScreen(),
                  ),
                  (route) => false,
                );
              });
              // End
            },
          );
        },
        onFail: (error) {
          // Debug error
          debugPrint(error);
          // Show error message
          errorDialog(
            context,
            message:
                "${_i18n.translate("an_error_occurred_while_creating_your_account")}Error: $error",
          );
        },
      );
    }
  }

  /// Handle Agree privacy policy
  Widget _agreePrivacy() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          Checkbox(
            activeColor: Theme.of(context).primaryColor,
            value: _agreeTerms,
            onChanged: (value) {
              _setAgreeTerms(value!);
            },
          ),
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: () => _setAgreeTerms(!_agreeTerms),
                child: Text(
                  _i18n.translate("i_agree_with"),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              // Terms of Service and Privacy Policy
              TermsOfServiceRow(color: Colors.black),
            ],
          ),
        ],
      ),
    );
  }
}
