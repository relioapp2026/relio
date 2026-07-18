import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/feed_bottom_nav.dart';
import '../widgets/feed_header.dart';
import 'agenda_pro_screen.dart';
import 'aide_support_screen.dart';
import 'cahier_de_liaison_screen.dart';
import 'changer_mot_de_passe_screen.dart';
import 'confidentialite_rgpd_screen.dart';
import 'documents_famille_screen.dart';
import 'documents_pro_screen.dart';
import 'edit_profil_screen.dart';
import 'feed_famille_screen.dart';
import 'feed_pro_screen.dart';
import 'journal_de_vie_screen.dart';
import 'login_screen.dart';
import 'messagerie_famille_screen.dart';
import 'messages_pro_screen.dart';
import 'notifications_famille_screen.dart';
import 'notifications_pro_screen.dart';
import 'notifications_settings_screen.dart';
import 'nouvelle_communication_screen.dart';
import 'selection_usager_journal_screen.dart';
import 'unite_detail_screen.dart';

/// Page Profil : contenu conditionné par le rôle connecté (famille ou pro).
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key, required this.isPro});

  /// Donnée factice simulant le rôle connecté ("famille" ou "pro").
  final bool isPro;

  String get _nom => isPro ? 'Thomas Martin' : 'Marie Dubois';

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.toUpperCase();
  }

  void _handleUniteDetail(BuildContext context, UniteAvecUsagers unite) {
    Navigator.of(context).push(
      fadeRoute(UniteDetailScreen(unite: unite)),
    );
  }

  void _handleDocuments(BuildContext context) {
    Navigator.of(context).push(
      fadeRoute(isPro ? const DocumentsProScreen() : const DocumentsFamilleScreen()),
    );
  }

  void _handleMessagerie(BuildContext context) {
    Navigator.of(context).push(
      fadeRoute(isPro ? const NouvelleCommunicationScreen() : const MessagerieFamilleScreen()),
    );
  }

  void _handleInfosPersonnelles(BuildContext context) {
    Navigator.of(context).push(
      fadeRoute(EditProfilScreen(isPro: isPro)),
    );
  }

  Future<void> _handleDeconnexion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez vous reconnecter pour accéder à votre espace Relio.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.roseViolet),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        fadeRoute(const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _handleTabTap(BuildContext context, FeedNavTab tab) {
    switch (tab) {
      case FeedNavTab.accueil:
        Navigator.of(context).pushAndRemoveUntil(
          fadeRoute(isPro ? const FeedProScreen() : const FeedFamilleScreen()),
          (route) => false,
        );
      case FeedNavTab.journalDeVie:
        Navigator.of(context).pushReplacement(
          fadeRoute(isPro ? const SelectionUsagerJournalScreen() : const JournalDeVieScreen()),
        );
      case FeedNavTab.cahierDeLiaison:
        Navigator.of(context).pushReplacement(
          fadeRoute(
            isPro
                ? const SelectionUsagerJournalScreen(
                    destination: SelectionUsagerDestination.cahierDeLiaison,
                  )
                : CahierDeLiaisonScreen(
                    usagerId: mockFamilleConnecteeInfo.usagerId,
                    usagerName: mockFamilleConnecteeInfo.usagerNomComplet,
                  ),
          ),
        );
      case FeedNavTab.profil:
        break;
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
              notificationCount: notificationsNonLuesPour(isPro ? mockProConnecteUid : mockFamilleConnecteeUid),
              messagesBadgeCount: isPro ? 0 : messagesNonConfirmesPour(mockFamilleConnecteeUid),
              onMessagesTap: () => _handleMessagerie(context),
              onNotificationsTap: () => Navigator.of(context).push(
                fadeRoute(isPro ? const NotificationsProScreen() : const NotificationsFamilleScreen()),
              ),
            ),
            Expanded(
              child: AuthBackground(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    _buildIdentiteCard(context),
                    if (isPro) ...[
                      const SizedBox(height: 20),
                      _sectionCaption('Mes unités'),
                      const SizedBox(height: 8),
                      _buildMesUnitesCard(context),
                    ],
                    const SizedBox(height: 20),
                    _sectionCaption('Mon compte'),
                    const SizedBox(height: 8),
                    _buildMenuGroup([
                      _MenuTile(
                        icon: Icons.person_outline,
                        label: 'Infos personnelles',
                        subtitle: 'Modifier mes informations',
                        onTap: () => _handleInfosPersonnelles(context),
                      ),
                      _MenuTile(
                        icon: Icons.folder_outlined,
                        label: 'Documents',
                        subtitle: isPro ? 'Voir les documents envoyés' : 'Voir les documents reçus',
                        onTap: () => _handleDocuments(context),
                      ),
                      if (isPro)
                        _MenuTile(
                          icon: Icons.chat_bubble_outline,
                          label: 'Messages',
                          subtitle: 'Voir les messages envoyés',
                          onTap: () => Navigator.of(context).push(
                            fadeRoute(const MessagesProScreen()),
                          ),
                        ),
                      if (isPro)
                        _MenuTile(
                          icon: Icons.event_outlined,
                          label: 'Agenda',
                          subtitle: 'Voir tous les événements',
                          onTap: () => Navigator.of(context).push(
                            fadeRoute(const AgendaProScreen()),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 20),
                    _sectionCaption('Paramètres'),
                    const SizedBox(height: 8),
                    _buildMenuGroup([
                      _MenuTile(
                        icon: Icons.lock_outline,
                        label: 'Mot de passe',
                        subtitle: 'Changer mon mot de passe',
                        onTap: () => Navigator.of(context).push(
                          fadeRoute(const ChangerMotDePasseScreen()),
                        ),
                      ),
                      _MenuTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        subtitle: 'Gérer mes notifications',
                        onTap: () => Navigator.of(context).push(
                          fadeRoute(const NotificationsSettingsScreen()),
                        ),
                      ),
                      _MenuTile(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Confidentialité / RGPD',
                        subtitle: 'Gérer mes données personnelles',
                        onTap: () => Navigator.of(context).push(
                          fadeRoute(ConfidentialiteRGPDScreen(isPro: isPro)),
                        ),
                      ),
                      _MenuTile(
                        icon: Icons.help_outline,
                        label: 'Aide & support',
                        subtitle: 'Besoin d\'aide ? Consultez notre FAQ',
                        onTap: () => Navigator.of(context).push(
                          fadeRoute(const AideSupportScreen()),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildMenuGroup([
                      _MenuTile(
                        icon: Icons.logout,
                        label: 'Déconnexion',
                        subtitle: 'Se déconnecter de Relio',
                        iconColor: AppColors.roseViolet,
                        textColor: AppColors.roseViolet,
                        showChevron: false,
                        onTap: () => _handleDeconnexion(context),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            FeedBottomNav(
              current: FeedNavTab.profil,
              onTabTap: (tab) => _handleTabTap(context, tab),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCaption(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.marine.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildIdentiteCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _handleInfosPersonnelles(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.marine.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.turquoise,
              child: Text(
                _initials(_nom),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _nom,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.marine),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RolePill(isPro: isPro),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPro ? 'Éducateur spécialisé' : 'Maman de Lucas',
                    style: TextStyle(fontSize: 13, color: AppColors.marine.withValues(alpha: 0.6)),
                  ),
                  if (isPro) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Établissement Les Horizons',
                      style: TextStyle(fontSize: 13, color: AppColors.marine.withValues(alpha: 0.6)),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.marine.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildMesUnitesCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.marine.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < mockUnitesAvecUsagers.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.marine.withValues(alpha: 0.08)),
            InkWell(
              onTap: () => _handleUniteDetail(context, mockUnitesAvecUsagers[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _IconBadge(icon: Icons.groups_outlined, color: AppColors.turquoise),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mockUnitesAvecUsagers[i].nom,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.marine),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${mockUnitesAvecUsagers[i].usagers.length} usagers',
                            style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.55)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.marine.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuGroup(List<_MenuTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.marine.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 68, color: AppColors.marine.withValues(alpha: 0.08)),
            tiles[i],
          ],
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final color = isPro ? AppColors.turquoise : AppColors.marine;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        isPro ? 'Pro' : 'Famille',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _IconBadge(icon: icon, color: iconColor ?? AppColors.turquoise),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor ?? AppColors.marine),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: (textColor ?? AppColors.marine).withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, color: AppColors.marine.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
