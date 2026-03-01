import 'package:cheers/api/dislikes_api.dart';
import 'package:cheers/api/likes_api.dart';
import 'package:cheers/api/matches_api.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/datas/user.dart';
import 'package:cheers/dialogs/its_match_dialog.dart';
import 'package:cheers/dialogs/report_dialog.dart';
import 'package:cheers/helpers/app_helper.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/widgets/show_scaffold_msg.dart';

import 'package:flutter/material.dart';
import 'dart:ui'; // For ImageFilter
import 'package:scoped_model/scoped_model.dart';
import 'package:timeago/timeago.dart' as timeago;

// ignore: must_be_immutable
class ProfileScreen extends StatefulWidget {
  /// Params
  final User user;
  final bool showButtons;
  final bool hideDislikeButton;
  final bool fromDislikesScreen;
  final bool respectVisibilitySettings;
  final bool isPreviewMode;

  // Constructor
  const ProfileScreen({
    super.key,
    required this.user,
    this.showButtons = true,
    this.hideDislikeButton = false,
    this.fromDislikesScreen = false,
    this.respectVisibilitySettings = false,
    this.isPreviewMode = false,
  });

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  /// Local variables
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppHelper _appHelper = AppHelper();
  final LikesApi _likesApi = LikesApi();
  final DislikesApi _dislikesApi = DislikesApi();
  final MatchesApi _matchesApi = MatchesApi();
  late AppLocalizations _i18n;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  bool _isVisibleSetting(String settingKey) {
    if (!widget.respectVisibilitySettings) return true;
    final settings = widget.user.userSettings ?? {};
    final visibility = (settings[settingKey] ?? 'Visible').toString();
    return visibility == 'Visible';
  }

  bool get _showProfilePhoto =>
      _isVisibleSetting(USER_VISIBILITY_PROFILE_PHOTO);
  bool get _showGallery => _isVisibleSetting(USER_VISIBILITY_GALLERY);
  bool get _showIdentity => _isVisibleSetting(USER_VISIBILITY_IDENTITY);
  bool get _showInterests => _isVisibleSetting(USER_VISIBILITY_INTERESTS);

  bool get _showBio {
    if (!widget.respectVisibilitySettings) return true;
    return (widget.user.hideProfile ?? true) && _showIdentity;
  }

  String _previewName(int userAge) {
    if (_showIdentity) {
      return "${widget.user.userFullname}, $userAge";
    }
    return 'Private profile';
  }

  @override
  void initState() {
    super.initState();
    // Note: before make sure to add your Interstial AD ID
    // AppAdHelper().showInterstitialAd();
  }

