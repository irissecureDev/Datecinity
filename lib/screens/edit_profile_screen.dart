import 'package:cheers/datas/user.dart';
import 'package:cheers/dialogs/common_dialogs.dart';
import 'package:cheers/dialogs/progress_dialog.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/widgets/image_source_sheet.dart';
import 'package:cheers/widgets/svg_icon.dart';
import 'package:cheers/widgets/user_gallery.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  // Variables
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedEducation = educationLevels.firstWhere(
    (e) => e == UserModel().user.education,
  );
  String? _selectedReligion = religions.firstWhere(
    (r) => r == UserModel().user.religion,
  );
  final List<String> _hobbies = UserModel().user.hobbies;
  final List<String> _pets = UserModel().user.pets;
  final List<String> _languages = UserModel().user.languages;
  final _hobbyController = TextEditingController();
  final _petController = TextEditingController();
  final _languagesController = TextEditingController();
  // final _schoolController = TextEditingController(
  //   text: UserModel().user.userSchool,
  // );
  // final _jobController = TextEditingController(
  //   text: UserModel().user.userJobTitle,
  // );
  final _bioController = TextEditingController(text: UserModel().user.userBio);
  final _demographicsController = TextEditingController(
    text: UserModel().user.demographics,
  );
  late AppLocalizations _i18n;
  late ProgressDialog _pr;

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

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);
    _pr = ProgressDialog(context, isDismissible: false);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          _i18n.translate("edit_profile"),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          // Save changes button
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton(
              onPressed: () {
                /// Validate form
                if (_formKey.currentState!.validate()) {
                  _saveChanges();
                }
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                _i18n.translate("SAVE"),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ScopedModelDescendant<UserModel>(
              builder: (context, child, userModel) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Profile photo section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            child: Stack(
                              children: <Widget>[
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.3),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      userModel.user.userProfilePhoto,
                                    ),
                                    radius: 60,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                  ),
                                ),

                                /// Edit icon
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.transparent,
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () async {
                              /// Update profile image
                              _selectImage(
                                imageUrl: userModel.user.userProfilePhoto,
                                path: 'profile',
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _i18n.translate("profile_photo"),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tap to change your profile picture",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Gallery section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.1),
                                      Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.photo_library,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _i18n.translate("gallery"),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          /// Show gallery
                          const UserGallery(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Form fields section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Personal Information",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _bioController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: _i18n.translate("bio"),
                              hintText: _i18n.translate("write_about_you"),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12.0),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SvgIcon(
                                  "assets/icons/info_icon.svg",
                                  color: Theme.of(context).primaryColor,
                                  width: 16,
                                  height: 16,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            validator: (bio) {
                              if (bio == null || bio.trim().isEmpty) {
                                return _i18n.translate("please_write_your_bio");
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          /// Demographics field
                          TextFormField(
                            controller: _demographicsController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: "Race",
                              hintText: "Describe your race/demographics",
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12.0),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SvgIcon(
                                  "assets/icons/info_icon.svg",
                                  color: Theme.of(context).primaryColor,
                                  width: 16,
                                  height: 16,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            validator: (bio) {
                              if (bio == null || bio.trim().isEmpty) {
                                return "Please describe your race";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedEducation,
                            decoration: InputDecoration(
                              labelText: _i18n.translate("education"),
                              hintText: _i18n.translate(
                                "choose_your_education_level",
                              ),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12.0),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SvgIcon(
                                  "assets/icons/university_icon.svg",
                                  color: Theme.of(context).primaryColor,
                                  width: 16,
                                  height: 16,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
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
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12.0),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.favorite,
                                  color: Theme.of(context).primaryColor,
                                  size: 16,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Interests section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Interests & Preferences",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          /// Hobbies section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.1),
                                          Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.sports_soccer,
                                      color: Theme.of(context).primaryColor,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _i18n.translate("hobbies"),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _hobbyController,
                                      decoration: InputDecoration(
                                        hintText: _i18n.translate("add_hobby"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                      onSubmitted: (value) => _addToList(
                                        value,
                                        _hobbies,
                                        _hobbyController,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextButton(
                                      onPressed: () => _addToList(
                                        _hobbyController.text,
                                        _hobbies,
                                        _hobbyController,
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _i18n.translate("add"),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _hobbies
                                    .map(
                                      (hobby) => Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).primaryColor,
                                              Theme.of(
                                                context,
                                              ).primaryColor.withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Chip(
                                          label: Text(
                                            hobby,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.transparent,
                                          deleteIconColor: Colors.white,
                                          onDeleted: () =>
                                              _removeFromList(hobby, _hobbies),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Pets section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.1),
                                          Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.pets,
                                      color: Theme.of(context).primaryColor,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _i18n.translate("pets"),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _petController,
                                      decoration: InputDecoration(
                                        hintText: _i18n.translate("app_pet"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                      onSubmitted: (value) => _addToList(
                                        value,
                                        _pets,
                                        _petController,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextButton(
                                      onPressed: () => _addToList(
                                        _petController.text,
                                        _pets,
                                        _petController,
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _i18n.translate("add"),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _pets
                                    .map(
                                      (pet) => Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).primaryColor,
                                              Theme.of(
                                                context,
                                              ).primaryColor.withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Chip(
                                          label: Text(
                                            pet,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.transparent,
                                          deleteIconColor: Colors.white,
                                          onDeleted: () =>
                                              _removeFromList(pet, _pets),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          /// Languages section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.1),
                                          Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.language,
                                      color: Theme.of(context).primaryColor,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _i18n.translate("languages"),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _languagesController,
                                      decoration: InputDecoration(
                                        hintText: _i18n.translate(
                                          "add_language",
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                      onSubmitted: (value) => _addToList(
                                        value,
                                        _languages,
                                        _languagesController,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: TextButton(
                                      onPressed: () => _addToList(
                                        _languagesController.text,
                                        _languages,
                                        _languagesController,
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _i18n.translate("add"),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _languages
                                    .map(
                                      (language) => Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).primaryColor,
                                              Theme.of(
                                                context,
                                              ).primaryColor.withOpacity(0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Chip(
                                          label: Text(
                                            language,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.transparent,
                                          deleteIconColor: Colors.white,
                                          onDeleted: () => _removeFromList(
                                            language,
                                            _languages,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Get image from camera / gallery
  void _selectImage({required String imageUrl, required String path}) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageSourceSheet(
        onImageSelected: (image) async {
          if (image != null) {
            /// Show progress dialog
            _pr.show(_i18n.translate("processing"));

            /// Update profile image
            await UserModel().updateProfileImage(
              imageFile: image,
              oldImageUrl: imageUrl,
              path: 'profile',
            );
            // Hide dialog
            _pr.hide();
            // close modal
            Future(() => Navigator.of(context).pop());
          }
        },
      ),
    );
  }

  /// Update profile changes for TextFormField only
  void _saveChanges() {
    /// Update uer profile
    UserModel().updateProfile(
      // userSchool: _schoolController.text.trim(),
      // userJobTitle: _jobController.text.trim(),
      userBio: _bioController.text.trim(),
      educationLevel: _selectedEducation ?? '',
      religion: _selectedReligion ?? '',
      pets: _pets,
      hobbies: _hobbies,
      languages: _languages,
      demographics: _demographicsController.text.trim(),
      onSuccess: () {
        /// Show success message
        successDialog(
          context,
          message: _i18n.translate("profile_updated_successfully"),
          positiveAction: () {
            /// Close dialog
            Future(() => Navigator.of(context).pop());
          },
        );
      },
      onFail: (error) {
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
}
