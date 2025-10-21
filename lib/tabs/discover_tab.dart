import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cheers/api/dislikes_api.dart';
import 'package:cheers/api/likes_api.dart';
import 'package:cheers/api/matches_api.dart';
import 'package:cheers/api/visits_api.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/datas/user.dart';
import 'package:cheers/dialogs/its_match_dialog.dart';
import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/plugins/swipe_stack/swipe_stack.dart';
import 'package:cheers/screens/disliked_profile_screen.dart';
import 'package:cheers/screens/profile_screen.dart';
import 'package:cheers/widgets/cicle_button.dart';
import 'package:cheers/widgets/no_data.dart';
import 'package:cheers/widgets/processing.dart';
import 'package:cheers/widgets/profile_card.dart';
import 'package:flutter/material.dart';
import 'package:cheers/api/users_api.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});

  @override
  DiscoverTabState createState() => DiscoverTabState();
}

class DiscoverTabState extends State<DiscoverTab> {
  // Variables
  final GlobalKey<SwipeStackState> _swipeKey = GlobalKey<SwipeStackState>();
  final LikesApi _likesApi = LikesApi();
  final DislikesApi _dislikesApi = DislikesApi();
  final MatchesApi _matchesApi = MatchesApi();
  final VisitsApi _visitsApi = VisitsApi();
  final UsersApi _usersApi = UsersApi();
  List<DocumentSnapshot<Map<String, dynamic>>>? _users;
  late AppLocalizations _i18n;

  /// Get all Users
  Future<void> _loadUsers(
    List<DocumentSnapshot<Map<String, dynamic>>> dislikedUsers,
  ) async {
    _usersApi.getUsers(dislikedUsers: dislikedUsers).then((users) {
      // Check result
      if (users.isNotEmpty) {
        if (mounted) {
          setState(() => _users = users);
        }
      } else {
        if (mounted) {
          setState(() => _users = []);
        }
      }
      // Debug
      debugPrint('getUsers() -> ${users.length}');
      debugPrint('getDislikedUsers() -> ${dislikedUsers.length}');
    });
  }

  @override
  void initState() {
    super.initState();

    /// First: Load All Disliked Users to be filtered
    _dislikesApi.getDislikedUsers(withLimit: false).then((
      List<DocumentSnapshot<Map<String, dynamic>>> dislikedUsers,
    ) async {
      /// Validate user max distance
      await UserModel().checkUserMaxDistance();

      /// Load all users
      await _loadUsers(dislikedUsers);
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);
    return _showUsers();
  }

  Widget _showUsers() {
    /// Check result
    if (_users == null) {
      return Processing(text: _i18n.translate("loading"));
    } else if (_users!.isEmpty) {
      /// No user found
      return NoData(
        svgName: 'search_icon',
        text: _i18n.translate(
          "no_user_found_around_you_please_try_again_later",
        ),
      );
    } else {
      return Stack(
        fit: StackFit.expand,
        children: [
          /// User card list
          SwipeStack(
            key: _swipeKey,
            children: _users!.map((userDoc) {
              // Get User object
              final User user = User.fromDocument(userDoc.data()!);
              // Return user profile
              return SwiperItem(
                builder: (SwiperPosition position, double progress) {
                  /// Return User Card
                  return ProfileCard(
                    page: 'discover',
                    position: position,
                    user: user,
                  );
                },
              );
            }).toList(),
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            translationInterval: 6,
            scaleInterval: 0.03,
            stackFrom: StackFrom.None,
            onEnd: () => debugPrint("onEnd"),
            onSwipe: (int index, SwiperPosition position) {
              /// Control swipe position
              switch (position) {
                case SwiperPosition.None:
                  break;
                case SwiperPosition.Left:

                  /// Swipe Left Dislike profile
                  _dislikesApi.dislikeUser(
                    dislikedUserId: _users![index][USER_ID],
                    onDislikeResult: (r) => debugPrint('onDislikeResult: $r'),
                  );

                  break;

                case SwiperPosition.Right:

                  /// Swipe right and Like profile
                  _likeUser(context, clickedUserDoc: _users![index]);

                  break;
              }
            },
          ),

          /// Swipe buttons
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: swipeButtons(context),
            ),
          ),
        ],
      );
    }
  }

  /// Build swipe buttons
  Widget swipeButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          /// Rewind profiles
          ///
          /// Go to Disliked Profiles
          Flexible(
            child: cicleButton(
              bgColor: Colors.white,
              padding: 8,
              icon: const Icon(Icons.restore, size: 22, color: Colors.grey),
              onTap: () {
                // Go to Disliked Profiles Screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DislikedProfilesScreen(),
                  ),
                );
              },
            ),
          ),

          /// Swipe left and reject user
          Flexible(
            child: cicleButton(
              bgColor: Colors.white,
              padding: 8,
              icon: const Icon(Icons.close, size: 35, color: Colors.grey),
              onTap: () {
                /// Get card current index
                final cardIndex = _swipeKey.currentState!.currentIndex;

                /// Check card valid index
                if (cardIndex != -1) {
                  /// Swipe left
                  _swipeKey.currentState!.swipeLeft();
                }
              },
            ),
          ),

          /// Swipe right and like user
          Flexible(
            child: cicleButton(
              bgColor: Colors.white,
              padding: 8,
              icon: Icon(
                Icons.favorite_border,
                size: 35,
                color: Theme.of(context).primaryColor,
              ),
              onTap: () async {
                /// Get card current index
                final cardIndex = _swipeKey.currentState!.currentIndex;

                /// Check card valid index
                if (cardIndex != -1) {
                  /// Swipe right
                  _swipeKey.currentState!.swipeRight();
                }
              },
            ),
          ),

          /// Go to user profile
          Flexible(
            child: cicleButton(
              bgColor: Colors.white,
              padding: 8,
              icon: const Icon(
                Icons.remove_red_eye,
                size: 22,
                color: Colors.grey,
              ),
              onTap: () {
                /// Get card current index
                final cardIndex = _swipeKey.currentState!.currentIndex;

                /// Check card valid index
                if (cardIndex != -1) {
                  /// Get User object
                  final User user = User.fromDocument(
                    _users![cardIndex].data()!,
                  );

                  /// Go to profile screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(user: user, showButtons: false),
                    ),
                  );

                  /// Increment user visits an push notification
                  _visitsApi.visitUserProfile(
                    visitedUserId: user.userId,
                    userDeviceToken: user.userDeviceToken,
                    nMessage:
                        "${UserModel().user.userFullname.split(' ')[0]}, "
                        "${_i18n.translate("visited_your_profile_click_and_see")}",
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Like user function
  Future<void> _likeUser(
    BuildContext context, {
    required DocumentSnapshot<Map<String, dynamic>> clickedUserDoc,
  }) async {
    /// Check match first
    await _matchesApi.checkMatch(
      userId: clickedUserDoc[USER_ID],
      onMatchResult: (result) {
        if (result) {
          /// It`s match - show dialog to ask user to chat or continue playing
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return ItsMatchDialog(
                swipeKey: _swipeKey,
                matchedUser: User.fromDocument(clickedUserDoc.data()!),
              );
            },
          );
        }
      },
    );

    /// like profile
    await _likesApi.likeUser(
      likedUserId: clickedUserDoc[USER_ID],
      userDeviceToken: clickedUserDoc[USER_DEVICE_TOKEN],
      nMessage:
          "${UserModel().user.userFullname.split(' ')[0]}, "
          "${_i18n.translate("liked_your_profile_click_and_see")}",
      onLikeResult: (result) {
        debugPrint('likeResult: $result');
      },
    );
  }
}
