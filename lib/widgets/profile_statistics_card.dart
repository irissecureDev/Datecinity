import 'package:cheers/helpers/app_localizations.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/screens/complete_profile_screen.dart';
import 'package:cheers/screens/disliked_profile_screen.dart';
import 'package:cheers/screens/profile_likes_screen.dart';
import 'package:cheers/screens/profile_visits_screen.dart';
import 'package:cheers/widgets/default_card_border.dart';
import 'package:cheers/widgets/svg_icon.dart';
import 'package:flutter/material.dart';

class ProfileStatisticsCard extends StatelessWidget {
  // Text style
  final _textStyle = const TextStyle(
    color: Colors.black,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
  );

  const ProfileStatisticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    /// Initialization
    final i18n = AppLocalizations.of(context);

    return Card(
      elevation: 4.0,
      color: Colors.grey[100],
      shape: defaultCardBorder(),
      child: Column(
        children: [
          ListTile(
            leading: SvgIcon(
              "assets/icons/settings_icon.svg",
              width: 22,
              height: 22,
              color: Theme.of(context).primaryColor,
            ),
            trailing: const Icon(Icons.arrow_forward),
            title: Text(i18n.translate("setup_preferences"), style: _textStyle),
            onTap: () {
              /// Go to profile visits screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const CompleteProfileScreen(showBackButton: true),
                ),
              );
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: SvgIcon(
              "assets/icons/heart_icon.svg",
              width: 22,
              height: 22,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(i18n.translate("LIKES"), style: _textStyle),
            trailing: _counter(context, UserModel().user.userTotalLikes),
            onTap: () {
              /// Go to profile likes screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileLikesScreen(),
                ),
              );
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: SvgIcon(
              "assets/icons/eye_icon.svg",
              width: 31,
              height: 31,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(i18n.translate("VISITS"), style: _textStyle),
            trailing: _counter(context, UserModel().user.userTotalVisits),
            onTap: () {
              /// Go to profile visits screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileVisitsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: SvgIcon(
              "assets/icons/close_icon.svg",
              width: 25,
              height: 25,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(i18n.translate("DISLIKED_PROFILES"), style: _textStyle),
            trailing: _counter(context, UserModel().user.userTotalDisliked),
            onTap: () {
              /// Go to disliked profile screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DislikedProfilesScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _counter(BuildContext context, int value) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor, //.withAlpha(85),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(6.0),
      child: Text(
        value.toString(),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
