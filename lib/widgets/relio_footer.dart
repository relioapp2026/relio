import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Mention de marque discrète, placée en bas d'écran selon deux règles
/// distinctes — voir CLAUDE.md, section « Design system ». Ne pas les fusionner :
///
/// 1. **Écrans d'entrée** (Splash, Welcome, Login, Inscription, Mot de passe
///    oublié) : obligatoire. C'est la première impression de marque, posée
///    avant tout contenu lié à un enfant.
/// 2. **Écrans de contenu vécu autour d'un enfant** (Publication, Événement,
///    Cahier de liaison, et plus tard Messages/Documents/Agenda) : le footer
///    marque ces écrans-là. Il n'apparaît pas sur les écrans utilitaires
///    (formulaires système, sélection, paramètres, authentification hors
///    écrans d'entrée listés en 1).
///
/// Toujours le placer sur un fond clair (AuthBackground ou équivalent) :
/// son marine à 45 % d'opacité est illisible sur le turquoise.
class RelioFooter extends StatelessWidget {
  const RelioFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Relio • créé pour vous avec ❤️',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.marine.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
