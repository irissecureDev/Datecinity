import 'dart:math';
import 'package:flutter/material.dart';

class FlameAnimation extends StatefulWidget {
  final double size;
  final Color baseColor;
  final Duration duration;

  const FlameAnimation({
    super.key,
    this.size = 150,
    this.baseColor = const Color(0xFFFF6B35),
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<FlameAnimation> createState() => _FlameAnimationState();
}

class _FlameAnimationState extends State<FlameAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Icon(
              Icons.local_fire_department,
              size: widget.size,
              color: widget.baseColor,
            ),
          ),
        );
      },
    );
  }
}

class SparkleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final int sparkleCount;

  const SparkleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.sparkleCount = 12,
  });

  @override
  State<SparkleAnimation> createState() => _SparkleAnimationState();
}

class _SparkleAnimationState extends State<SparkleAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<SparkleParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _generateParticles();
    _controller.repeat();
  }

  void _generateParticles() {
    _particles = List.generate(widget.sparkleCount, (index) {
      return SparkleParticle(
        startAngle: _random.nextDouble() * 2 * pi,
        distance: 50 + _random.nextDouble() * 80,
        size: 3 + _random.nextDouble() * 5,
        animationDelay: _random.nextDouble() * 0.5,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Child widget (profile card)
        widget.child,

        // Sparkles
        ...List.generate(_particles.length, (index) {
          final particle = _particles[index];
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final animationValue =
                  (_controller.value + particle.animationDelay) % 1.0;
              final opacity = sin(animationValue * pi).abs();
              final currentDistance = particle.distance * animationValue;

              final x = cos(particle.startAngle) * currentDistance;
              final y = sin(particle.startAngle) * currentDistance;

              return Positioned(
                left: x,
                top: y,
                child: Transform.scale(
                  scale: 1.0 - (animationValue * 0.5),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            const Color(0xFFFFD54F),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

class SparkleParticle {
  final double startAngle;
  final double distance;
  final double size;
  final double animationDelay;

  SparkleParticle({
    required this.startAngle,
    required this.distance,
    required this.size,
    required this.animationDelay,
  });
}

class PulsingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;

  const PulsingIcon({
    super.key,
    required this.icon,
    this.size = 50,
    this.color = const Color(0xFFFF6B35),
  });

  @override
  State<PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(widget.icon, size: widget.size, color: widget.color),
        );
      },
    );
  }
}

class CircularProgressWithSpark extends StatefulWidget {
  final double progress;
  final double size;
  final Duration remainingTime;

  const CircularProgressWithSpark({
    super.key,
    required this.progress,
    this.size = 120,
    required this.remainingTime,
  });

  @override
  State<CircularProgressWithSpark> createState() =>
      _CircularProgressWithSparkState();
}

class _CircularProgressWithSparkState extends State<CircularProgressWithSpark>
    with TickerProviderStateMixin {
  late AnimationController _sparkController;

  @override
  void initState() {
    super.initState();
    _sparkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sparkController.repeat();
  }

  @override
  void dispose() {
    _sparkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = widget.remainingTime.inMinutes;
    final seconds = widget.remainingTime.inSeconds % 60;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 8,
            color: Colors.grey.withOpacity(0.2),
          ),

          // Progress circle
          CircularProgressIndicator(
            value: widget.progress,
            strokeWidth: 8,
            backgroundColor: Colors.transparent,
            color: const Color(0xFFFF6B35),
          ),

          // Animated spark at progress position
          AnimatedBuilder(
            animation: _sparkController,
            builder: (context, child) {
              final angle = widget.progress * 2 * pi - (pi / 2);
              final sparkOpacity = sin(_sparkController.value * pi).abs();
              final sparkScale =
                  1.0 + (sin(_sparkController.value * 2 * pi) * 0.3);

              return Transform.rotate(
                angle: angle,
                child: Transform.translate(
                  offset: Offset(0, -(widget.size / 2 - 10)),
                  child: Transform.scale(
                    scale: sparkScale,
                    child: Opacity(
                      opacity: sparkOpacity,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD54F),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Timer text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'remaining',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
