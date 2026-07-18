import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/feed_bottom_nav.dart';
import '../widgets/feed_header.dart';
import '../widgets/notification_style.dart';
import '../widgets/publication_card.dart';
import 'cahier_de_liaison_screen.dart';
import 'journal_de_vie_screen.dart';
import 'messagerie_famille_screen.dart';
import 'notifications_famille_screen.dart';
import 'profil_screen.dart';

class FeedFamilleScreen extends StatelessWidget {
  const FeedFamilleScreen({super.key});

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
