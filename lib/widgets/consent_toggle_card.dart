import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Carte "case à cocher" pour un type de publication (individuelle / groupe
/// / établissement), utilisée par l'écran de recueil du consentement image
/// (inscription) et par Profil > Paramètres > Confidentialité/RGPD (voir
/// CLAUDE.md, section « Consentement image (usagers) »).
class ConsentToggleCard extends StatelessWidget {
  const ConsentToggleCard({
    super.key,
    required this.titre,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String titre;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.marine),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(fontSize: 13, color: AppColors.marine.withValues(alpha: 0.65), height: 1.4),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Checkbox(
                value: value,
                activeColor: AppColors.roseViolet,
                onChanged: (v) => onChanged(v ?? false),
              ),
              Text(
                'J\'autorise',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.marine),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
