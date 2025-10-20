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
      appBar: AppBar(
        title: Text(_i18n.translate("edit_profile")),
        actions: [
          // Save changes button
          TextButton(
            child: Text(
              _i18n.translate("SAVE"),
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            onPressed: () {
              /// Validate form
              if (_formKey.currentState!.validate()) {
                _saveChanges();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Form(
            key: _formKey,
            child: ScopedModelDescendant<UserModel>(
              builder: (context, child, userModel) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Profile photo
                    GestureDetector(
                      child: Center(
                        child: Stack(
                          children: <Widget>[
                            CircleAvatar(
                              backgroundImage: NetworkImage(
                                userModel.user.userProfilePhoto,
                              ),
                              radius: 80,
                              backgroundColor: Theme.of(context).primaryColor,
                            ),

                            /// Edit icon
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () async {
                        /// Update profile image
                        _selectImage(
                          imageUrl: userModel.user.userProfilePhoto,
                          path: 'profile',
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        _i18n.translate("profile_photo"),
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    /// Profile gallery
                    Text(
                      _i18n.translate("gallery"),
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 5),

                    /// Show gallery
                    const UserGallery(),
                    const SizedBox(height: 20.0),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: _i18n.translate("bio"),
                        hintText: _i18n.translate("write_about_you"),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SvgIcon("assets/icons/info_icon.svg"),
                        ),
                      ),
                      validator: (bio) {
                        if (bio == null) {
                          return _i18n.translate("please_write_your_bio");
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    /// Bio field
                    TextFormField(
                      controller: _demographicsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Race",
                        hintText: "Describe your race/demographics",
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SvgIcon("assets/icons/info_icon.svg"),
                        ),
                      ),
                      validator: (bio) {
                        if (bio == null) {
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
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(9.0),
                          child: SvgIcon("assets/icons/university_icon.svg"),
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
                          child: const Icon(Icons.list, color: Colors.black38),
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
                                onSubmitted: (value) =>
                                    _addToList(value, _pets, _petController),
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
                                  onDeleted: () => _removeFromList(pet, _pets),
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
                                (pet) => Chip(
                                  label: Text(
                                    pet,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onDeleted: () => _removeFromList(pet, _pets),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
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
