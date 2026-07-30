import 'package:flutter/material.dart';

import '../models/unite.dart';
import '../models/usager_affichage.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/etat_referentiel.dart';
import '../widgets/simple_turquoise_header.dart';

/// Détail d'une unité (lecture seule) : liste des usagers qui la composent.
///
/// Chantier Référentiel / R3a — reste un [StatelessWidget] : c'est
/// `ProfilScreen` qui a déjà chargé les unités et leurs usagers pour afficher
/// « Mes unités », et qui transmet ici le sous-ensemble concerné. Recharger
/// depuis cet écran doublerait les lectures facturées pour la même donnée.
class UniteDetailScreen extends StatelessWidget {
  const UniteDetailScreen({
    super.key,
    required this.unite,
    required this.usagers,
  });

  final Unite unite;

  /// Usagers de cette unité, déjà chargés par l'écran appelant.
  final List<UsagerAffichage> usagers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            SimpleTurquoiseHeader(title: unite.nom),
            Expanded(
              child: AuthBackground(
                child: usagers.isEmpty
                    ? const ReferentielVide(message: 'Aucun usager dans cette unité.')
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        children: [
                          Text(
                            '${usagers.length} usagers',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.marine.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildUsagersCard(),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsagersCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.roseViolet, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.marine.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < usagers.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 68, color: AppColors.marine.withValues(alpha: 0.08)),
            _buildUsagerRow(usagers[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildUsagerRow(UsagerAffichage usager) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: usager.avatarColor,
            child: Text(
              usager.initiales,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              usager.nomComplet,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.marine),
            ),
          ),
          Text(
            '${usager.age} ans',
            style: TextStyle(fontSize: 13, color: AppColors.marine.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}
