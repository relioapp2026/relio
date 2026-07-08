import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/feed_bottom_nav.dart';
import '../widgets/feed_header.dart';
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
