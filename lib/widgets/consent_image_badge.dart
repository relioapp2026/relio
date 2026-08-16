import 'package:flutter/material.dart';

import '../models/consent_image.dart';
import '../theme/app_colors.dart';

/// Badge informatif (jamais bloquant) affiché à côté d'un usager, au moment de
/// choisir qui figure sur une publication — voir CLAUDE.md, section
/// « Consentement image (usagers) ».
///
/// ## Trois états depuis R3b, et un seul silencieux
///
/// Le badge distingue désormais un **refus explicite** d'une **absence de
/// réponse** ([EtatConsentImage]), question laissée ouverte jusqu'ici dans
/// CLAUDE.md et tranchée par `dateConsentement`. La différence est utile au
/// pro : un refus se respecte, une absence de réponse se relance auprès de la
/// famille.
///
/// [EtatConsentImage.autorise] ne produit **aucun badge** ([SizedBox.shrink]).
/// C'est délibéré : ce composant est une *alerte*, et une unité compte jusqu'à
/// 27 usagers. Pastiller chaque ligne autorisée noierait les deux ou trois qui
/// demandent une attention — l'absence de badge est le signal « rien à
/// signaler ». Pour la consultation d'un état complet, voir `ConsentImageEtat`.
class ConsentImageBadge extends StatelessWidget {
  const ConsentImageBadge({super.key, required this.etat});

  final EtatConsentImage etat;

  @override
  Widget build(BuildContext context) {
    // Orange = refus explicite (même teinte que ConsentImageEtat, pour qu'un
    // pro n'ait pas à réapprendre le code couleur d'un écran à l'autre).
    // Marine atténué = non renseigné : ce n'est pas une faute de la famille,
    // seulement une information manquante. La traiter en orange vif dirait au
    // pro qu'on lui a refusé quelque chose, ce qui serait faux.
    final (color, icone, libelle) = switch (etat) {
      EtatConsentImage.autorise => (null, null, null),
      EtatConsentImage.refuse => (
          Colors.orange.shade800,
          Icons.image_not_supported_outlined,
          "Pas d'autorisation image",
        ),
      EtatConsentImage.nonRenseigne => (
          AppColors.marine.withValues(alpha: 0.55),
          Icons.help_outline,
          'Autorisation non renseignée',
        ),
    };

    if (color == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            libelle!,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
