import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// En-tête turquoise simple (flèche retour + titre centré, sous-titre
/// optionnel), utilisé sur les pages secondaires qui n'ont pas besoin du
/// header de feed complet.
class SimpleTurquoiseHeader extends StatelessWidget {
  const SimpleTurquoiseHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = true,
    this.onBack,
  });

  final String title;

  /// Affiché sous le titre en plus petit (ex. nom de l'usager).
  final String? subtitle;

  /// Masque la flèche retour (ex. écran d'accueil famille, accès direct
  /// depuis le footer, sans page de sélection en amont).
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.turquoise,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
