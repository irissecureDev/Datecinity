import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
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
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _initialized = false;

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
      looping: false,
      allowFullScreen: true,
      showControls: false,
      placeholder: Container(color: Colors.black),
    );

    _videoPlayerController!.addListener(() {
      if (_videoPlayerController!.value.position >=
              _videoPlayerController!.value.duration &&
          mounted) {
        _goToCompatibilityTest();
      }
    });

    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
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
                        child: _initialized && _chewieController != null
                            ? Chewie(controller: _chewieController!)
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
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
