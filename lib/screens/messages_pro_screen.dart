import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/message.dart';
import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/simple_turquoise_header.dart';
import 'envoyer_message_screen.dart';
import 'message_detail_screen.dart';

const _mois = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String _formatDateHeure(DateTime date) =>
    '${date.day} ${_mois[date.month - 1]} à ${date.hour.toString().padLeft(2, '0')}h'
    '${date.minute.toString().padLeft(2, '0')}';

String _porteeLabel(VisibiliteType type) => switch (type) {
      VisibiliteType.individuelle => 'Individuel',
      VisibiliteType.groupe => 'Unité',
      VisibiliteType.etablissement => 'Établissement',
    };

Color _porteeColor(VisibiliteType type) => switch (type) {
      VisibiliteType.individuelle => AppColors.roseViolet,
      VisibiliteType.groupe => AppColors.turquoise,
      VisibiliteType.etablissement => AppColors.marine,
    };

/// Liste des messages envoyés par le pro connecté, avec pour chacun le
/// suivi des consultations par les familles concernées. Si [usagerId] est
/// renseigné (accès depuis le Cahier de liaison d'un usager), la liste est
/// filtrée aux seuls messages le concernant plutôt qu'à tous les messages
/// envoyés par le pro.
class MessagesProScreen extends StatelessWidget {
  const MessagesProScreen({super.key, this.usagerId, this.usagerNom});

  final String? usagerId;
  final String? usagerNom;

  @override
  Widget build(BuildContext context) {
    final usagerId = this.usagerId;
    final messages = (usagerId != null
        ? messagesPourUsager(usagerId)
        : mockMessages.where((message) => message.expediteurId == mockProConnecteUid).toList())
      ..sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi));

    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            SimpleTurquoiseHeader(
              title: usagerNom != null ? 'Messagerie' : 'Messages envoyés',
              subtitle: usagerNom,
            ),
            Expanded(
              child: Stack(
                children: [
                  AuthBackground(
                    child: messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            itemCount: messages.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) => _MessageCard(message: messages[index]),
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
                        onPressed: () => Navigator.of(context).push(
                          fadeRoute(const EnvoyerMessageScreen()),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ],
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
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.turquoise.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              usagerNom != null ? 'Aucun message pour le moment' : "Vous n'avez envoyé aucun message",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.marine),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final color = _porteeColor(message.portee);
    final consultes = message.consultations.length;
    final total = message.destinatairesUids.length;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          fadeRoute(MessageDetailScreen(message: message)),
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _porteeLabel(message.portee),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                  const Spacer(),
                  Text(
                    _formatDateHeure(message.dateEnvoi),
                    style: TextStyle(fontSize: 11, color: AppColors.marine.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.contenu,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: AppColors.marine.withValues(alpha: 0.85), height: 1.3),
              ),
              const SizedBox(height: 10),
              Text(
                'Consulté par $consultes/$total familles',
                style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
