import 'package:cheers/models/proximity_profile.dart';

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
  final Duration? remainingTime;
  final String? errorMessage;
  final bool isAnimating;

  const DiscoveryState({
    required this.flow,
    this.targetProfile,
    this.remainingTime,
    this.errorMessage,
    this.isAnimating = false,
  });

  DiscoveryState copyWith({
    DiscoveryStep? flow,
    ProximityProfile? targetProfile,
    Duration? remainingTime,
    String? errorMessage,
    bool? isAnimating,
  }) {
    return DiscoveryState(
      flow: flow ?? this.flow,
      targetProfile: targetProfile ?? this.targetProfile,
      remainingTime: remainingTime ?? this.remainingTime,
      errorMessage: errorMessage ?? this.errorMessage,
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
  static const double minCompatibilityForMatch = 0.7; // 70%
}
