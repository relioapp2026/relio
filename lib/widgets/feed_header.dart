import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// En-tête turquoise des écrans de feed (famille et pro) : logo, messagerie,
/// notifications, et bouton "Publier" optionnel (pro uniquement).
class FeedHeader extends StatelessWidget {
  const FeedHeader({
    super.key,
    this.showPublishButton = false,
    this.notificationCount = 0,
    this.messagesBadgeCount = 0,
    this.onMessagesTap,
    this.onNotificationsTap,
    this.onPublishTap,
  });

  final bool showPublishButton;
  final int notificationCount;
  final int messagesBadgeCount;
  final VoidCallback? onMessagesTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onPublishTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.turquoise,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Image.asset('assets/images/logo/logo_blanc_rose.png', width: 36, height: 36),
          const Spacer(),
          _HeaderIconButton(
            icon: Icons.chat_bubble_outline,
            badgeCount: messagesBadgeCount,
            onTap: onMessagesTap,
          ),
          const SizedBox(width: 18),
          _HeaderIconButton(
            icon: Icons.notifications_outlined,
            badgeCount: notificationCount,
            onTap: onNotificationsTap,
          ),
          if (showPublishButton) ...[
            const SizedBox(width: 18),
            _PublishButton(onTap: onPublishTap),
          ],
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, this.badgeCount = 0, this.onTap});

  final IconData icon;
  final int badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.marine,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.marine.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(icon, color: Colors.white, size: 23),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    decoration: BoxDecoration(
                      color: AppColors.roseViolet,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.turquoise, width: 2),
                    ),
                    child: Text(
                      '$badgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  const _PublishButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.roseViolet,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'Publier',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
