import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/chargement_referentiel.dart';

/// États partagés d'un écran qui lit le référentiel Firestore.
///
/// Chantier Référentiel / R3a. Le catalogue mock était une liste en mémoire,
/// lue instantanément ; Firestore est asynchrone. Chaque écran migré doit donc
/// gérer trois situations qu'il n'avait pas — chargement, erreur, résultat
/// vide — et les dix écrans concernés les affichent de la même façon plutôt
/// que chacun à la sienne.

/// Indicateur de chargement centré, aux couleurs Relio.
class ReferentielEnChargement extends StatelessWidget {
  const ReferentielEnChargement({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: CircularProgressIndicator(color: AppColors.turquoise),
      ),
    );
  }
}

/// Message d'erreur de lecture, avec bouton « Réessayer ».
///
/// Affiche [ChargementReferentiel.messageUtilisateur], qui distingue déjà un
/// refus de règle d'une panne réseau.
class ReferentielEnErreur extends StatelessWidget {
  const ReferentielEnErreur({super.key, required this.resultat, this.onReessayer});

  final ChargementReferentiel resultat;
  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              resultat.refusDePermission
                  ? Icons.lock_outline
                  : Icons.cloud_off_outlined,
              size: 40,
              color: AppColors.marine.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              resultat.messageUtilisateur,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.marine.withValues(alpha: 0.7),
              ),
            ),
            if (onReessayer != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onReessayer,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.turquoise,
                  side: const BorderSide(color: AppColors.turquoise, width: 1.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Résultat vide — jamais une zone blanche muette.
class ReferentielVide extends StatelessWidget {
  const ReferentielVide({super.key, required this.message, this.icone});

  final String message;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icone ?? Icons.groups_outlined,
              size: 40,
              color: AppColors.marine.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.marine.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
