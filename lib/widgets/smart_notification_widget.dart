import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cheers/api/notifications_api.dart';
import 'package:cheers/constants/constants.dart';
import 'package:cheers/screens/notifications_screen.dart';

/// Widget de notification intelligent pour l'écran principal
///
/// Affiche:
/// - Badge avec nombre de notifications non lues
/// - Icône spéciale pour notifications intelligentes
/// - Accès direct à l'écran de notifications
class SmartNotificationWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const SmartNotificationWidget({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: NotificationsApi().getNotifications(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        bool hasSmartNotifications = false;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final unreadNotifications = snapshot.data!.docs
              .where((doc) => doc.data()[N_READ] == false)
              .toList();

          unreadCount = unreadNotifications.length;

          // Vérifier s'il y a des notifications intelligentes
          hasSmartNotifications = unreadNotifications.any((doc) {
            final type = doc.data()[N_TYPE] as String?;
            return type == 'high_compatibility' ||
                type == 'nearby_match' ||
                type == 'new_matches';
          });
        }

        return GestureDetector(
          onTap:
              onTap ??
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(),
                  ),
                );
              },
          child: Stack(
            children: [
              // Icône de base avec effet spécial pour notifications intelligentes
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasSmartNotifications
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : null,
                  border: hasSmartNotifications
                      ? Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        )
                      : null,
                ),
                child: child,
              ),

              // Badge de compteur
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: hasSmartNotifications
                          ? Theme.of(context).primaryColor
                          : Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Effet de pulsation pour notifications intelligentes importantes
              if (hasSmartNotifications)
                Positioned.fill(
                  child: _PulsingEffect(color: Theme.of(context).primaryColor),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Effet de pulsation pour attirer l'attention
class _PulsingEffect extends StatefulWidget {
  final Color color;

  const _PulsingEffect({required this.color});

  @override
  State<_PulsingEffect> createState() => _PulsingEffectState();
}

class _PulsingEffectState extends State<_PulsingEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(_animation.value * 0.5),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

/// Widget rapide pour les paramètres de notifications
class NotificationSettingsButton extends StatelessWidget {
  const NotificationSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.of(
              context,
            ).pushNamed('/suggestions-notification-settings');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smart_toy,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Notifications Intelligentes',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