  @override
  void dispose() {
    _pageController.dispose();
    // AppAdHelper().disposeInterstitialAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);

    // Get User Birthday & Age
    final DateTime userBirthday = DateTime(
      widget.user.userBirthYear,
      widget.user.userBirthMonth,
      widget.user.userBirthDay,
    );
    final int userAge = UserModel().calculateUserAge(userBirthday);

    if (widget.isPreviewMode) {
      return _buildPreviewScaffold(userAge);
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F5FF),
      body: ScopedModelDescendant<UserModel>(
        builder: (context, child, userModel) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Parallax Header
              SliverAppBar(
                expandedHeight: 450.0,
                pinned: true,
                backgroundColor: Theme.of(context).primaryColor,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                actions: [
                  if (UserModel().user.userId != widget.user.userId)
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.flag_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () =>
                            ReportDialog(userId: widget.user.userId).show(),
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Main Photo
                      _showProfilePhoto
                          ? Builder(
                              builder: (context) {
                                final images = UserModel().getUserProfileImages(
                                  widget.user,
                                );
                                final imageUrl = images.isEmpty
                                    ? widget.user.userProfilePhoto
                                    : images[_currentImageIndex];
                                return Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Container(
                              color: const Color(0xFFE7E1F5),
                              child: const Center(
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 72,
                                  color: Color(0xFF7B6E9B),
                                ),
                              ),
                            ),
                      // Gradient Overlay for better text readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.2),
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      // Thumbnails on the right side
                      Positioned(
                        top: 100,
                        right: 12,
                        child: Builder(
                          builder: (context) {
                            if (!_showProfilePhoto || !_showGallery) {
                              return const SizedBox.shrink();
                            }
                            final images = UserModel().getUserProfileImages(
                              widget.user,
                            );
                            if (images.length <= 1) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              children: List.generate(
                                images.length > 4 ? 4 : images.length,
                                (index) => GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                  },
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _currentImageIndex == index
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.5),
                                        width: _currentImageIndex == index
                                            ? 3
                                            : 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        images[index],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Name & Age on Image
                      Positioned(
                        bottom: 40,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _previewName(userAge),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.user.userIsVerified)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Glassmorphism Badges Row
                            Row(
                              children: [
                                _glassBadge(
                                  icon: Icons.location_on,
                                  text:
                                      "${_appHelper.getDistanceBetweenUsers(userLat: widget.user.userGeoPoint.latitude, userLong: widget.user.userGeoPoint.longitude)}km",
                                ),
                                if (UserModel().user.userId ==
                                        widget.user.userId &&
                                    UserModel().userIsVip) ...[
                                  const SizedBox(width: 8),
                                  _glassBadge(
                                    icon: Icons.star,
                                    text: "VIP Member",
                                    color: Colors.amber,
                                  ),
                                ],
                              ],
                            ),
                            // Bio under name
                            if (_showBio && widget.user.userBio.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                widget.user.userBio,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 8,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Profile Content
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -20, 0),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Color(0xFFF8F5FF),
                        Color(0xFFF0E6FF),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (widget.isPreviewMode) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE7F6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Preview with visibility rules',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5E35B1),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Details Section Card
                        if (_showIdentity)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFEDE7F6), Color(0xFFE1BEE7)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.person_outline,
                                        color: Colors.indigo,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "Details",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    if (widget.user.education.isNotEmpty)
                                      _detailChip(
                                        icon: Icons.school,
                                        label: widget.user.education,
                                        color: Colors.indigo,
                                      ),
                                    if (widget.user.religion.isNotEmpty)
                                      _detailChip(
                                        icon: Icons.temple_buddhist,
                                        label: widget.user.religion,
                                        color: Colors.purple,
                                      ),
                                  ],
                                ),
                                ...[
                                  const SizedBox(height: 12),
                                  _infoRow(
                                    icon: Icons.calendar_today,
                                    label:
                                        "Joined ${timeago.format(widget.user.userRegDate)}",
                                  ),
                                ],
                              ],
                            ),
                          ),
                        if (_showIdentity) const SizedBox(height: 16),

                        // Hobbies Section Card
                        if (_showInterests &&
                            widget.user.hobbies.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF7E57C2,
                                        ).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.favorite_border,
                                        color: Color(0xFF7E57C2),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _i18n.translate("hobbies"),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: widget.user.hobbies.map((hobby) {
                                    return _detailChip(
                                      icon: Icons.favorite_border,
                                      label: hobby,
                                      color: const Color(0xFF7E57C2),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Pets Section Card
                        if (_showInterests && widget.user.pets.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFEDE7F6), Color(0xFFCE93D8)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFAB47BC,
                                        ).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.pets,
                                        color: Color(0xFFAB47BC),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "Pets",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: widget.user.pets.map((pet) {
                                    return _detailChip(
                                      icon: Icons.pets,
                                      label: pet,
                                      color: const Color(0xFFAB47BC),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Languages Section Card
                        if (_showInterests &&
                            widget.user.languages.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFEDE7F6), Color(0xFFB39DDB)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF5E35B1,
                                        ).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.language,
                                        color: Color(0xFF5E35B1),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "Languages",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: widget.user.languages.map((
                                    language,
                                  ) {
                                    return _detailChip(
                                      icon: Icons.language,
                                      label: language,
                                      color: const Color(0xFF5E35B1),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_showIdentity &&
                            (widget.user.demographics?.trim().isNotEmpty ==
                                    true ||
                                widget.user.heightCm != null ||
                                widget.user.weightKg != null ||
                                widget.user.familyPlanning?.trim().isNotEmpty ==
                                    true ||
                                widget.user.smokingHabit?.trim().isNotEmpty ==
                                    true ||
                                widget.user.alcoholHabit?.trim().isNotEmpty ==
                                    true ||
                                (widget.user.preferences?['relationship_type']
                                        ?.toString()
                                        .trim()
                                        .isNotEmpty ??
                                    false))) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF5E35B1,
                                        ).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.tune,
                                        color: Color(0xFF5E35B1),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Lifestyle & Family',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if ((widget.user.demographics
                                            ?.trim()
                                            .isNotEmpty ??
                                        false))
                                      _detailChip(
                                        icon: Icons.diversity_3,
                                        label: widget.user.demographics!.trim(),
                                        color: const Color(0xFF5E35B1),
                                      ),
                                    if (widget.user.heightCm != null)
                                      _detailChip(
                                        icon: Icons.height,
                                        label: '${widget.user.heightCm} cm',
                                        color: const Color(0xFF5E35B1),
                                      ),
                                    if (widget.user.weightKg != null)
                                      _detailChip(
                                        icon: Icons.monitor_weight_outlined,
                                        label: '${widget.user.weightKg} kg',
                                        color: const Color(0xFF5E35B1),
                                      ),
                                    if ((widget
                                            .user
                                            .preferences?['relationship_type']
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ??
                                        false))
                                      _detailChip(
                                        icon: Icons.favorite_border,
                                        label: widget
                                            .user
                                            .preferences!['relationship_type']
                                            .toString(),
                                        color: const Color(0xFF5E35B1),
                                      ),
                                    if ((widget.user.familyPlanning
                                            ?.trim()
                                            .isNotEmpty ??
                                        false))
                                      _detailChip(
                                        icon: Icons.family_restroom,
                                        label: widget.user.familyPlanning!,
                                        color: const Color(0xFF5E35B1),
                                      ),
                                    if ((widget.user.smokingHabit
                                            ?.trim()
                                            .isNotEmpty ??
                                        false))
                                      _detailChip(
                                        icon: Icons.smoke_free,
                                        label:
                                            'Smoking: ${widget.user.smokingHabit}',
                                        color: const Color(0xFF5E35B1),
                                      ),
                                    if ((widget.user.alcoholHabit
                                            ?.trim()
                                            .isNotEmpty ??
                                        false))
                                      _detailChip(
                                        icon: Icons.local_bar_outlined,
                                        label:
                                            'Alcohol: ${widget.user.alcoholHabit}',
                                        color: const Color(0xFF5E35B1),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        if (_showProfilePhoto && _showGallery) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Gallery',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildGalleryGrid(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Bottom Spacing
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: widget.showButtons
          ? _buildFloatingButtons(context)
          : null,
    );
  }

  Widget _glassBadge({
    required IconData icon,
    required String text,
    Color color = Colors.white,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9), // Slightly darker for text
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    if (!_showProfilePhoto || !_showGallery) return const SizedBox.shrink();
    final images = UserModel().getUserProfileImages(widget.user);
    if (images.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        // Skip first image as it is used in header
        // Actually, users might want to see it here too, or we can use all images.
        // Let's show all images for completeness
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () {
              // TODO: Open full screen viewer
            },
            child: Image.network(images[index], fit: BoxFit.cover),
          ),
        );
      },
    );
  }

