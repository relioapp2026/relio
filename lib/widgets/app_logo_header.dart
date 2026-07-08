import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// En-tête logo Relio (icône couleur + wordmark + tagline), utilisé sur les
/// écrans d'authentification (connexion, bienvenue, inscription...).
class AppLogoHeader extends StatelessWidget {
  const AppLogoHeader({
    super.key,
    this.logoSize = 92,
    this.titleFontSize = 36,
    this.subtitleFontSize = 13,
  });

  final double logoSize;
  final double titleFontSize;
  final double subtitleFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo/logo.png',
          width: logoSize,
          height: logoSize,
        ),
        const SizedBox(height: 12),
        Text(
          'Relio',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w800,
            color: AppColors.marine,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Le lien numérique du médico-social',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.marine.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
