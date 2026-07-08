import 'package:flutter/material.dart';

import '../models/evenement.dart';
import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';

const _mois = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String _formatDate(DateTime date) => '${date.day} ${_mois[date.month - 1]} ${date.year}';

String _formatHeure(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';

/// Carte d'événement d'agenda : type, titre, description, date (+ heure si
/// l'événement n'est pas "toute la journée"). Utilisée par les pages Agenda
/// pro et famille.
class EvenementTile extends StatelessWidget {
  const EvenementTile({super.key, required this.evenement});

  final Evenement evenement;

  String get _typeLabel => switch (evenement.type) {
        VisibiliteType.individuelle => 'Individuelle',
        VisibiliteType.groupe => 'Unité',
        VisibiliteType.etablissement => 'Établissement',
      };

  Color get _typeColor => switch (evenement.type) {
        VisibiliteType.individuelle => AppColors.roseViolet,
        VisibiliteType.groupe => AppColors.turquoise,
        VisibiliteType.etablissement => AppColors.marine,
      };

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
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: _typeColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                _typeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _typeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            evenement.titre,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.marine,
            ),
          ),
          if (evenement.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              evenement.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.marine.withValues(alpha: 0.6),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.turquoise),
              const SizedBox(width: 6),
              Text(
                _formatDate(evenement.dateDebut),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.marine.withValues(alpha: 0.7),
                ),
              ),
              if (!evenement.touteLaJournee && evenement.dateFin != null) ...[
                const SizedBox(width: 14),
                Icon(Icons.access_time, size: 14, color: AppColors.turquoise),
                const SizedBox(width: 6),
                Text(
                  '${_formatHeure(evenement.dateDebut)} - ${_formatHeure(evenement.dateFin!)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.marine.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
