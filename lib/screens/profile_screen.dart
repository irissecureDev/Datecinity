import 'package:cheers/api/dislikes_api.dart';
import 'package:cheers/api/likes_api.dart';
import 'package:cheers/api/matches_api.dart';
import 'package:cheers/datas/user.dart';
import 'package:cheers/dialogs/its_match_dialog.dart';
import 'package:cheers/dialogs/report_dialog.dart';
import 'package:cheers/helpers/app_helper.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/plugins/carousel_pro/carousel_pro.dart';
import 'package:cheers/widgets/cicle_button.dart';
import 'package:cheers/widgets/show_scaffold_msg.dart';
import 'package:cheers/widgets/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:timeago/timeago.dart' as timeago;

// ignore: must_be_immutable
class ProfileScreen extends StatefulWidget {
  /// Params
  final User user;
  final bool showButtons;
  final bool hideDislikeButton;
  final bool fromDislikesScreen;

  // Constructor
  const ProfileScreen({
    super.key,
    required this.user,
    this.showButtons = true,
    this.hideDislikeButton = false,
    this.fromDislikesScreen = false,
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

  @override
  void initState() {
    super.initState();
    // Note: before make sure to add your Interstial AD ID
    // AppAdHelper().showInterstitialAd();
  }

  @override
  void dispose() {
    // AppAdHelper().disposeInterstitialAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);
    //
    // Get User Birthday
    final DateTime userBirthday = DateTime(
      widget.user.userBirthYear,
      widget.user.userBirthMonth,
      widget.user.userBirthDay,
    );
    // Get User Current Age
    final int userAge = UserModel().calculateUserAge(userBirthday);

    return Scaffold(
      key: _scaffoldKey,
      body: ScopedModelDescendant<UserModel>(
        builder: (context, child, userModel) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 50),
                child: Column(
                  children: [
                    /// Carousel Profile images
                    AspectRatio(
                      aspectRatio: 1 / 1,
                      child: Carousel(
                        autoplay: false,
                        dotBgColor: Colors.transparent,
                        dotIncreasedColor: Theme.of(context).primaryColor,
                        images: UserModel()
                            .getUserProfileImages(widget.user)
                            .map((url) => NetworkImage(url))
                            .toList(),
                      ),
                    ),

                    /// Profile details - Modern Design
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Modern Header with Name and Badges
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.user.userFullname
                                            .split(' ')
                                            .map(
                                              (word) => word.isNotEmpty
                                                  ? word[0].toUpperCase() +
                                                        word
                                                            .substring(1)
                                                            .toLowerCase()
                                                  : word,
                                            )
                                            .join(' '),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${userAge.toString()} years',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF718096),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    /// Distance Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).primaryColor,
                                            Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SvgIcon(
                                            "assets/icons/location_point_icon.svg",
                                            color: Colors.white,
                                            width: 12,
                                            height: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_appHelper.getDistanceBetweenUsers(userLat: widget.user.userGeoPoint.latitude, userLong: widget.user.userGeoPoint.longitude)}km',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    /// Verified badge
                                    if (widget.user.userIsVerified)
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Image.asset(
                                          'assets/images/verified_badge.png',
                                          width: 20,
                                          height: 20,
                                        ),
                                      ),
                                    const SizedBox(width: 8),

                                    /// VIP badge
                                    if (UserModel().user.userId ==
                                            widget.user.userId &&
                                        UserModel().userIsVip)
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Image.asset(
                                          'assets/images/crow_badge.png',
                                          width: 20,
                                          height: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            /// Quick Info Cards
                            Row(
                              children: [
                                Expanded(
                                  child: _modernInfoCard(
                                    context,
                                    icon: const SvgIcon(
                                      "assets/icons/location_point_icon.svg",
                                      width: 20,
                                      height: 20,
                                    ),
                                    title: "Localisation",
                                    subtitle:
                                        "${widget.user.userLocality}, ${widget.user.userCountry}",
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _modernInfoCard(
                                    context,
                                    icon: const SvgIcon(
                                      "assets/icons/gift_icon.svg",
                                      width: 20,
                                      height: 20,
                                    ),
                                    title: "Anniversaire",
                                    subtitle:
                                        '${widget.user.userBirthDay}/${widget.user.userBirthMonth}/${widget.user.userBirthYear}',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: _modernInfoCard(
                                    context,
                                    icon: const SvgIcon(
                                      "assets/icons/info_icon.svg",
                                      width: 20,
                                      height: 20,
                                    ),
                                    title: "Membre depuis",
                                    subtitle: timeago.format(
                                      widget.user.userRegDate,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            /// Bio Section
                            if (widget.user.userBio.isNotEmpty) ...[
                              _modernSectionHeader(context, "À propos"),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  widget.user.userBio,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: Color(0xFF4A5568),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            /// Details Sections
                            if (widget.user.religion.isNotEmpty) ...[
                              _modernDetailSection(
                                context,
                                title: _i18n.translate("religion"),
                                content: widget.user.religion,
                                icon: const SvgIcon(
                                  "assets/icons/info_icon.svg",
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (widget.user.education.isNotEmpty) ...[
                              _modernDetailSection(
                                context,
                                title: _i18n.translate("education"),
                                content: widget.user.education,
                                icon: const SvgIcon(
                                  "assets/icons/university_icon.svg",
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (widget.user.languages.isNotEmpty) ...[
                              _modernDetailSection(
                                context,
                                title: _i18n.translate("languages"),
                                content: widget.user.languages.join(", "),
                                icon: const SvgIcon(
                                  "assets/icons/conversation_icon.svg",
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (widget.user.hobbies.isNotEmpty) ...[
                              _modernDetailSection(
                                context,
                                title: _i18n.translate("hobbies"),
                                content: widget.user.hobbies.join(", "),
                                icon: const SvgIcon(
                                  "assets/icons/game_icon.svg",
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (widget.user.pets.isNotEmpty) ...[
                              _modernDetailSection(
                                context,
                                title: _i18n.translate("pets"),
                                content: widget.user.pets.join(", "),
                                icon: const SvgIcon(
                                  "assets/icons/heart_icon.svg",
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            const SizedBox(
                              height: 80,
                            ), // Space for bottom buttons
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// AppBar to return back
              Positioned(
                top: 0.0,
                left: 0.0,
                right: 0.0,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(
                    color: Theme.of(context).primaryColor,
                  ),
                  actions: <Widget>[
                    // Check the current User ID
                    if (UserModel().user.userId != widget.user.userId)
                      IconButton(
                        icon: Icon(
                          Icons.flag,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                        // Report/Block profile dialog
                        onPressed: () =>
                            ReportDialog(userId: widget.user.userId).show(),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: widget.showButtons ? _buildButtons(context) : null,
    );
  }

  /// Modern info card widget
  Widget _modernInfoCard(
    BuildContext context, {
    required Widget icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: IconThemeData(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  child: icon,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4A5568),
            ),
          ),
        ],
      ),
    );
  }

  /// Modern section header
  Widget _modernSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2D3748),
      ),
    );
  }

  /// Modern detail section
  Widget _modernDetailSection(
    BuildContext context, {
    required String title,
    required String content,
    required Widget icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
              ),
              child: icon,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF4A5568),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build Like and Dislike buttons
  Widget _buildButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          /// Dislike profile button
          if (!widget.hideDislikeButton)
            cicleButton(
              padding: 8.0,
              icon: Icon(Icons.close, color: Theme.of(context).primaryColor),
              bgColor: Colors.grey,
              onTap: () {
                // Dislike profile
                _dislikesApi.dislikeUser(
                  dislikedUserId: widget.user.userId,
                  onDislikeResult: (result) {
                    /// Check result to show message
                    if (!result) {
                      // Show error message
                      showScaffoldMessage(
                        context: context,
                        message: _i18n.translate(
                          "you_already_disliked_this_profile",
                        ),
                      );
                    }
                  },
                );
              },
            ),

          /// Like profile button
          cicleButton(
            padding: 8.0,
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            bgColor: Theme.of(context).primaryColor,
            onTap: () {
              // Like user
              _likeUser(context);
            },
          ),
        ],
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
