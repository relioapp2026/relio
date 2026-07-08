import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/feed_bottom_nav.dart';
import '../widgets/feed_header.dart';
import '../widgets/publication_card.dart';
import 'agenda_famille_screen.dart';
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
      case FeedNavTab.agenda:
        Navigator.of(context).push(
          fadeRoute(const AgendaFamilleScreen()),
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
                    PublicationCard(
                      authorName: 'Marie Dubois',
                      avatarColor: AppColors.roseViolet,
                      timeAgo: 'il y a 2h',
                      photoCount: 3,
                      likeCount: 24,
                      text:
                          'Atelier peinture ce matin ! Les enfants ont laissé libre '
                          'cours à leur imagination. De magnifiques créations hautes '
                          'en couleurs 🎨✨',
                      comments: const [
                        PublicationComment(
                          authorName: 'Thomas Martin',
                          avatarColor: AppColors.turquoise,
                          text: 'Waouh ! Ils sont vraiment talentueux 👏',
                        ),
                        PublicationComment(
                          authorName: 'Sophie Leroy',
                          avatarColor: AppColors.marine,
                          text: 'Les couleurs sont superbes ! Bravo à tous 😊',
                        ),
                        PublicationComment(
                          authorName: 'Julien Petit',
                          avatarColor: AppColors.roseViolet,
                          text: 'Quelle belle énergie créative !',
                        ),
                        PublicationComment(
                          authorName: 'Nathalie Moreau',
                          avatarColor: AppColors.turquoise,
                          text: 'Ça leur fait tellement de bien de créer.',
                        ),
                        PublicationComment(
                          authorName: 'Camille Bernard',
                          avatarColor: AppColors.marine,
                          text: 'Merci pour le partage, ça fait plaisir à voir !',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PublicationCard(
                      authorName: 'Camille Bernard',
                      avatarColor: AppColors.marine,
                      timeAgo: 'il y a 5h',
                      photoCount: 1,
                      likeCount: 18,
                      text:
                          'Jardinage au programme cet après-midi ! Plantation de '
                          'fleurs et découverte de la nature 🌱🌻',
                      comments: const [
                        PublicationComment(
                          authorName: 'Julien Petit',
                          avatarColor: AppColors.roseViolet,
                          text: 'Super activité en plein air ! 🌿',
                        ),
                        PublicationComment(
                          authorName: 'Nathalie Moreau',
                          avatarColor: AppColors.turquoise,
                          text: 'Ça fait du bien de voir les enfants dehors ! ☀️',
                        ),
                        PublicationComment(
                          authorName: 'Marie Dubois',
                          avatarColor: AppColors.roseViolet,
                          text: 'Quelle belle idée de sortie !',
                        ),
                      ],
                    ),
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
