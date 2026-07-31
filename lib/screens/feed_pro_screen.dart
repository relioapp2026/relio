import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/feed_bottom_nav.dart';
import '../widgets/feed_header.dart';
import '../widgets/publications_feed.dart';
import 'create_publication_screen.dart';
import 'notifications_pro_screen.dart';
import 'nouvelle_communication_screen.dart';
import 'profil_screen.dart';
import 'selection_usager_journal_screen.dart';

class FeedProScreen extends StatefulWidget {
  const FeedProScreen({super.key});

  @override
  State<FeedProScreen> createState() => _FeedProScreenState();
}

class _FeedProScreenState extends State<FeedProScreen> {
  /// Permet de recharger le fil au retour de l'écran de création, sans quoi
  /// une publication tout juste créée n'apparaîtrait qu'au prochain
  /// tirer-pour-actualiser.
  final _feedKey = GlobalKey<PublicationsFeedState>();

  Future<void> _handlePublish(BuildContext context) async {
    await Navigator.of(context).push(
      fadeRoute(const CreatePublicationScreen()),
    );
    await _feedKey.currentState?.rafraichir();
  }

  void _handleTabTap(BuildContext context, FeedNavTab tab) {
    switch (tab) {
      case FeedNavTab.accueil:
        break;
      case FeedNavTab.journalDeVie:
        Navigator.of(context).push(
          fadeRoute(const SelectionUsagerJournalScreen()),
        );
      case FeedNavTab.cahierDeLiaison:
        Navigator.of(context).push(
          fadeRoute(
            const SelectionUsagerJournalScreen(
              destination: SelectionUsagerDestination.cahierDeLiaison,
            ),
          ),
        );
      case FeedNavTab.profil:
        Navigator.of(context).push(
          fadeRoute(const ProfilScreen(isPro: true)),
        );
    }
  }

  Future<void> _handleNotifications(BuildContext context) async {
    await Navigator.of(context).push(
      fadeRoute(const NotificationsProScreen()),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final proUid = AuthService.currentProUser?.uid;
    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            FeedHeader(
              notificationCount: proUid == null ? 0 : notificationsNonLuesPour(proUid),
              showPublishButton: true,
              onPublishTap: () => _handlePublish(context),
              onMessagesTap: () => Navigator.of(context).push(
                fadeRoute(const NouvelleCommunicationScreen()),
              ),
              onNotificationsTap: () => _handleNotifications(context),
            ),
            Expanded(
              child: AuthBackground(
                child: PublicationsFeed(key: _feedKey),
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
