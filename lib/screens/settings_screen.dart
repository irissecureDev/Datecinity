import 'package:datecinity/constants/constants.dart';
import 'package:datecinity/dialogs/show_me_dialog.dart';
// import 'package:datecinity/dialogs/vip_dialog.dart';
import 'package:datecinity/helpers/app_localizations.dart';
import 'package:datecinity/models/app_model.dart';
import 'package:datecinity/models/user_model.dart';
import 'package:datecinity/plugins/locationpicker/place_picker.dart';
// import 'package:datecinity/screens/passport_screen.dart';
import 'package:datecinity/widgets/show_scaffold_msg.dart';
import 'package:datecinity/widgets/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  // Variables
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late RangeValues _selectedAgeRange;
  late RangeLabels _selectedAgeRangeLabels;
  late double _selectedMaxDistance;
  // bool _hideProfile = false; // Not used since hide profile section is commented
  late AppLocalizations _i18n;

  /// Initialize user settings
  void initUserSettings() {
    // Get user settings
    final Map<String, dynamic> userSettings = UserModel().user.userSettings!;
    // Update variables state
    setState(() {
      // Get user max distance
      _selectedMaxDistance = userSettings[USER_MAX_DISTANCE].toDouble();

      // Get age range
      final double minAge = userSettings[USER_MIN_AGE].toDouble();
      final double maxAge = userSettings[USER_MAX_AGE].toDouble();

      // Set range values
      _selectedAgeRange = RangeValues(minAge, maxAge);
      _selectedAgeRangeLabels = RangeLabels('$minAge', '$maxAge');

      // Check profile status
      // if (UserModel().user.userStatus == 'hidden') {
      //   _hideProfile = true;
      // }
    });
  }

  String _showMeOption(AppLocalizations i18n) {
    // Variables
    final Map<String, dynamic> settings = UserModel().user.userSettings!;
    final String? showMe = settings[USER_SHOW_ME];
    // Check option
    if (showMe != null) {
      return i18n.translate(showMe);
    }
    return i18n.translate('opposite_gender');
  }

  @override
  void initState() {
    super.initState();
    initUserSettings();
  }

  // Go to Passport screen
  // Future<void> _goToPassportScreen() async {
  //   // Get picked location result
  //   LocationResult? result = await Navigator.of(context).push<LocationResult?>(
  //     MaterialPageRoute(builder: (context) => const PassportScreen()),
  //   );
  //   // Handle the retur result
  //   if (result != null) {
  //     // Update current your location
  //     _updateUserLocation(true, locationResult: result);
  //     // Debug info
  //     debugPrint(
  //       '_goToPassportScreen() -> result: ${result.country!.name}, ${result.city!.name}',
  //     );
  //   } else {
  //     debugPrint('_goToPassportScreen() -> result: empty');
  //   }
  // }

  // Update User Location
  Future<void> _updateUserLocation(
    bool isPassport, {
    LocationResult? locationResult,
  }) async {
    /// Update user location: Country & City an Geo Data

    /// Update user data
    await UserModel().updateUserLocation(
      isPassport: isPassport,
      locationResult: locationResult,
      onSuccess: () {
        // Show success message
        showScaffoldMessage(
          context: context,
          message: _i18n.translate("location_updated_successfully"),
        );
      },
      onFail: () {
        // Show error message
        showScaffoldMessage(
          context: context,
          message: _i18n.translate("we_were_unable_to_update_your_location"),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);

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
          _i18n.translate("settings"),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ScopedModelDescendant<UserModel>(
          builder: (context, child, userModel) {
            return Column(
              children: [
                /// User current location
                Container(
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.1),
                              Theme.of(context).primaryColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SvgIcon(
                                "assets/icons/location_point_icon.svg",
                                color: Theme.of(context).primaryColor,
                                width: 24,
                                height: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _i18n.translate("your_current_location"),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${UserModel().user.userCountry}, ${UserModel().user.userLocality}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
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
                                  onPressed: () async {
                                    /// Update user location: Country & City an Geo Data
                                    _updateUserLocation(false);
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _i18n.translate("UPDATE"),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                /// User Max distance
                Container(
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.1),
                              Theme.of(context).primaryColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.radar,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_i18n.translate("maximum_distance")} ${_selectedMaxDistance.round()} km',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _i18n.translate(
                                      "show_people_within_this_radius",
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                '${_selectedMaxDistance.round()} km',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Theme.of(
                                  context,
                                ).primaryColor,
                                inactiveTrackColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.2),
                                thumbColor: Theme.of(context).primaryColor,
                                overlayColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.2),
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 12,
                                ),
                                trackHeight: 6,
                              ),
                              child: Slider(
                                value: _selectedMaxDistance,
                                divisions: 100,
                                min: 0,

                                /// Check User VIP Account to set max distance available
                                max: UserModel().userIsVip
                                    ? AppModel().appInfo.vipAccountMaxDistance
                                    : AppModel().appInfo.freeAccountMaxDistance,
                                onChanged: (radius) {
                                  setState(() {
                                    _selectedMaxDistance = radius;
                                  });
                                  // debug
                                  debugPrint(
                                    '_selectedMaxDistance: '
                                    '${radius.toStringAsFixed(2)}',
                                  );
                                },
                                onChangeEnd: (radius) {
                                  /// Update user max distance
                                  UserModel()
                                      .updateUserData(
                                        userId: UserModel().user.userId,
                                        data: {
                                          '$USER_SETTINGS.$USER_MAX_DISTANCE':
                                              double.parse(
                                                radius.toStringAsFixed(2),
                                              ),
                                        },
                                      )
                                      .then((_) {
                                        debugPrint(
                                          'User max distance updated -> ${radius.toStringAsFixed(2)}',
                                        );
                                      });
                                },
                              ),
                            ),
                            // Show message for non VIP user
                            UserModel().userIsVip
                                ? const SizedBox(width: 0, height: 0)
                                : Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
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
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Theme.of(context).primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "${_i18n.translate("need_more_radius_away")} "
                                            "${AppModel().appInfo.vipAccountMaxDistance} km "
                                            "${_i18n.translate('radius_away')}",
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // User age range
                Container(
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.1),
                              Theme.of(context).primaryColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _i18n.translate("age_range"),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _i18n.translate(
                                      "show_people_within_this_age_range",
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${_selectedAgeRange.start.toStringAsFixed(0)} - "
                                "${_selectedAgeRange.end.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Theme.of(context).primaryColor,
                            inactiveTrackColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.2),
                            thumbColor: Theme.of(context).primaryColor,
                            overlayColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.2),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12,
                            ),
                            trackHeight: 6,
                          ),
                          child: RangeSlider(
                            values: _selectedAgeRange,
                            labels: _selectedAgeRangeLabels,
                            divisions: 100,
                            min: 18,
                            max: 100,
                            onChanged: (newRange) {
                              // Update state
                              setState(() {
                                _selectedAgeRange = newRange;
                                _selectedAgeRangeLabels = RangeLabels(
                                  newRange.start.toStringAsFixed(0),
                                  newRange.end.toStringAsFixed(0),
                                );
                              });
                              debugPrint(
                                '_selectedAgeRange: $_selectedAgeRange',
                              );
                            },
                            onChangeEnd: (endValues) {
                              /// Update age range
                              ///
                              /// Get start value
                              final int minAge = int.parse(
                                endValues.start.toStringAsFixed(0),
                              );

                              /// Get end value
                              final int maxAge = int.parse(
                                endValues.end.toStringAsFixed(0),
                              );

                              // Update age range
                              UserModel()
                                  .updateUserData(
                                    userId: UserModel().user.userId,
                                    data: {
                                      '$USER_SETTINGS.$USER_MIN_AGE': minAge,
                                      '$USER_SETTINGS.$USER_MAX_AGE': maxAge,
                                    },
                                  )
                                  .then((_) {
                                    debugPrint('Age range updated');
                                  });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Show me option
                Container(
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(20),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.2),
                            Theme.of(context).primaryColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.wc_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      _i18n.translate('show_me'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _showMeOption(_i18n),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    onTap: () {
                      /// Choose Show me option
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return const ShowMeDialog();
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
