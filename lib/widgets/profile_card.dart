import 'package:cheers/datas/user.dart';
import 'package:cheers/dialogs/report_dialog.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/plugins/swipe_stack/swipe_stack.dart';
import 'package:cheers/widgets/custom_badge.dart';
import 'package:cheers/widgets/default_card_border.dart';
import 'package:cheers/widgets/show_like_or_dislike.dart';
import 'package:cheers/widgets/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:cheers/helpers/app_helper.dart';

class ProfileCard extends StatelessWidget {
  /// User object
  final User user;

  /// Screen to be checked
  final String? page;

  /// Swiper position
  final SwiperPosition? position;

  /// Compatibility percentage
  final double? compatibility;

  ProfileCard({
    super.key,
    this.page,
    this.position,
    required this.user,
    this.compatibility,
  });

  // Local variables
  final AppHelper _appHelper = AppHelper();

  @override
  Widget build(BuildContext context) {
    // Debug print pour vérifier la compatibilité
    if (page == 'discover' && compatibility != null) {
      debugPrint(
        '🎯 ProfileCard: Affichage compatibility ${compatibility!.round()}% pour ${user.userFullname}',
      );
    }

    // Variables
    final bool requireVip = page == 'require_vip' && !UserModel().userIsVip;
    late ImageProvider userPhoto;
    // Check user vip status
    if (requireVip) {
      userPhoto = const AssetImage('assets/images/crow_badge.png');
    } else {
      userPhoto = NetworkImage(user.userProfilePhoto);
    }

    //
    // Get User Birthday
    final DateTime userBirthday = DateTime(
      user.userBirthYear,
      user.userBirthMonth,
      user.userBirthDay,
    );
    // Get User Current Age
    final int userAge = UserModel().calculateUserAge(userBirthday);

    // Build profile card
    return Padding(
      key: UniqueKey(),
      padding: const EdgeInsets.all(9.0),
      child: Stack(
        children: [
          /// User Card
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 4.0,
            margin: const EdgeInsets.all(0),
            shape: defaultCardBorder(),
            child: Container(
              decoration: BoxDecoration(
                /// User profile image
                image: DecorationImage(
                  /// Show VIP icon if user is not vip member
                  image: userPhoto,
                  fit: requireVip ? BoxFit.contain : BoxFit.cover,
                ),
              ),
              child: Container(
                /// BoxDecoration to make user info visible
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Colors.transparent,
                    ],
                  ),
                ),

                /// User info container
                child: Container(
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(16.0), // Padding plus généreux
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// User fullname
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${user.userFullname}, '
                              '${userAge.toString()}',
                              style: TextStyle(
                                fontSize: page == 'discover'
                                    ? 22
                                    : 18, // Taille plus grande
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.7),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      /// User education

                      // Note: Uncoment the code below if you want to show the education

                      // Row(
                      //   children: [
                      //     const SvgIcon("assets/icons/university_icon.svg",
                      //         color: Colors.white, width: 20, height: 20),
                      //     const SizedBox(width: 5),
                      //     Expanded(
                      //       child: Text(
                      //         user.userSchool,
                      //         style: const TextStyle(
                      //           color: Colors.white,
                      //           fontSize: 16,
                      //         ),
                      //         maxLines: 1,
                      //         overflow: TextOverflow.ellipsis,
                      //       ),
                      //     ),
                      //   ],
                      // ),

                      // const SizedBox(height: 3),

                      // User job title
                      // Note: Uncoment the code below if you want to show the job title

                      // Row(
                      //   children: [
                      //     const SvgIcon("assets/icons/job_bag_icon.svg",
                      //         color: Colors.white, width: 17, height: 17),
                      //     const SizedBox(width: 5),
                      //     Expanded(
                      //       child: Text(
                      //         user.userJobTitle,
                      //         style: const TextStyle(
                      //           color: Colors.white,
                      //           fontSize: 16,
                      //         ),
                      //         maxLines: 1,
                      //         overflow: TextOverflow.ellipsis,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      page == 'discover'
                          ? const SizedBox(height: 70)
                          : const SizedBox(width: 0, height: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// Show location distance
          Positioned(
            top: 10,
            left: 8,
            child: CustomBadge(
              icon: page == 'discover'
                  ? const SvgIcon(
                      "assets/icons/location_point_icon.svg",
                      color: Colors.white,
                      width: 15,
                      height: 15,
                    )
                  : null,
              text:
                  '${_appHelper.getDistanceBetweenUsers(userLat: user.userGeoPoint.latitude, userLong: user.userGeoPoint.longitude)}km',
            ),
          ),

          /// Show compatibility percentage
          page == 'discover' && compatibility != null
              ? Positioned(
                  bottom: 90, // En bas, au-dessus des boutons
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SvgIcon(
                          "assets/icons/heart_icon.svg",
                          color: Colors.white,
                          width: 14,
                          height: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${compatibility!.round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: 0, height: 0),

          /// Show Like or Dislike
          page == 'discover'
              ? ShowLikeOrDislike(position: position!)
              : const SizedBox(width: 0, height: 0),

          /// Show message icon
          page == 'matches'
              ? Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const SvgIcon(
                      "assets/icons/message_icon.svg",
                      color: Colors.white,
                      width: 30,
                      height: 30,
                    ),
                  ),
                )
              : const SizedBox(width: 0, height: 0),

          // Show Report/Block profile button
          page == 'discover'
              ? Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 36, // Taille fixe pour uniformité
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.flag,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => ReportDialog(userId: user.userId).show(),
                    ),
                  ),
                )
              : const SizedBox(width: 0, height: 0),
        ],
      ),
    );
  }
}
