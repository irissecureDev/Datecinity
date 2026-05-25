import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:datecinity/datas/user.dart';
import 'package:datecinity/widgets/compatibility_score_widget.dart';

/// Widget de carte de profil avancée pour les suggestions
///
/// Affiche:
/// - Photo du profil
/// - Informations de base (nom, âge)
/// - Score de compatibilité détaillé
/// - Distance
/// - Actions rapides (like, super like, voir profil)
/// - Badges et indicateurs
class AdvancedProfileCard extends StatefulWidget {
  final User user;
  final double compatibility;
  final double distance;
  final bool isListView;
  final VoidCallback? onLike;
  final VoidCallback? onSuperLike;
  final VoidCallback? onViewProfile;

  const AdvancedProfileCard({
    super.key,
    required this.user,
    required this.compatibility,
    required this.distance,
    this.isListView = true,
    this.onLike,
    this.onSuperLike,
    this.onViewProfile,
  });

  @override
  State<AdvancedProfileCard> createState() => _AdvancedProfileCardState();
}

class _AdvancedProfileCardState extends State<AdvancedProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialiser les animations
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  /// Calculer l'âge à partir des composants de date
  int _calculateAge() {
    try {
      final birthDate = DateTime(
        widget.user.userBirthYear,
        widget.user.userBirthMonth,
        widget.user.userBirthDay,
      );
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 25; // Âge par défaut en cas d'erreur
    }
  }

  /// Obtenir l'indicateur de statut en ligne
  Widget _buildOnlineStatus() {
    final lastLogin = widget.user.userLastLogin;
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    Color statusColor;
    String statusText;

    if (difference.inMinutes < 5) {
      statusColor = Colors.green;
      statusText = 'En ligne';
    } else if (difference.inHours < 1) {
      statusColor = Colors.orange;
      statusText = 'Actif récemment';
    } else if (difference.inDays < 1) {
      statusColor = Colors.grey;
      statusText = 'Actif aujourd\'hui';
    } else {
      statusColor = Colors.grey[400]!;
      statusText =
          'Actif il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Construire les badges utilisateur
  List<Widget> _buildBadges() {
    List<Widget> badges = [];

    // Badge vérifié
    if (widget.user.userIsVerified == true) {
      badges.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, size: 12, color: Colors.white),
              SizedBox(width: 2),
              Text(
                'Vérifié',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Badge nouveauté (inscrit récemment)
    final joinDate = widget.user.userRegDate;
    if (DateTime.now().difference(joinDate).inDays < 7) {
      badges.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Nouveau',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return badges;
  }

  /// Gérer l'appui sur la carte
  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  /// Gérer la fin de l'appui
  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();

    if (widget.onViewProfile != null) {
      widget.onViewProfile!();
    }
  }

  /// Gérer l'annulation de l'appui
  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isListView) {
      return _buildListCard();
    } else {
      return _buildGridCard();
    }
  }

  /// Construire la carte en mode liste
  Widget _buildListCard() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Photo de profil
                      _buildProfileImage(size: 80),

                      SizedBox(width: 16),

                      // Informations
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nom et âge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.user.userFullname,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${_calculateAge()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 4),

                            // Distance
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${widget.distance.round()} km',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 8),

                            // Statut en ligne
                            _buildOnlineStatus(),

                            SizedBox(height: 8),

                            // Score de compatibilité
                            CompatibilityScoreWidget(
                              score: widget.compatibility,
                              showDetails: false,
                            ),

                            SizedBox(height: 8),

                            // Badges
                            if (_buildBadges().isNotEmpty)
                              Wrap(spacing: 4, children: _buildBadges()),
                          ],
                        ),
                      ),

                      // Actions
                      _buildActionButtons(isVertical: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construire la carte en mode grille
  Widget _buildGridCard() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo de profil en haut
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: _buildProfileImage(isCover: true),
                          ),

                          // Badges en overlay
                          if (_buildBadges().isNotEmpty)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Column(children: _buildBadges()),
                            ),

                          // Score de compatibilité en overlay
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: CompatibilityScoreWidget(
                              score: widget.compatibility,
                              showDetails: false,
                              isOverlay: true,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Informations en bas
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nom et âge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.user.userFullname,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${_calculateAge()}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 4),

                            // Distance
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '${widget.distance.round()} km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),

                            Spacer(),

                            // Actions
                            _buildActionButtons(isVertical: false),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construire l'image de profil
  Widget _buildProfileImage({double? size, bool isCover = false}) {
    final imageUrl = widget.user.userProfilePhoto;

    Widget imageWidget;

    if (imageUrl.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar(size);
        },
      );
    } else {
      imageWidget = _buildDefaultAvatar(size);
    }

    if (isCover) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: imageWidget,
      );
    } else {
      return Container(
        width: size ?? 80,
        height: size ?? 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imageWidget,
        ),
      );
    }
  }

  /// Construire l'avatar par défaut
  Widget _buildDefaultAvatar(double? size) {
    return Container(
      width: size ?? 80,
      height: size ?? 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.3),
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Icon(Icons.person, size: (size ?? 80) * 0.5, color: Colors.white),
    );
  }

  /// Construire les boutons d'action
  Widget _buildActionButtons({required bool isVertical}) {
    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.favorite,
            color: Colors.pink,
            onTap: widget.onLike,
          ),
          SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.star,
            color: Colors.blue,
            onTap: widget.onSuperLike,
          ),
          SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.visibility,
            color: Colors.grey[600]!,
            onTap: widget.onViewProfile,
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.favorite,
            color: Colors.pink,
            onTap: widget.onLike,
            size: 24,
          ),
          _buildActionButton(
            icon: Icons.star,
            color: Colors.blue,
            onTap: widget.onSuperLike,
            size: 24,
          ),
          _buildActionButton(
            icon: Icons.visibility,
            color: Colors.grey[600]!,
            onTap: widget.onViewProfile,
            size: 24,
          ),
        ],
      );
    }
  }

  /// Construire un bouton d'action individuel
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    double size = 32,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, size: size * 0.5, color: color),
      ),
    );
  }
}
