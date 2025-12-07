import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget pour afficher un score de compatibilité avec indicateur visuel
///
/// Fonctionnalités:
/// - Affichage circulaire du score avec animation
/// - Indicateur de couleur selon le niveau de compatibilité
/// - Mode détaillé avec breakdown
/// - Mode overlay pour les cartes
class CompatibilityScoreWidget extends StatefulWidget {
  final double score; // Score entre 0.0 et 1.0
  final bool showDetails;
  final bool isOverlay;
  final Map<String, double>? scoreBreakdown;

  const CompatibilityScoreWidget({
    super.key,
    required this.score,
    this.showDetails = false,
    this.isOverlay = false,
    this.scoreBreakdown,
  });

  @override
  State<CompatibilityScoreWidget> createState() =>
      _CompatibilityScoreWidgetState();
}

class _CompatibilityScoreWidgetState extends State<CompatibilityScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialiser les animations
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: widget.score).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );
  }

  /// Démarrer l'animation
  void _startAnimation() {
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  /// Obtenir la couleur selon le score
  Color _getScoreColor(double score) {
    if (score >= 0.8) {
      return Colors.green;
    } else if (score >= 0.6) {
      return Colors.lightGreen;
    } else if (score >= 0.4) {
      return Colors.orange;
    } else if (score >= 0.2) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }

  /// Obtenir le texte descriptif du score
  String _getScoreDescription(double score) {
    if (score >= 0.8) {
      return 'Excellente compatibilité';
    } else if (score >= 0.6) {
      return 'Bonne compatibilité';
    } else if (score >= 0.4) {
      return 'Compatibilité correcte';
    } else if (score >= 0.2) {
      return 'Compatibilité faible';
    } else {
      return 'Compatibilité très faible';
    }
  }

  /// Obtenir l'icône selon le score
  IconData _getScoreIcon(double score) {
    if (score >= 0.8) {
      return Icons.favorite;
    } else if (score >= 0.6) {
      return Icons.thumb_up;
    } else if (score >= 0.4) {
      return Icons.thumbs_up_down;
    } else if (score >= 0.2) {
      return Icons.thumb_down;
    } else {
      return Icons.close;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOverlay) {
      return _buildOverlayWidget();
    } else if (widget.showDetails) {
      return _buildDetailedWidget();
    } else {
      return _buildSimpleWidget();
    }
  }

  /// Widget simple pour affichage basique
  Widget _buildSimpleWidget() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicateur circulaire
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  children: [
                    // Cercle de fond
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                    ),

                    // Cercle de progression
                    CustomPaint(
                      size: Size(40, 40),
                      painter: CircularProgressPainter(
                        progress: _progressAnimation.value,
                        color: _getScoreColor(widget.score),
                        backgroundColor: Colors.grey[200]!,
                        strokeWidth: 3,
                      ),
                    ),

                    // Pourcentage au centre
                    Center(
                      child: Text(
                        '${(_progressAnimation.value * 100).round()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(widget.score),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8),

              // Texte de compatibilité
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Compatibilité',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${(widget.score * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(widget.score),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Widget overlay pour les cartes
  Widget _buildOverlayWidget() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getScoreIcon(widget.score),
                  size: 16,
                  color: _getScoreColor(widget.score),
                ),
                SizedBox(width: 4),
                Text(
                  '${(widget.score * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Widget détaillé avec breakdown
  Widget _buildDetailedWidget() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getScoreColor(widget.score).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête avec score principal
                Row(
                  children: [
                    // Indicateur circulaire principal
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        children: [
                          // Cercle de fond
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[100],
                            ),
                          ),

                          // Cercle de progression
                          CustomPaint(
                            size: Size(60, 60),
                            painter: CircularProgressPainter(
                              progress: _progressAnimation.value,
                              color: _getScoreColor(widget.score),
                              backgroundColor: Colors.grey[200]!,
                              strokeWidth: 4,
                            ),
                          ),

                          // Pourcentage au centre
                          Center(
                            child: Text(
                              '${(_progressAnimation.value * 100).round()}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(widget.score),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 16),

                    // Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Score de Compatibilité',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _getScoreDescription(widget.score),
                            style: TextStyle(
                              fontSize: 14,
                              color: _getScoreColor(widget.score),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Breakdown des critères si disponible
                if (widget.scoreBreakdown != null &&
                    widget.scoreBreakdown!.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 8),
                  Text(
                    'Détail des critères:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),

                  // Liste des critères
                  ...widget.scoreBreakdown!.entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _buildCriteriaBar(entry.key, entry.value),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construire une barre de critère individuel
  Widget _buildCriteriaBar(String criteria, double score) {
    final displayName = _getCriteriaDisplayName(criteria);
    final color = _getScoreColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayName,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              '${(score * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Obtenir le nom d'affichage d'un critère
  String _getCriteriaDisplayName(String criteria) {
    switch (criteria) {
      case 'interests':
        return 'Centres d\'intérêt';
      case 'lifestyle':
        return 'Style de vie';
      case 'values':
        return 'Valeurs';
      case 'goals':
        return 'Objectifs';
      case 'personality':
        return 'Personnalité';
      default:
        return criteria;
    }
  }
}

/// Painter pour dessiner le cercle de progression
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Dessiner le cercle de fond
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Dessiner l'arc de progression
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Commencer en haut
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate != this;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CircularProgressPainter &&
        other.progress == progress &&
        other.color == color &&
        other.backgroundColor == backgroundColor &&
        other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode {
    return Object.hash(progress, color, backgroundColor, strokeWidth);
  }
}
