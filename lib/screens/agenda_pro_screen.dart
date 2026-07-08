import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/evenement_tile.dart';
import '../widgets/feed_bottom_nav.dart';
import '../widgets/feed_header.dart';
import 'create_evenement_screen.dart';
import 'notifications_pro_screen.dart';
import 'nouvelle_communication_screen.dart';
import 'profil_screen.dart';
import 'selection_usager_journal_screen.dart';

class AgendaProScreen extends StatelessWidget {
  const AgendaProScreen({super.key});

  void _handleCreer(BuildContext context) {
    Navigator.of(context).push(
      fadeRoute(const CreateEvenementScreen()),
    );
  }

  void _handleTabTap(BuildContext context, FeedNavTab tab) {
    switch (tab) {
      case FeedNavTab.accueil:
        Navigator.of(context).pop();
      case FeedNavTab.journalDeVie:
        Navigator.of(context).pushReplacement(
          fadeRoute(const SelectionUsagerJournalScreen()),
        );
      case FeedNavTab.agenda:
        break;
      case FeedNavTab.profil:
        Navigator.of(context).pushReplacement(
          fadeRoute(const ProfilScreen(isPro: true)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Donnée factice : en production, filtrée côté Firestore par les
    // unites_acces du pro connecté et triée par date_debut croissante.
    final evenements = [...mockEvenements]
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            FeedHeader(
              notificationCount: notificationsNonLuesPour(mockProConnecteUid),
              onMessagesTap: () => Navigator.of(context).push(
                fadeRoute(const NouvelleCommunicationScreen()),
              ),
              onNotificationsTap: () => Navigator.of(context).push(
                fadeRoute(const NotificationsProScreen()),
              ),
            ),
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
            FeedBottomNav(
              current: FeedNavTab.agenda,
              onTabTap: (tab) => _handleTabTap(context, tab),
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
