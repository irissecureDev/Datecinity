import 'package:flutter/material.dart';

/// Widget to display matching score breakdown by preference section
/// Shows the compatibility percentage for each of the 7 sections:
/// 1. WHAT YOU WANT IN LOVE (20% weight)
/// 2. HOW YOU HANDLE FEELINGS (15% weight)
/// 3. HOW YOU COMMUNICATE (20% weight)
/// 4. LOVE & CONNECTION (15% weight)
/// 5. LIFESTYLE & HABITS (15% weight)
/// 6. PERSONALITY & CONNECTION (10% weight)
/// 7. WHAT MATTERS MOST (5% weight)
class MatchingBreakdownWidget extends StatefulWidget {
  /// Overall matching percentage (0-100)
  final double overallScore;

  /// Section scores (0-100) by section number
  /// Example: { 1: 85, 2: 90, 3: 75, ... }
  final Map<int, double>? sectionScores;

  /// Whether to show detailed breakdown
  final bool showDetails;

  /// Callback when user taps to expand/collapse
  final VoidCallback? onToggleExpand;

  const MatchingBreakdownWidget({
    super.key,
    required this.overallScore,
    this.sectionScores,
    this.showDetails = false,
    this.onToggleExpand,
  });

  @override
  State<MatchingBreakdownWidget> createState() =>
      _MatchingBreakdownWidgetState();
}

class _MatchingBreakdownWidgetState extends State<MatchingBreakdownWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late bool _isExpanded;

  static const Color _accentColor = Color(0xFFFA7E45);
  static const Color _backgroundColor = Color(0xFF120024);

  final List<Map<String, dynamic>> _sections = [
    {
      'number': 1,
      'title': 'What You Want In Love',
      'weight': 0.20,
      'description': 'Relationship goals & kids',
      'icon': Icons.favorite_border,
    },
    {
      'number': 2,
      'title': 'How You Handle Feelings',
      'weight': 0.15,
      'description': 'Emotional responses',
      'icon': Icons.mood,
    },
    {
      'number': 3,
      'title': 'How You Communicate',
      'weight': 0.20,
      'description': 'Communication style',
      'icon': Icons.chat_bubble_outline,
    },
    {
      'number': 4,
      'title': 'Love & Connection',
      'weight': 0.15,
      'description': 'Physical & emotional intimacy',
      'icon': Icons.favorite,
    },
    {
      'number': 5,
      'title': 'Lifestyle & Habits',
      'weight': 0.15,
      'description': 'Daily life compatibility',
      'icon': Icons.fitness_center,
    },
    {
      'number': 6,
      'title': 'Personality & Connection',
      'weight': 0.10,
      'description': 'Social energy & personality fit',
      'icon': Icons.person_outline,
    },
    {
      'number': 7,
      'title': 'What Matters Most',
      'weight': 0.05,
      'description': 'Core values & beliefs',
      'icon': Icons.star_outline,
    },
  ];

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.showDetails;
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (_isExpanded) {
      _expandController.forward();
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  /// Toggle expand/collapse state
  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }

    widget.onToggleExpand?.call();
  }

  /// Get color based on score
  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF4CAF50); // Green
    if (score >= 60) return const Color(0xFF8BC34A); // Light green
    if (score >= 40) return const Color(0xFFFFC107); // Amber
    return const Color(0xFFFF6B6B); // Red
  }

  /// Get overall match level text
  String _getMatchLevel(double score) {
    if (score >= 90) return 'Excellent Match';
    if (score >= 80) return 'Great Match';
    if (score >= 70) return 'Good Match';
    if (score >= 60) return 'Fair Match';
    return 'Low Match';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Overall score header
          GestureDetector(
            onTap: _toggleExpand,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _isExpanded ? _accentColor : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compatibility Match',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getScoreColor(
                                  widget.overallScore,
                                ).withOpacity(0.2),
                                border: Border.all(
                                  color: _getScoreColor(widget.overallScore),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${widget.overallScore.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(widget.overallScore),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _getMatchLevel(widget.overallScore),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: _isExpanded ? _accentColor : Colors.white54,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section breakdown (expandable)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: List.generate(_sections.length, (index) {
                        final section = _sections[index];
                        final sectionNumber = section['number'] as int;
                        final sectionScore =
                            widget.sectionScores?[sectionNumber] ??
                            (widget.overallScore); // Fallback to overall score
                        final weight = section['weight'] as double;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildSectionRow(
                            section: section,
                            score: sectionScore,
                            weight: weight,
                          ),
                        );
                      }),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Build individual section row
  Widget _buildSectionRow({
    required Map<String, dynamic> section,
    required double score,
    required double weight,
  }) {
    final title = section['title'] as String;
    final description = section['description'] as String;
    final icon = section['icon'] as IconData;
    final color = _getScoreColor(score);

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                border: Border.all(color: color),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${score.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(×${(weight * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
