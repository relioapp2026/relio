import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/feed_bottom_nav.dart';
import '../widgets/feed_header.dart';
import '../widgets/notification_style.dart';
import '../widgets/publication_card.dart';
import 'agenda_pro_screen.dart';
import 'create_publication_screen.dart';
import 'notifications_pro_screen.dart';
import 'nouvelle_communication_screen.dart';
import 'profil_screen.dart';
import 'selection_usager_journal_screen.dart';

class FeedProScreen extends StatelessWidget {
  const FeedProScreen({super.key});

  void _handlePublish(BuildContext context) {
    Navigator.of(context).push(
      fadeRoute(const CreatePublicationScreen()),
    );
  }

  void _handleTabTap(BuildContext context, FeedNavTab tab) {
    switch (tab) {
      case FeedNavTab.accueil:
        break;
      case FeedNavTab.journalDeVie:
        Navigator.of(context).push(
          fadeRoute(const SelectionUsagerJournalScreen()),
        );
      case FeedNavTab.agenda:
        Navigator.of(context).push(
          fadeRoute(const AgendaProScreen()),
        );
      case FeedNavTab.profil:
        Navigator.of(context).push(
          fadeRoute(const ProfilScreen(isPro: true)),
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
              notificationCount: notificationsNonLuesPour(mockProConnecteUid),
              showPublishButton: true,
              onPublishTap: () => _handlePublish(context),
              onMessagesTap: () => Navigator.of(context).push(
                fadeRoute(const NouvelleCommunicationScreen()),
              ),
              onNotificationsTap: () => Navigator.of(context).push(
                fadeRoute(const NotificationsProScreen()),
              ),
            ),
            Expanded(
              child: AuthBackground(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    for (var i = 0; i < mockPublications.length; i++) ...[
                      PublicationCard(
                        authorName: mockPublications[i].auteurNom,
                        avatarColor: mockPublications[i].avatarColor,
                        timeAgo: notificationTimeAgo(mockPublications[i].date),
                        photoCount: mockPublications[i].photos.length,
                        likeCount: mockPublications[i].likes.length,
                        text: mockPublications[i].texte,
                        comments: mockPublications[i]
                            .commentaires
                            .map((c) => PublicationComment(
                                  authorName: c.auteurNom,
                                  avatarColor: c.avatarColor,
                                  text: c.texte,
                                ))
                            .toList(),
                      ),
                      if (i < mockPublications.length - 1) const SizedBox(height: 16),
                    ],
                  ],
                ),
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
