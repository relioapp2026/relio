import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/evenement_tile.dart';
import '../widgets/simple_turquoise_header.dart';

/// Agenda de l'usager de la famille connectée, accessible depuis sa page
/// Cahier de liaison. Lecture seule : uniquement les événements concernant
/// son usager (individuelle), son unité (groupe) ou tout l'établissement.
class AgendaFamilleScreen extends StatelessWidget {
  const AgendaFamilleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final evenements = evenementsPourUsager(mockFamilleConnecteeInfo.usagerId)
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(title: 'Agenda'),
            Expanded(
              child: AuthBackground(
                child: evenements.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: evenements.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            EvenementTile(evenement: evenements[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64,
              color: AppColors.turquoise.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun événement à venir',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.marine,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
