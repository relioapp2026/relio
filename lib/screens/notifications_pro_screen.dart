import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/evenement.dart';
import '../models/notification.dart';
import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/notification_style.dart';
import '../widgets/simple_turquoise_header.dart';
import 'agenda_pro_screen.dart';
import 'document_detail_screen.dart';
import 'feed_pro_screen.dart';
import 'message_detail_screen.dart';

/// Résout un usager représentatif d'un événement, pour ouvrir son Cahier de
/// liaison depuis une notification (l'agenda pro est désormais consulté par
/// usager, plus de vue globale directement accessible). `null` si
/// l'événement ne concerne aucun usager précis (établissement, ou groupe/
/// individuel sans usager résolvable).
MockUsager? _usagerPourEvenement(Evenement evenement) {
  switch (evenement.type) {
    case VisibiliteType.individuelle:
      if (evenement.usagersConcernesIds.isEmpty) return null;
      return findUsagerById(evenement.usagersConcernesIds.first);
    case VisibiliteType.groupe:
      final usagers = mockUsagersCatalogue.where((u) => u.uniteId == evenement.uniteConcerneeId).toList();
      return usagers.isEmpty ? null : usagers.first;
    case VisibiliteType.etablissement:
      return null;
  }
}

/// Liste des notifications du pro connecté, triées par date décroissante.
class NotificationsProScreen extends StatefulWidget {
  const NotificationsProScreen({super.key});

  @override
  State<NotificationsProScreen> createState() => _NotificationsProScreenState();
}

class _NotificationsProScreenState extends State<NotificationsProScreen> {
  late List<AppNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = mockNotifications.where((n) => n.destinataireId == mockProConnecteUid).toList()
      ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
  }

  void _marquerLu(AppNotification notification) {
    if (notification.lu) return;
    final updated = notification.copyWith(lu: true);
    final indexGlobal = mockNotifications.indexWhere((n) => n.id == updated.id);
    if (indexGlobal != -1) mockNotifications[indexGlobal] = updated;
    setState(() {
      final indexLocal = _notifications.indexWhere((n) => n.id == updated.id);
      if (indexLocal != -1) _notifications[indexLocal] = updated;
    });
  }

  void _handleTap(AppNotification notification) {
    _marquerLu(notification);

    switch (notification.cibleType) {
      case CibleType.document:
        final document = mockDocuments.where((d) => d.id == notification.cibleId).toList();
        if (document.isEmpty) return;
        Navigator.of(context).push(
          fadeRoute(DocumentDetailScreen(document: document.first, isPro: true)),
        );
      case CibleType.message:
        final message = mockMessages.where((m) => m.id == notification.cibleId).toList();
        if (message.isEmpty) return;
        Navigator.of(context).push(
          fadeRoute(MessageDetailScreen(message: message.first)),
        );
      case CibleType.publication:
        Navigator.of(context).push(
          fadeRoute(const FeedProScreen()),
        );
      case CibleType.evenement:
        final evenement = mockEvenements.where((e) => e.id == notification.cibleId).toList();
        if (evenement.isEmpty) return;
        final usager = _usagerPourEvenement(evenement.first);
        if (usager == null) return;
        Navigator.of(context).push(
          fadeRoute(AgendaProScreen(usagerId: usager.id, usagerName: usager.nomComplet)),
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
            const SimpleTurquoiseHeader(title: 'Notifications'),
            Expanded(
              child: AuthBackground(
                child: _notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildTile(_notifications[index]),
                      ),
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
              Icons.notifications_none,
              size: 64,
              color: AppColors.turquoise.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              "Vous n'avez aucune notification",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.marine),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(AppNotification notification) {
    final color = notificationColor(notification.type);

    return Material(
      color: notification.lu ? Colors.white : AppColors.roseViolet.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleTap(notification),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.roseViolet, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.marine.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(notificationIcon(notification.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.titre,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.marine),
                          ),
                        ),
                        if (!notification.lu)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            decoration: const BoxDecoration(color: AppColors.roseViolet, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.description,
                      style: TextStyle(fontSize: 13, color: AppColors.marine.withValues(alpha: 0.7), height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notificationTimeAgo(notification.dateCreation),
                      style: TextStyle(fontSize: 11, color: AppColors.marine.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
