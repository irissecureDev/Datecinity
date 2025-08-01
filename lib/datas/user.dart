import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soulmate/constants/constants.dart';

class User {
  /// User info
  final String userId;
  final String userProfilePhoto;
  final String userFullname;
  final String userGender;
  final int userBirthDay;
  final int userBirthMonth;
  final int userBirthYear;
  final String education;
  final String religion;
  final List<String> hobbies;
  final List<String> pets;
  final List<String> languages;
  final String userBio;
  final String userPhoneNumber;
  final String userEmail;
  final String userCountry;
  final String userLocality;
  final GeoPoint userGeoPoint;
  final String userStatus;
  final bool userIsVerified;
  final String userLevel;
  final DateTime userRegDate;
  final DateTime userLastLogin;
  final String userDeviceToken;
  final int userTotalLikes;
  final int userTotalVisits;
  final int userTotalDisliked;
  final Map<String, dynamic>? userGallery;
  final Map<String, dynamic>? userSettings;

  // Constructor
  User({
    required this.userId,
    required this.userProfilePhoto,
    required this.userFullname,
    required this.userGender,
    required this.userBirthDay,
    required this.userBirthMonth,
    required this.userBirthYear,
    required this.userBio,
    required this.userPhoneNumber,
    required this.userEmail,
    required this.userGallery,
    required this.userCountry,
    required this.userLocality,
    required this.userGeoPoint,
    required this.userSettings,
    required this.userStatus,
    required this.userLevel,
    required this.userIsVerified,
    required this.userRegDate,
    required this.userLastLogin,
    required this.userDeviceToken,
    required this.userTotalLikes,
    required this.userTotalVisits,
    required this.userTotalDisliked,
    required this.education,
    required this.religion,
    required this.hobbies,
    required this.languages,
    required this.pets,
  });

  /// factory user object
  factory User.fromDocument(Map<String, dynamic> doc) {
    return User(
      userId: doc[USER_ID],
      userProfilePhoto: doc[USER_PROFILE_PHOTO],
      userFullname: doc[USER_FULLNAME],
      userGender: doc[USER_GENDER],
      userBirthDay: doc[USER_BIRTH_DAY],
      userBirthMonth: doc[USER_BIRTH_MONTH],
      userBirthYear: doc[USER_BIRTH_YEAR],
      userBio: doc[USER_BIO] ?? '',
      userPhoneNumber: doc[USER_PHONE_NUMBER] ?? '',
      userEmail: doc[USER_EMAIL] ?? '',
      userGallery: doc[USER_GALLERY],
      userCountry: doc[USER_COUNTRY] ?? '',
      userLocality: doc[USER_LOCALITY] ?? '',
      userGeoPoint: doc[USER_GEO_POINT]['geopoint'],
      userSettings: doc[USER_SETTINGS],
      userStatus: doc[USER_STATUS],
      userIsVerified: doc[USER_IS_VERIFIED] ?? false,
      userLevel: doc[USER_LEVEL],
      userRegDate: doc[USER_REG_DATE].toDate(), // Firestore Timestamp
      userLastLogin: doc[USER_LAST_LOGIN].toDate(), // Firestore Timestamp
      userDeviceToken: doc[USER_DEVICE_TOKEN],
      userTotalLikes: doc[USER_TOTAL_LIKES] ?? 0,
      userTotalVisits: doc[USER_TOTAL_VISITS] ?? 0,
      userTotalDisliked: doc[USER_TOTAL_DISLIKED] ?? 0,
      education: doc[USER_EDUCATION] ?? "",
      religion: doc[USER_RELIGION] ?? '',
      pets: List<String>.from(doc[USER_PETS] ?? []),
      hobbies: List<String>.from(doc[USER_HOBBIES] ?? []),
      languages: List<String>.from(doc[USER_LANGUAGES] ?? []),
    );
  }

  Future<BitmapDescriptor> getMarkerFromUrl({int size = 100}) async {
    try {
      final http.Response response = await http.get(
        Uri.parse(userProfilePhoto),
      );
      if (response.statusCode != 200) throw Exception("Failed to load image");

      final Uint8List imageData = response.bodyBytes;
      final ui.Codec codec = await ui.instantiateImageCodec(
        imageData,
        targetWidth: size,
        targetHeight: size,
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      final Paint paint = Paint()..isAntiAlias = true;
      final Rect rect = Rect.fromLTWH(
        0.0,
        0.0,
        size.toDouble(),
        size.toDouble(),
      );
      final RRect rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(size / 2),
      );
      canvas.clipRRect(rrect);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        paint,
      );

      final ui.Image markerAsImage = await recorder.endRecording().toImage(
        size,
        size,
      );
      final ByteData? byteData = await markerAsImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      // ignore: deprecated_member_use
      return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
    } catch (e) {
      debugPrint("Error creating marker icon: $e");
      return BitmapDescriptor.defaultMarker;
    }
  }
}

List<String> educationLevels = [
  "High School",
  "Bachelor",
  "Master",
  "Doctorate",
  "None",
  "Other",
];

List<String> religions = [
  "Christianity",
  "Islam",
  "Buddhism",
  "Judaism",
  "Hinduism",
  "Spiritual",
  "None",
  "Other",
];
