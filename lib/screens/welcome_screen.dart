import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cheers/screens/complete_profile_screen.dart';
import 'package:cheers/models/user_model.dart';
import 'package:cheers/constants/constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  WebViewController? _controller;
  bool _pageLoaded = false;
  bool _navigating = false;
  Timer? _fallbackTimer;

  static const _bgColor = Color(0xFF0D001A);
  static const _accentColor = Color(0xFFFA7E45);

  // Mobile Safari UA so YouTube renders its full mobile player
  static const _userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'Version/17.0 Mobile/15E148 Safari/604.1';

  static const _videoUrl = 'https://www.youtube.com/shorts/e6L97wfq-MQ';

  @override
  void initState() {
    super.initState();
    // Fallback: always show button after 4 s even if the video never loads
    _fallbackTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_pageLoaded) setState(() => _pageLoaded = true);
    });
    // Defer WebView creation until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setUserAgent(_userAgent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _pageLoaded = true);
            },
            onWebResourceError: (_) {
              if (mounted) setState(() => _pageLoaded = true);
            },
          ),
        )
        ..loadRequest(Uri.parse(_videoUrl));

      if (mounted) setState(() => _controller = ctrl);
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
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
      // Reset flag so the button works again if the user comes back
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
          // ── Video (YouTube Shorts page) ────────────────────────────────
          if (_controller != null) WebViewWidget(controller: _controller!),

          // ── Loading overlay ────────────────────────────────────────────
          AnimatedOpacity(
            opacity: _pageLoaded ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            child: IgnorePointer(
              ignoring: _pageLoaded,
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

          // ── Top gradient ───────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
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

          // ── Bottom gradient ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 180,
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

          // ── Top bar: back + skip ───────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
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

          // ── Bottom CTA ─────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: AnimatedOpacity(
                  opacity: _pageLoaded ? 1.0 : 0.0,
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

// ── Shared small widgets ──────────────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
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
