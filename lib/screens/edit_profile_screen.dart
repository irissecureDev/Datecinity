import 'package:cheers/datas/user.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/dialogs/common_dialogs.dart';
import 'package:cheers/dialogs/progress_dialog.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/screens/profile_screen.dart';
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
    orElse: () => educationLevels.first,
  );
  String? _selectedReligion = religions.firstWhere(
    (r) => r == UserModel().user.religion,
    orElse: () => religions.first,
  );
  final List<String> _hobbies = UserModel().user.hobbies;
  final List<String> _pets = UserModel().user.pets;
  final List<String> _languages = UserModel().user.languages;
  late final List<String> _dealBreakers;
  late final List<String> _lifestyleTags;
  static const List<String> _relationshipTypes = [
    'Long-term relationship',
    'Casual dating',
    'Serious commitment',
    'Not sure yet',
  ];
  static const List<String> _familyPlanningOptions = [
    'Not now',
    'Soon',
    'Ready now',
  ];
  static const List<String> _visibilityOptions = [
    'Visible',
    'Hidden',
    'Matches only',
  ];
  static const List<String> _habitOptions = ['No', 'A little', 'A lot'];
  final _hobbyController = TextEditingController();
  final _petController = TextEditingController();
  final _languagesController = TextEditingController();
  final _dealBreakersController = TextEditingController();
  final _lifestyleController = TextEditingController();
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
  final _heightController = TextEditingController(
    text: UserModel().user.heightCm?.toString() ?? '',
  );
  final _weightController = TextEditingController(
    text: UserModel().user.weightKg?.toString() ?? '',
  );
  late String _familyPlanning;
  late bool _financialReadiness;
  late double _desiredChildrenCount;
  late bool _hasChildren;
  late double _childrenCount;
  late bool _wantsChildren;
  late String _smokingHabit;
  late String _alcoholHabit;
  late String _profilePhotoVisibility;
  late String _galleryVisibility;
  late String _identityVisibility;
  late String _interestsVisibility;
  late String _relationshipType;
  late double _preferredMaxDistance;
  late double _preferredMinAge;
  late double _preferredMaxAge;
  TextEditingController? _fullnameController;
  DateTime? _selectedBirthDate;
  late AppLocalizations _i18n;
  late ProgressDialog _pr;
  bool _showMediaSection = true;
  bool _showPersonalSection = true;
  bool _showPreferencesSection = true;
  bool _hasUnsavedChanges = false;
  DateTime? _lastSavedAt;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _attachChangeListeners();
    _familyPlanning =
        UserModel().user.familyPlanning ?? _familyPlanningOptions.first;
    _financialReadiness = UserModel().user.financialReadiness ?? false;
    _desiredChildrenCount = (UserModel().user.desiredChildrenCount ?? 0)
        .toDouble()
        .clamp(0, 10);
    _hasChildren = UserModel().user.hasChildren ?? false;
    _childrenCount = (UserModel().user.childrenCount ?? 0).toDouble().clamp(
      0,
      10,
    );
    _wantsChildren = UserModel().user.wantsChildren ?? true;
    _smokingHabit = UserModel().user.smokingHabit ?? _habitOptions.first;
    _alcoholHabit = UserModel().user.alcoholHabit ?? _habitOptions.first;
    final currentPrefs = UserModel().user.preferences ?? {};
    _dealBreakers = _toStringList(currentPrefs['deal_breakers']);
    _lifestyleTags = _toStringList(currentPrefs['lifestyle_tags']);
    _relationshipType =
        (currentPrefs['relationship_type']?.toString().trim().isNotEmpty ??
            false)
        ? currentPrefs['relationship_type'].toString()
        : _relationshipTypes.first;

    final userSettings = UserModel().user.userSettings ?? {};
    final settingsMaxDistance =
        (userSettings[USER_MAX_DISTANCE] as num?)?.toDouble() ?? 50.0;
    final settingsMinAge =
        (userSettings[USER_MIN_AGE] as num?)?.toDouble() ?? 18;
    final settingsMaxAge =
        (userSettings[USER_MAX_AGE] as num?)?.toDouble() ?? 45;
    _profilePhotoVisibility =
        userSettings[USER_VISIBILITY_PROFILE_PHOTO]?.toString() ??
        _visibilityOptions.first;
    _galleryVisibility =
        userSettings[USER_VISIBILITY_GALLERY]?.toString() ??
        _visibilityOptions.first;
    _identityVisibility =
        userSettings[USER_VISIBILITY_IDENTITY]?.toString() ??
        _visibilityOptions.first;
    _interestsVisibility =
        userSettings[USER_VISIBILITY_INTERESTS]?.toString() ??
        _visibilityOptions.first;
    _preferredMaxDistance = settingsMaxDistance.clamp(1, 500);
    _preferredMinAge = settingsMinAge.clamp(18, 80);
    _preferredMaxAge = settingsMaxAge.clamp(_preferredMinAge, 100);
  }

  void _initControllers() {
    _fullnameController ??= TextEditingController(
      text: UserModel().user.userFullname,
    );
    _selectedBirthDate ??= DateTime(
      UserModel().user.userBirthYear,
      UserModel().user.userBirthMonth,
      UserModel().user.userBirthDay,
    );
  }

  @override
  void dispose() {
    _detachChangeListeners();
    _hobbyController.dispose();
    _petController.dispose();
    _languagesController.dispose();
    _dealBreakersController.dispose();
    _lifestyleController.dispose();
    _bioController.dispose();
    _demographicsController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _fullnameController?.dispose();
    super.dispose();
  }

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
        _hasUnsavedChanges = true;
      });
    }
    controller.clear();
  }

  /// Remove item from a list
  void _removeFromList(String value, List<String> list) {
    setState(() {
      list.remove(value);
      _hasUnsavedChanges = true;
    });
  }

  void _attachChangeListeners() {
    _fullnameController?.addListener(_markUnsaved);
    _bioController.addListener(_markUnsaved);
    _demographicsController.addListener(_markUnsaved);
    _hobbyController.addListener(_markUnsaved);
    _petController.addListener(_markUnsaved);
    _languagesController.addListener(_markUnsaved);
    _dealBreakersController.addListener(_markUnsaved);
    _lifestyleController.addListener(_markUnsaved);
    _heightController.addListener(_markUnsaved);
    _weightController.addListener(_markUnsaved);
  }

  void _detachChangeListeners() {
    _fullnameController?.removeListener(_markUnsaved);
    _bioController.removeListener(_markUnsaved);
    _demographicsController.removeListener(_markUnsaved);
    _hobbyController.removeListener(_markUnsaved);
    _petController.removeListener(_markUnsaved);
    _languagesController.removeListener(_markUnsaved);
    _dealBreakersController.removeListener(_markUnsaved);
    _lifestyleController.removeListener(_markUnsaved);
    _heightController.removeListener(_markUnsaved);
    _weightController.removeListener(_markUnsaved);
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return [];
  }

  void _markUnsaved() {
    if (_hasUnsavedChanges) return;
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  int _requiredRemaining(UserModel userModel) {
    int required = 0;
    if (userModel.user.userProfilePhoto.trim().isEmpty) required++;
    if ((_fullnameController?.text.trim().isEmpty ?? true)) required++;
    if (_bioController.text.trim().isEmpty) required++;
    if (_demographicsController.text.trim().isEmpty) required++;
    if (_hobbies.isEmpty) required++;
    if (_languages.isEmpty) required++;
    return required;
  }

  int _galleryCount(UserModel userModel) {
    return (userModel.user.userGallery?.values
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .length) ??
        0;
  }

  double _sectionProgress({required int completed, required int total}) {
    if (total == 0) return 0;
    return (completed / total).clamp(0, 1);
  }

  String _savedStatusText() {
    if (_hasUnsavedChanges) return 'Unsaved changes';
    if (_lastSavedAt == null) return 'Editing profile';
    final minutes = DateTime.now().difference(_lastSavedAt!).inMinutes;
    if (minutes <= 0) return 'Saved just now';
    return 'Saved $minutes min ago';
  }

  int? _parsePositiveInt(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _initControllers();
    _i18n = AppLocalizations.of(context);
    _pr = ProgressDialog(context, isDismissible: false);

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
          _i18n.translate("edit_profile"),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Preview profile',
              icon: const Icon(Icons.visibility_outlined, color: Colors.white),
              onPressed: () {
                if (_hasUnsavedChanges) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Preview shows saved profile. Save changes to update preview.',
                      ),
                    ),
                  );
                }

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      user: UserModel().user,
                      showButtons: false,
                      respectVisibilitySettings: true,
                      isPreviewMode: true,
                    ),
                  ),
                );
              },
            ),
          ),
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
                _requiredRemaining(UserModel()) == 0
                    ? _i18n.translate("DONE")
                    : _i18n.translate("CONTINUE"),
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
                final requiredRemaining = _requiredRemaining(userModel);
                final mediaCompleted =
                    (userModel.user.userProfilePhoto.trim().isNotEmpty
                        ? 1
                        : 0) +
                    ((_galleryCount(userModel) > 0) ? 1 : 0);
                final personalCompleted =
                    ((_fullnameController?.text.trim().isNotEmpty ?? false)
                        ? 1
                        : 0) +
                    ((_selectedBirthDate != null) ? 1 : 0) +
                    (_bioController.text.trim().isNotEmpty ? 1 : 0) +
                    (_demographicsController.text.trim().isNotEmpty ? 1 : 0) +
                    ((_selectedEducation ?? '').isNotEmpty ? 1 : 0) +
                    ((_selectedReligion ?? '').isNotEmpty ? 1 : 0);
                final preferencesCompleted =
                    (_hobbies.isNotEmpty ? 1 : 0) +
                    (_pets.isNotEmpty ? 1 : 0) +
                    (_languages.isNotEmpty ? 1 : 0) +
                    (_dealBreakers.isNotEmpty ? 1 : 0) +
                    (_lifestyleTags.isNotEmpty ? 1 : 0) +
                    (_relationshipType.isNotEmpty ? 1 : 0) +
                    (_familyPlanning.isNotEmpty ? 1 : 0) +
                    (_preferredMaxDistance > 0 ? 1 : 0) +
                    (_preferredMinAge >= 18 ? 1 : 0) +
                    (_preferredMaxAge >= _preferredMinAge ? 1 : 0);
                final mediaProgress = _sectionProgress(
                  completed: mediaCompleted,
                  total: 2,
                );
                final personalProgress = _sectionProgress(
                  completed: personalCompleted,
                  total: 6,
                );
                final preferencesProgress = _sectionProgress(
                  completed: preferencesCompleted,
                  total: 10,
                );
                final overallProgress = _sectionProgress(
                  completed:
                      mediaCompleted + personalCompleted + preferencesCompleted,
                  total: 18,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Complete your profile to get better matches',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: requiredRemaining == 0
                                      ? Colors.green.withOpacity(0.12)
                                      : Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  requiredRemaining == 0
                                      ? 'All required done'
                                      : '$requiredRemaining required left',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: requiredRemaining == 0
                                        ? Colors.green[700]
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: overallProgress,
                              valueColor: AlwaysStoppedAnimation(
                                Theme.of(context).primaryColor,
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.13),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(overallProgress * 100).round()}% complete',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildSectionProgressPill(
                                title: 'Media',
                                progress: mediaProgress,
                              ),
                              const SizedBox(width: 8),
                              _buildSectionProgressPill(
                                title: 'Personal',
                                progress: personalProgress,
                              ),
                              const SizedBox(width: 8),
                              _buildSectionProgressPill(
                                title: 'Preferences',
                                progress: preferencesProgress,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _savedStatusText(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _hasUnsavedChanges
                                  ? Colors.orange[800]
                                  : Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildChecklistRow(
                            title: 'Add a profile photo',
                            done: userModel.user.userProfilePhoto
                                .trim()
                                .isNotEmpty,
                          ),
                          _buildChecklistRow(
                            title: 'Write your bio',
                            done: _bioController.text.trim().isNotEmpty,
                          ),
                          _buildChecklistRow(
                            title: 'Add at least one hobby',
                            done: _hobbies.isNotEmpty,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Profile photo section
                    _buildSectionContainer(
                      title: 'Media',
                      subtitle: 'Photos and gallery',
                      expanded: _showMediaSection,
                      onToggle: () {
                        setState(() {
                          _showMediaSection = !_showMediaSection;
                        });
                      },
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

                          const SizedBox(height: 16),
                          _buildVisibilityRow(
                            label: 'Profile photo visibility',
                            value: _profilePhotoVisibility,
                            onChanged: (value) {
                              setState(() {
                                _profilePhotoVisibility = value;
                                _hasUnsavedChanges = true;
                              });
                            },
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
                          const SizedBox(height: 12),
                          _buildVisibilityRow(
                            label: 'Gallery visibility',
                            value: _galleryVisibility,
                            onChanged: (value) {
                              setState(() {
                                _galleryVisibility = value;
                                _hasUnsavedChanges = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Form fields section
                    _buildSectionContainer(
                      title: 'Personal information',
                      subtitle: 'Identity and profile details',
                      expanded: _showPersonalSection,
                      onToggle: () {
                        setState(() {
                          _showPersonalSection = !_showPersonalSection;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),

                          /// Full Name field
                          TextFormField(
                            controller: _fullnameController,
                            decoration: InputDecoration(
                              labelText: _i18n.translate("fullname"),
                              hintText: _i18n.translate("enter_your_fullname"),
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
                                  "assets/icons/user_icon.svg",
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
                            validator: (name) {
                              if (name == null || name.trim().isEmpty) {
                                return _i18n.translate(
                                  "please_enter_your_fullname",
                                );
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          /// Date of Birth field
                          GestureDetector(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedBirthDate,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null &&
                                  picked != _selectedBirthDate) {
                                setState(() {
                                  _selectedBirthDate = picked;
                                  _hasUnsavedChanges = true;
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: TextEditingController(
                                  text: _selectedBirthDate != null
                                      ? "${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}"
                                      : _i18n.translate("select_date_of_birth"),
                                ),
                                decoration: InputDecoration(
                                  labelText: _i18n.translate("birthday"),
                                  hintText: _i18n.translate(
                                    "select_your_birthday",
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
                                    child: Icon(
                                      Icons.calendar_today,
                                      color: Theme.of(context).primaryColor,
                                      size: 18,
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
                              ),
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
                                margin: const EdgeInsets.all(6.0),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: SvgIcon(
                                  "assets/icons/university_icon.svg",
                                  color: Theme.of(context).primaryColor,
                                  width: 12,
                                  height: 12,
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
                            onChanged: (value) => setState(() {
                              _selectedEducation = value;
                              _hasUnsavedChanges = true;
                            }),
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
                            onChanged: (value) => setState(() {
                              _selectedReligion = value;
                              _hasUnsavedChanges = true;
                            }),
                          ),

                          const SizedBox(height: 14),
                          _buildVisibilityRow(
                            label: 'Identity visibility',
                            value: _identityVisibility,
                            onChanged: (value) {
                              setState(() {
                                _identityVisibility = value;
                                _hasUnsavedChanges = true;
                              });
                            },
                          ),

                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Height (cm)',
                                    hintText: 'e.g. 175',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Weight (kg)',
                                    hintText: 'e.g. 70',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _smokingHabit,
                            decoration: InputDecoration(
                              labelText: 'Smoking',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                            ),
                            items: _habitOptions
                                .map(
                                  (option) => DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _smokingHabit = value;
                                _hasUnsavedChanges = true;
                              });
                            },
                          ),

                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _alcoholHabit,
                            decoration: InputDecoration(
                              labelText: 'Alcohol',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                            ),
                            items: _habitOptions
                                .map(
                                  (option) => DropdownMenuItem<String>(
                                    value: option,
                                    child: Text(option),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _alcoholHabit = value;
                                _hasUnsavedChanges = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Interests section
                    _buildSectionContainer(
                      title: 'Interests and preferences',
                      subtitle: 'Lifestyle and matching context',
                      expanded: _showPreferencesSection,
                      onToggle: () {
                        setState(() {
                          _showPreferencesSection = !_showPreferencesSection;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add what you like so matches feel more personal.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.75),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildPreferenceEditorSection(
                            title: 'Interests',
                            icon: Icons.sports_soccer,
                            controller: _hobbyController,
                            selectedItems: _hobbies,
                            hintText: 'Add an interest',
                          ),

                          const SizedBox(height: 20),

                          _buildPreferenceEditorSection(
                            title: _i18n.translate('pets'),
                            icon: Icons.pets,
                            controller: _petController,
                            selectedItems: _pets,
                            hintText: _i18n.translate('app_pet'),
                          ),

                          const SizedBox(height: 20),

                          _buildPreferenceEditorSection(
                            title: _i18n.translate('languages'),
                            icon: Icons.language,
                            controller: _languagesController,
                            selectedItems: _languages,
                            hintText: _i18n.translate('add_language'),
                          ),

                          const SizedBox(height: 20),

                          _buildPreferenceEditorSection(
                            title: 'Deal-breakers',
                            icon: Icons.block,
                            controller: _dealBreakersController,
                            selectedItems: _dealBreakers,
                            hintText: 'Add a deal-breaker',
                          ),

                          const SizedBox(height: 20),

                          _buildPreferenceEditorSection(
                            title: 'Lifestyle',
                            icon: Icons.self_improvement,
                            controller: _lifestyleController,
                            selectedItems: _lifestyleTags,
                            hintText: 'Add a lifestyle trait',
                          ),

                          const SizedBox(height: 24),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.family_restroom,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Family',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Share your family intentions and readiness.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.75),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Do you have children?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [true, false]
                                      .map(
                                        (hasChildren) => ChoiceChip(
                                          label: Text(
                                            hasChildren ? 'Yes' : 'No',
                                          ),
                                          selected: _hasChildren == hasChildren,
                                          showCheckmark: true,
                                          selectedColor: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.95),
                                          backgroundColor: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.78),
                                          checkmarkColor: Colors.white,
                                          side: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.35),
                                          ),
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          onSelected: (_) {
                                            setState(() {
                                              _hasChildren = hasChildren;
                                              _hasUnsavedChanges = true;
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                                if (_hasChildren) ...[
                                  Row(
                                    children: [
                                      const Text(
                                        'How many children?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _childrenCount.round().toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    min: 0,
                                    max: 10,
                                    divisions: 10,
                                    activeColor: Theme.of(context).primaryColor,
                                    inactiveColor: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.25),
                                    value: _childrenCount,
                                    onChanged: (value) {
                                      setState(() {
                                        _childrenCount = value;
                                        _hasUnsavedChanges = true;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                ] else ...[
                                  const Text(
                                    'Would you like to have children?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [true, false]
                                        .map(
                                          (wantsChildren) => ChoiceChip(
                                            label: Text(
                                              wantsChildren ? 'Yes' : 'No',
                                            ),
                                            selected:
                                                _wantsChildren == wantsChildren,
                                            showCheckmark: true,
                                            selectedColor: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.95),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.78),
                                            checkmarkColor: Colors.white,
                                            side: BorderSide(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor.withOpacity(0.35),
                                            ),
                                            labelStyle: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            onSelected: (_) {
                                              setState(() {
                                                _wantsChildren = wantsChildren;
                                                _hasUnsavedChanges = true;
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  if (_wantsChildren) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Text(
                                          'How many would you like?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _desiredChildrenCount
                                              .round()
                                              .toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(
                                              context,
                                            ).primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Slider(
                                      min: 0,
                                      max: 10,
                                      divisions: 10,
                                      activeColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                      inactiveColor: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.25),
                                      value: _desiredChildrenCount,
                                      onChanged: (value) {
                                        setState(() {
                                          _desiredChildrenCount = value;
                                          _hasUnsavedChanges = true;
                                        });
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                ],

                                const Text(
                                  'Are you ready to build a family?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _familyPlanningOptions
                                      .map(
                                        (option) => ChoiceChip(
                                          label: Text(option),
                                          selected: _familyPlanning == option,
                                          showCheckmark: true,
                                          selectedColor: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.95),
                                          backgroundColor: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.78),
                                          checkmarkColor: Colors.white,
                                          side: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.35),
                                          ),
                                          labelStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          onSelected: (_) {
                                            setState(() {
                                              _familyPlanning = option;
                                              _hasUnsavedChanges = true;
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 14),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  activeColor: Theme.of(context).primaryColor,
                                  title: const Text(
                                    'Financially ready for family life',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  value: _financialReadiness,
                                  onChanged: (value) {
                                    setState(() {
                                      _financialReadiness = value;
                                      _hasUnsavedChanges = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Advanced preferences',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Fine-tune distance, relationship type and age range.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.75),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _relationshipType,
                                  decoration: InputDecoration(
                                    labelText: 'Relationship type',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                  ),
                                  items: _relationshipTypes
                                      .map(
                                        (type) => DropdownMenuItem<String>(
                                          value: type,
                                          child: Text(type),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _relationshipType = value;
                                      _hasUnsavedChanges = true;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Text(
                                      'Maximum distance',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_preferredMaxDistance.round()} km',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  min: 1,
                                  max: 500,
                                  divisions: 499,
                                  activeColor: Theme.of(context).primaryColor,
                                  inactiveColor: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.25),
                                  value: _preferredMaxDistance,
                                  onChanged: (value) {
                                    setState(() {
                                      _preferredMaxDistance = value;
                                      _hasUnsavedChanges = true;
                                    });
                                  },
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      'Preferred age range',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_preferredMinAge.round()} - ${_preferredMaxAge.round()}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                RangeSlider(
                                  min: 18,
                                  max: 100,
                                  divisions: 82,
                                  activeColor: Theme.of(context).primaryColor,
                                  inactiveColor: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.25),
                                  values: RangeValues(
                                    _preferredMinAge,
                                    _preferredMaxAge,
                                  ),
                                  onChanged: (values) {
                                    setState(() {
                                      _preferredMinAge = values.start;
                                      _preferredMaxAge = values.end;
                                      _hasUnsavedChanges = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),
                          _buildVisibilityRow(
                            label: 'Interests visibility',
                            value: _interestsVisibility,
                            onChanged: (value) {
                              setState(() {
                                _interestsVisibility = value;
                                _hasUnsavedChanges = true;
                              });
                            },
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

  Widget _buildPreferenceEditorSection({
    required String title,
    required IconData icon,
    required TextEditingController controller,
    required List<String> selectedItems,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor.withOpacity(0.45),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor.withOpacity(0.45),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                onSubmitted: (value) =>
                    _addToList(value, selectedItems, controller),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextButton(
                onPressed: () =>
                    _addToList(controller.text, selectedItems, controller),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (selectedItems.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedItems
                .map(
                  (item) => Chip(
                    label: Text(
                      item,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                    deleteIconColor: Colors.white,
                    onDeleted: () => _removeFromList(item, selectedItems),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required String subtitle,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
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
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[const SizedBox(height: 14), child],
        ],
      ),
    );
  }

  Widget _buildSectionProgressPill({
    required String title,
    required double progress,
  }) {
    final percent = (progress * 100).round();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).primaryColor,
                ),
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.18),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistRow({required String title, required bool done}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 17,
            color: done ? Colors.green[700] : Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityRow({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              selectedItemBuilder: (context) {
                return _visibilityOptions
                    .map(
                      (option) => Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          option,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList();
              },
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: primary,
              ),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(10),
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              items: _visibilityOptions
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (selected) {
                if (selected == null) return;
                onChanged(selected);
              },
            ),
          ),
        ],
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
      // Update User Full Name and Birthday
      userFullName: _fullnameController?.text.trim() ?? '',
      userBirthDay: _selectedBirthDate?.day ?? 0,
      userBirthMonth: _selectedBirthDate?.month ?? 0,
      userBirthYear: _selectedBirthDate?.year ?? 0,
      educationLevel: _selectedEducation ?? '',
      religion: _selectedReligion ?? '',
      pets: _pets,
      hobbies: _hobbies,
      languages: _languages,
      demographics: _demographicsController.text.trim(),
      familyPlanning: _familyPlanning,
      financialReadiness: _financialReadiness,
      desiredChildrenCount: _wantsChildren ? _desiredChildrenCount.round() : 0,
      heightCm: _parsePositiveInt(_heightController.text),
      weightKg: _parsePositiveInt(_weightController.text),
      hasChildren: _hasChildren,
      childrenCount: _hasChildren ? _childrenCount.round() : 0,
      wantsChildren: _hasChildren ? false : _wantsChildren,
      smokingHabit: _smokingHabit,
      alcoholHabit: _alcoholHabit,
      profilePhotoVisibility: _profilePhotoVisibility,
      galleryVisibility: _galleryVisibility,
      identityVisibility: _identityVisibility,
      interestsVisibility: _interestsVisibility,
      profilePreferences: {
        'deal_breakers': _dealBreakers,
        'lifestyle_tags': _lifestyleTags,
        'relationship_type': _relationshipType,
      },
      maxDistance: _preferredMaxDistance,
      minPreferredAge: _preferredMinAge.round(),
      maxPreferredAge: _preferredMaxAge.round(),
      onSuccess: () {
        if (mounted) {
          setState(() {
            _hasUnsavedChanges = false;
            _lastSavedAt = DateTime.now();
          });
        }

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