  Scaffold _buildPreviewScaffold(int userAge) {
    final firstName = widget.user.userFullname.trim().isEmpty
        ? 'Private'
        : widget.user.userFullname.trim().split(' ').first;
    final previewTitle = _showIdentity
        ? '$firstName, $userAge'
        : 'Private profile';
    final previewImages = _showProfilePhoto
        ? UserModel()
              .getUserProfileImages(widget.user)
              .where((image) => image.trim().isNotEmpty)
              .toList()
        : <String>[];
    final relationshipType =
        widget.user.preferences?['relationship_type']?.toString().trim() ?? '';
    final familyPlanning = widget.user.familyPlanning?.trim() ?? '';
    final hasChildren = widget.user.hasChildren;
    final childrenCount = widget.user.childrenCount;
    final wantsChildren = widget.user.wantsChildren;
    final desiredChildrenCount = widget.user.desiredChildrenCount;
    final userSettings = widget.user.userSettings ?? {};

    int? parseSettingInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value);
      return null;
    }

    final interestedMinAge = parseSettingInt(userSettings[USER_MIN_AGE]);
    final interestedMaxAge = parseSettingInt(userSettings[USER_MAX_AGE]);
    final hasInterestedAgeRange =
        interestedMinAge != null && interestedMaxAge != null;
    final currentLocation = [
      widget.user.userCountry.trim(),
      widget.user.userLocality.trim(),
    ].where((part) => part.isNotEmpty).join(', ');

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF3EFFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3EFFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2F2440)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile preview',
          style: TextStyle(
            color: Color(0xFF2F2440),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      previewTitle,
                      style: const TextStyle(
                        fontSize: 36 / 1.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B223A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A4BC1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Active now',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.user.userIsVerified) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF7A4BC1),
                      size: 20,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE4DDF1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 420,
                          child: _showProfilePhoto && previewImages.isNotEmpty
                              ? PageView.builder(
                                  controller: _pageController,
                                  itemCount: previewImages.length,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    return Image.network(
                                      previewImages[index],
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Container(
                                  color: const Color(0xFFE7E1F5),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.lock_outline,
                                    size: 60,
                                    color: Color(0xFF7B6E9B),
                                  ),
                                ),
                        ),
                      ),
                      if (_showProfilePhoto && previewImages.length > 1) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(previewImages.length, (
                            index,
                          ) {
                            final isSelected = _currentImageIndex == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isSelected ? 16 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF7A4BC1)
                                    : const Color(0xFFD9CCE9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_showBio && widget.user.userBio.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _previewSection(
                  title: 'About',
                  child: Text(
                    widget.user.userBio,
                    style: const TextStyle(
                      fontSize: 20 / 1.3,
                      height: 1.45,
                      color: Color(0xFF3A2F4D),
                    ),
                  ),
                ),
              ],
              if (_showInterests && widget.user.hobbies.isNotEmpty) ...[
                const SizedBox(height: 12),
                _previewSection(
                  title: 'Interests',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.user.hobbies
                        .map(
                          (hobby) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE8E1F4),
                              ),
                            ),
                            child: Text(
                              hobby,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF3A2F4D),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
              if (_showIdentity) ...[
                const SizedBox(height: 12),
                _previewSection(
                  title: "The one thing I'd love to know about you is",
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _previewInfoPill(Icons.cake_outlined, '$userAge'),
                          const SizedBox(width: 10),
                          _previewInfoPill(
                            Icons.person_outline,
                            widget.user.userGender,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (widget.user.education.isNotEmpty)
                        _previewLine(
                          Icons.school_outlined,
                          widget.user.education,
                        ),
                      if (currentLocation.isNotEmpty)
                        _previewLine(
                          Icons.location_on_outlined,
                          'Current location: $currentLocation',
                        ),
                      if (hasInterestedAgeRange)
                        _previewLine(
                          Icons.calendar_today_outlined,
                          'Age range interested: $interestedMinAge - $interestedMaxAge',
                        ),
                      if (relationshipType.isNotEmpty)
                        _previewLine(Icons.favorite_border, relationshipType),
                      if (familyPlanning.isNotEmpty)
                        _previewLine(Icons.family_restroom, familyPlanning),
                      if (hasChildren != null)
                        _previewLine(
                          Icons.child_care,
                          'Has children: ${hasChildren ? 'Yes' : 'No'}',
                        ),
                      if (hasChildren == true && childrenCount != null)
                        _previewLine(
                          Icons.numbers,
                          'Children count: $childrenCount',
                        ),
                      if (hasChildren == false && wantsChildren != null)
                        _previewLine(
                          Icons.favorite_outline,
                          'Wants children: ${wantsChildren ? 'Yes' : 'No'}',
                        ),
                      if (hasChildren == false &&
                          wantsChildren == true &&
                          desiredChildrenCount != null)
                        _previewLine(
                          Icons.family_restroom,
                          'Desired children: $desiredChildrenCount',
                        ),
                      if (_showInterests && widget.user.pets.isNotEmpty)
                        _previewLine(Icons.pets, widget.user.pets.join(', ')),
                      if (_showInterests && widget.user.languages.isNotEmpty)
                        _previewLine(
                          Icons.language,
                          widget.user.languages.join(', '),
                        ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: widget.showButtons ? 110 : 0),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          widget.showButtons && UserModel().user.userId != widget.user.userId
          ? _buildFloatingButtons(context)
          : null,
    );
  }

  Widget _previewSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4DDF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B223A),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _previewInfoPill(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF7A4BC1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF7A4BC1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewLine(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5B2D88)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 20 / 1.3,
                color: Color(0xFF3A2F4D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Dislike
          if (!widget.hideDislikeButton)
            _actionButton(
              context,
              icon: Icons.close,
              color: Colors.white,
              backgroundColor: Colors.white,
              iconColor: Colors.redAccent,
              onTap: () {
                _dislikesApi.dislikeUser(
                  dislikedUserId: widget.user.userId,
                  onDislikeResult: (result) {
                    if (!result) {
                      showScaffoldMessage(
                        context: context,
                        message: _i18n.translate(
                          "you_already_disliked_this_profile",
                        ),
                      );
                    } else if (widget.isPreviewMode && mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),

          // Like
          _actionButton(
            context,
            icon: Icons.favorite,
            color: Theme.of(context).primaryColor,
            backgroundColor: Theme.of(context).primaryColor,
            iconColor: Colors.white,
            isLarge: true,
            onTap: () => _likeUser(context),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            width: isLarge ? 80 : 60,
            height: isLarge ? 80 : 60,
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: isLarge ? 32 : 28),
          ),
        ),
      ),
    );
  }

  /// Like user function
  Future<void> _likeUser(BuildContext context) async {
    /// Check match first
    _matchesApi
        .checkMatch(
          userId: widget.user.userId,
          onMatchResult: (result) {
            if (result) {
              /// Show It`s match dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return ItsMatchDialog(
                    matchedUser: widget.user,
                    showSwipeButton: false,
                    swipeKey: null,
                  );
                },
              );
            }
          },
        )
        .then((_) {
          /// Like user
          _likesApi.likeUser(
            likedUserId: widget.user.userId,
            userDeviceToken: widget.user.userDeviceToken,
            nMessage:
                "${UserModel().user.userFullname.split(' ')[0]}, "
                "${_i18n.translate("liked_your_profile_click_and_see")}",
            onLikeResult: (result) async {
              if (result) {
                // Show success message
                showScaffoldMessage(
                  context: context,
                  message:
                      '${_i18n.translate("like_sent_to")} ${widget.user.userFullname}',
                );
              } else if (!result) {
                // Show error message
                showScaffoldMessage(
                  context: context,
                  message: _i18n.translate("you_already_liked_this_profile"),
                );
              }
              /// Validate to delete disliked user from disliked list
              else if (result && widget.fromDislikesScreen) {
                // Delete in database
                await _dislikesApi.deleteDislikedUser(widget.user.userId);
              }
            },
          );
        });
  }
}
