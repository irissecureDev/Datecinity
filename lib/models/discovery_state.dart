import 'package:datecinity/models/proximity_profile.dart';

enum DiscoveryStep {
  proximityDetected, // Notification et bouton click-to-match
  proximitySearch, // "Finding someone nearby..."
  profileView, // "Here's the profile found"
  sparkForming, // "A Spark is forming..."
  matchFound, // "Here's who you matched with"
  timerCountdown, // Timer 10 minutes avec profils
  swipeToAdd, // Animation swipe sur téléphone
  flameSuccess, // "Your Spark has become a Flame"
  error,
  idle,
}

class DiscoveryState {
  final DiscoveryStep flow;
  final ProximityProfile? targetProfile;
  final String? sparkId;
  final Duration? remainingTime;
  final String? errorMessage;
  final String? infoMessage;
  final bool isAnimating;

  const DiscoveryState({
    required this.flow,
    this.targetProfile,
    this.sparkId,
    this.remainingTime,
    this.errorMessage,
    this.infoMessage,
    this.isAnimating = false,
  });

  static const Object _keep = Object();

  DiscoveryState copyWith({
    DiscoveryStep? flow,
    Object? targetProfile = _keep,
    Object? sparkId = _keep,
    Object? remainingTime = _keep,
    Object? errorMessage = _keep,
    Object? infoMessage = _keep,
    bool? isAnimating,
  }) {
    return DiscoveryState(
      flow: flow ?? this.flow,
      targetProfile: identical(targetProfile, _keep)
          ? this.targetProfile
          : targetProfile as ProximityProfile?,
      sparkId: identical(sparkId, _keep) ? this.sparkId : sparkId as String?,
      remainingTime: identical(remainingTime, _keep)
          ? this.remainingTime
          : remainingTime as Duration?,
      errorMessage: identical(errorMessage, _keep)
          ? this.errorMessage
          : errorMessage as String?,
      infoMessage: identical(infoMessage, _keep)
          ? this.infoMessage
          : infoMessage as String?,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }

  static const idle = DiscoveryState(flow: DiscoveryStep.idle);
}

// Configuration pour les timers et animations
class DiscoveryConfig {
  static const Duration proximitySearchDuration = Duration(seconds: 3);
  static const Duration sparkFormingDuration = Duration(seconds: 2);
  static const Duration matchFoundDisplayDuration = Duration(seconds: 3);
  static const Duration countdownDuration = Duration(minutes: 10);
  static const Duration flameSuccessDuration = Duration(seconds: 4);

  static const double maxProximityDistance = 0.5; // 500m
  static const double minCompatibilityForMatch = 0.6; // 60%
}
