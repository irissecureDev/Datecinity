import 'dart:io';

import 'package:soulmate/constants/constants.dart';
import 'package:soulmate/helpers/app_localizations.dart';
import 'package:soulmate/models/user_model.dart';
import 'package:soulmate/plugins/locationpicker/entities/localization_item.dart';
import 'package:soulmate/plugins/locationpicker/place_picker.dart';
import 'package:flutter/material.dart';

class PassportScreen extends StatelessWidget {
  const PassportScreen({super.key});

  // Get Google Maps API KEY
  String _getGoogleMapsAPIkey() {
    // Check the current Platform
    if (Platform.isAndroid) {
      // For Android
      return ANDROID_MAPS_API_KEY;
    } else if (Platform.isIOS) {
      // For iOS
      return IOS_MAPS_API_KEY;
    } else {
      return "Unknown platform";
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    final i18n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.translate('travel_to_any_country_or_city')),
      ),
      body: PlacePicker(
        _getGoogleMapsAPIkey(),
        displayLocation: LatLng(
          UserModel().user.userGeoPoint.latitude,
          UserModel().user.userGeoPoint.longitude,
        ),
        localizationItem: LocalizationItem(
          languageCode: i18n.translate('lang'),
          nearBy: i18n.translate('nearby_places'),
          findingPlace: i18n.translate('finding_place'),
          noResultsFound: i18n.translate('no_results_found'),
          unnamedLocation: i18n.translate('unnamed_location'),
          tapToSelectLocation: i18n.translate(
            'tap_here_to_select_this_location',
          ),
        ),
      ),
    );
  }
}
