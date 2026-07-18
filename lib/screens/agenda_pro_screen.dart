import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/evenement_tile.dart';
import '../widgets/simple_turquoise_header.dart';
import 'create_evenement_screen.dart';

/// Agenda du pro connecté. Si [usagerId] est renseigné (accès depuis le
/// Cahier de liaison d'un usager), la liste est filtrée aux seuls
/// événements le concernant ; sinon (accès depuis Profil), tous les
/// événements sont affichés, comme pour les Messages/Documents envoyés.
class AgendaProScreen extends StatelessWidget {
  const AgendaProScreen({super.key, this.usagerId, this.usagerName});

  final String? usagerId;
  final String? usagerName;

  void _handleCreer(BuildContext context) {
    Navigator.of(context).push(
      fadeRoute(const CreateEvenementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usagerId = this.usagerId;
    final evenements = (usagerId != null ? evenementsPourUsager(usagerId) : [...mockEvenements])
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            SimpleTurquoiseHeader(title: 'Agenda', subtitle: usagerName),
            Expanded(
              child: Stack(
                children: [
                  AuthBackground(
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
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: FloatingActionButton(
                        backgroundColor: AppColors.roseViolet,
                        onPressed: () => _handleCreer(context),
                        child: const Icon(Icons.add, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ],
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
