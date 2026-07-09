import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/evenement_tile.dart';
import '../widgets/feed_bottom_nav.dart';
import '../widgets/feed_header.dart';
import 'journal_de_vie_screen.dart';
import 'messagerie_famille_screen.dart';
import 'notifications_famille_screen.dart';
import 'profil_screen.dart';

// Donnée factice : usager et unité de la famille connectée, par id stable
// (remplace un filtrage par nom, qui aurait confondu les deux "Emma
// Bernard" du catalogue, voir usager_017/usager_032 dans mock_data.dart).
// _monUniteId est dérivé de l'usager plutôt que recopié en dur, pour ne
// jamais désynchroniser des deux (c'était le cas avant l'unification des
// catalogues d'unités : cette constante pointait vers une unité qui ne
// correspondait pas vraiment à usager_017).
const _monUsagerId = 'usager_017'; // Emma Bernard, Unité Polyvalence
final _monUniteId = findUsagerById(_monUsagerId)!.uniteId;

class AgendaFamilleScreen extends StatelessWidget {
  const AgendaFamilleScreen({super.key});

  void _handleTabTap(BuildContext context, FeedNavTab tab) {
    switch (tab) {
      case FeedNavTab.accueil:
        Navigator.of(context).pop();
      case FeedNavTab.journalDeVie:
        Navigator.of(context).pushReplacement(
          fadeRoute(const JournalDeVieScreen()),
        );
      case FeedNavTab.agenda:
        break;
      case FeedNavTab.profil:
        Navigator.of(context).pushReplacement(
          fadeRoute(const ProfilScreen(isPro: false)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lecture seule : uniquement les événements concernant mon usager
    // (individuelle, par id), son unité (groupe, par id) ou tout
    // l'établissement.
    final evenements = mockEvenements.where((evenement) {
      switch (evenement.type) {
        case VisibiliteType.individuelle:
          return evenement.usagersConcernesIds.contains(_monUsagerId);
        case VisibiliteType.groupe:
          return evenement.uniteConcerneeId == _monUniteId;
        case VisibiliteType.etablissement:
          return true;
      }
    }).toList()
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            FeedHeader(
              notificationCount: notificationsNonLuesPour(mockFamilleConnecteeUid),
              messagesBadgeCount: messagesNonConfirmesPour(mockFamilleConnecteeUid),
              onMessagesTap: () => Navigator.of(context).push(
                fadeRoute(const MessagerieFamilleScreen()),
              ),
              onNotificationsTap: () => Navigator.of(context).push(
                fadeRoute(const NotificationsFamilleScreen()),
              ),
            ),
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
