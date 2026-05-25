import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datecinity/api/likes_api.dart';
import 'package:datecinity/api/visits_api.dart';
import 'package:datecinity/constants/constants.dart';
import 'package:datecinity/datas/user.dart';
import 'package:datecinity/dialogs/vip_dialog.dart';
import 'package:datecinity/helpers/app_helper.dart';
import 'package:datecinity/helpers/app_localizations.dart';
import 'package:datecinity/models/user_model.dart';
import 'package:datecinity/screens/profile_screen.dart';
import 'package:datecinity/widgets/build_title.dart';
import 'package:datecinity/widgets/loading_card.dart';
import 'package:datecinity/widgets/no_data.dart';
import 'package:datecinity/widgets/processing.dart';
import 'package:datecinity/widgets/profile_card.dart';
import 'package:datecinity/widgets/users_grid.dart';
import 'package:flutter/material.dart';

class ProfileLikesScreen extends StatefulWidget {
  const ProfileLikesScreen({super.key});

  @override
  ProfileLikesScreenState createState() => ProfileLikesScreenState();
}

class ProfileLikesScreenState extends State<ProfileLikesScreen> {
  // Variables
  final ScrollController _gridViewController = ScrollController();
  final LikesApi _likesApi = LikesApi();
  final VisitsApi _visitsApi = VisitsApi();
  late AppLocalizations _i18n;
  List<DocumentSnapshot<Map<String, dynamic>>>? _likedMeUsers;
  late DocumentSnapshot<Map<String, dynamic>> _userLastDoc;
  bool _loadMore = true;

  /// Load more users
  void _loadMoreUsersListener() async {
    _gridViewController.addListener(() {
      if (_gridViewController.position.pixels ==
          _gridViewController.position.maxScrollExtent) {
        /// Load more users
        if (_loadMore) {
          _likesApi
              .getLikedMeUsers(loadMore: true, userLastDoc: _userLastDoc)
              .then((users) {
                /// Update users list
                if (users.isNotEmpty) {
                  _updateUsersList(users);
                } else {
                  setState(() => _loadMore = false);
                }
                debugPrint('load more users: ${users.length}');
              });
        } else {
          debugPrint('No more users');
        }
      }
    });
  }

  /// Update list
  void _updateUsersList(List<DocumentSnapshot<Map<String, dynamic>>> users) {
    if (mounted) {
      setState(() {
        _likedMeUsers!.addAll(users);
        if (users.isNotEmpty) {
          _userLastDoc = users.last;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _likesApi.getLikedMeUsers().then((users) {
      // Check result
      if (users.isNotEmpty) {
        if (mounted) {
          setState(() {
            _likedMeUsers = users;
            _userLastDoc = users.last;
          });
        }
      } else {
        setState(() => _likedMeUsers = []);
      }
    });

    /// Listener
    _loadMoreUsersListener();
  }

  @override
  void dispose() {
    _gridViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);

    return Scaffold(
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
          _i18n.translate("likes"),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// Header Title
          BuildTitle(
            svgIconName: "heart_icon",
            title: _i18n.translate("users_who_liked_you"),
          ),

          /// Matches
          Expanded(child: _showProfiles()),
        ],
      ),
    );
  }

  /// Show profiles
  Widget _showProfiles() {
    if (_likedMeUsers == null) {
      return Processing(text: _i18n.translate("loading"));
    } else if (_likedMeUsers!.isEmpty) {
      // No data
      return NoData(svgName: 'heart_icon', text: _i18n.translate("no_like"));
    } else {
      /// Show users
      return UsersGrid(
        gridViewController: _gridViewController,
        itemCount: _likedMeUsers!.length + 1,

        /// Workaround for loading more
        itemBuilder: (context, index) {
          /// Validate fake index
          if (index < _likedMeUsers!.length) {
            /// Get user id
            final userId = _likedMeUsers![index][LIKED_BY_USER_ID];

            /// Load profile
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: UserModel().getUser(userId),
              builder: (context, snapshot) {
                /// Check result
                if (!snapshot.hasData) {
                  return const LoadingCard();
                } else if (snapshot.data?.data() == null) {
                  AppHelper()
                      .ambiguate(WidgetsBinding.instance)!
                      .addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _likedMeUsers!.removeAt(index);
                          });
                        }
                      });

                  return const LoadingCard();
                } else {
                  /// Get user object
                  final User user = User.fromDocument(snapshot.data!.data()!);

                  /// Show user card
                  return GestureDetector(
                    child: ProfileCard(user: user, page: 'require_vip'),
                    onTap: () {
                      /// Check vip account
                      if (UserModel().userIsVip) {
                        /// Go to profile screen - using showDialog to
                        /// prevents reloading getUser FutureBuilder
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return ProfileScreen(
                              user: user,
                              hideDislikeButton: true,
                            );
                          },
                        );

                        /// Increment user visits an push notification
                        _visitsApi.visitUserProfile(
                          visitedUserId: user.userId,
                          userDeviceToken: user.userDeviceToken,
                          nMessage:
                              "${UserModel().user.userFullname.split(' ')[0]}, "
                              "${_i18n.translate("visited_your_profile_click_and_see")}",
                        );
                      } else {
                        /// Show VIP dialog
                        showDialog(
                          context: context,
                          builder: (context) => const VipDialog(),
                        );
                      }
                    },
                  );
                }
              },
            );
          } else {
            return Container();
          }
        },
      );
    }
  }
}
