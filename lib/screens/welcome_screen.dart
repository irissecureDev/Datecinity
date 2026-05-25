import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:datecinity/screens/complete_profile_screen.dart';
import 'package:datecinity/models/user_model.dart';
import 'package:datecinity/constants/constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;
  bool _navigating = false;

  static const _bgColor = Color(0xFF0D001A);
  static const _accentColor = Color(0xFFFA7E45);

  static const _firebaseVideoUrl =
      'https://firebasestorage.googleapis.com/v0/b/soulemate-e3cc5.firebasestorage.app/o/uploads%2FVideos%2Fintro_video.mp4?alt=media&token=3ee987ae-adff-473e-ba7d-fb23d9f99864';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(_firebaseVideoUrl),
    );

    await _videoPlayerController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: true,
      showControls: false,
      allowFullScreen: false,
      placeholder: Container(color: Colors.black),
    );

    if (mounted) setState(() => _videoInitialized = true);
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _goToCompatibilityQuiz() async {
    if (_navigating) return;
    _navigating = true;
    await UserModel().updateUserData(
      userId: UserModel().user.userId,
      data: {USER_HAS_SEEN_WELCOME: true},
    );
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CompleteProfileScreen(showBackButton: true),
        ),
      );
      if (mounted) _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video (Firebase Storage MP4) ──────────────────────────────
          if (_videoInitialized && _chewieController != null)
            Chewie(controller: _chewieController!)
          else
            Container(color: _bgColor),

          // ── Loading overlay ───────────────────────────────────────────
          AnimatedOpacity(
            opacity: _videoInitialized ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: IgnorePointer(
              ignoring: _videoInitialized,
              child: Container(
                color: _bgColor,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _accentColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading video…',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Top gradient ──────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0, height: 140,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xDD000000), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom gradient ───────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0, height: 180,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xF5000000), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // ── Top bar: skip ─────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48),
                    _SkipButton(onTap: _goToCompatibilityQuiz),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom CTA ────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: AnimatedOpacity(
                  opacity: _videoInitialized ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: GestureDetector(
                    onTap: _goToCompatibilityQuiz,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFA7E45), Color(0xFFD95F02)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withOpacity(0.45),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Begin Test',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 3),
            Icon(Icons.chevron_right_rounded, color: Colors.white60, size: 18),
          ],
        ),
      ),
    );
  }
}
