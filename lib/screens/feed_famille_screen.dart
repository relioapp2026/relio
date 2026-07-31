import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/feed_bottom_nav.dart';
import '../widgets/feed_header.dart';
import '../widgets/publications_feed.dart';
import 'cahier_de_liaison_screen.dart';
import 'journal_de_vie_screen.dart';
import 'messagerie_famille_screen.dart';
import 'notifications_famille_screen.dart';
import 'profil_screen.dart';

/// Passé en [StatefulWidget] au chantier Publications / étape 1 : le fil est
/// désormais lu sur Firestore et doit porter un état de chargement, ce qu'un
/// [StatelessWidget] ne peut pas faire.
class FeedFamilleScreen extends StatefulWidget {
  const FeedFamilleScreen({super.key});

  @override
  State<FeedFamilleScreen> createState() => _FeedFamilleScreenState();
}

class _FeedFamilleScreenState extends State<FeedFamilleScreen> {
  void _handleTabTap(BuildContext context, FeedNavTab tab) {
    switch (tab) {
      case FeedNavTab.accueil:
        break;
      case FeedNavTab.journalDeVie:
        Navigator.of(context).push(
          fadeRoute(const JournalDeVieScreen()),
        );
      case FeedNavTab.cahierDeLiaison:
        Navigator.of(context).push(
          fadeRoute(
            CahierDeLiaisonScreen(
              usagerId: mockFamilleConnecteeInfo.usagerId,
              usagerName: mockFamilleConnecteeInfo.usagerNomComplet,
            ),
          ),
        );
      case FeedNavTab.profil:
        Navigator.of(context).push(
          fadeRoute(const ProfilScreen(isPro: false)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: const PublicationsFeed(),
              ),
            ),
            FeedBottomNav(
              current: FeedNavTab.accueil,
              onTabTap: (tab) => _handleTabTap(context, tab),
            ),
          ],
        ),
      ),
    );
  }
}
