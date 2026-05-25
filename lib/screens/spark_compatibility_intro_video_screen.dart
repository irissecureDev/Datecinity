import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:datecinity/models/spark.dart';
import 'package:datecinity/screens/spark_compatibility_screen.dart';
import 'package:datecinity/widgets/spark_theme.dart';

class SparkCompatibilityIntroVideoScreen extends StatefulWidget {
  final Spark spark;

  const SparkCompatibilityIntroVideoScreen({super.key, required this.spark});

  @override
  State<SparkCompatibilityIntroVideoScreen> createState() =>
      _SparkCompatibilityIntroVideoScreenState();
}

class _SparkCompatibilityIntroVideoScreenState
    extends State<SparkCompatibilityIntroVideoScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: 'e6L97wfq-MQ',
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
        enableCaption: false,
      ),
    );

    _controller.stream.listen((value) {
      if (value.playerState == PlayerState.ended && mounted) {
        _goToCompatibilityTest();
      }
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _goToCompatibilityTest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SparkCompatibilityScreen(spark: widget.spark),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.spark.user.userFullname.split(' ').first;

    return Scaffold(
      body: SparkBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: SparkTheme.textPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _goToCompatibilityTest,
                      child: const Text(
                        'Skip Video',
                        style: TextStyle(
                          color: SparkTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const SparkLogo(size: 52),
                const SizedBox(height: 16),
                Text(
                  'Before Compatibility Test',
                  textAlign: TextAlign.center,
                  style: SparkTheme.titleStyle.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  'Watch this short intro, or skip anytime to start your compatibility test with $firstName.',
                  textAlign: TextAlign.center,
                  style: SparkTheme.bodyStyle,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: YoutubePlayer(controller: _controller),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SparkGradientButton(
                  text: 'Start Compatibility Test',
                  onPressed: _goToCompatibilityTest,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
