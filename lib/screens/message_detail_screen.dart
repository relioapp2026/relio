import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/consultation.dart';
import '../models/message.dart';
import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/section_label.dart';
import '../widgets/simple_turquoise_header.dart';
import '../widgets/statut_lecture_pill.dart';

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

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
  return letters.toUpperCase();
}

/// Suivi d'un message envoyé (pro) : contenu + consultations et
/// confirmations de lecture famille par famille, même principe que
/// [DocumentDetailScreen].
class MessageDetailScreen extends StatelessWidget {
  const MessageDetailScreen({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final color = _porteeColor(message.portee);

    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(title: 'Détail du message'),
            Expanded(
              child: AuthBackground(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    _buildEnteteCard(color),
                    const SizedBox(height: 20),
                    const SectionLabel('Consultations par les familles'),
                    const SizedBox(height: 8),
                    _buildConsultationsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnteteCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message.contenu,
            style: TextStyle(fontSize: 15, color: AppColors.marine, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Envoyé par ${message.expediteurNom}',
            style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 2),
          Text(
            'Le ${_formatDateHeure(message.dateEnvoi)}',
            style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          for (var i = 0; i < message.destinatairesUids.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 68, color: AppColors.marine.withValues(alpha: 0.08)),
            _buildFamilleRow(message.destinatairesUids[i]),
          ],
        ],
      ),
    );
  }

  Consultation? _consultationDe(String uid) {
    for (final consultation in message.consultations) {
      if (consultation.uid == uid) return consultation;
    }
    return null;
  }

  ConfirmationLecture? _confirmationDe(String uid) {
    for (final confirmation in message.confirmationsLecture) {
      if (confirmation.uid == uid) return confirmation;
    }
    return null;
  }

  Widget _buildFamilleRow(String uid) {
    final famille = mockFamilles[uid];
    final nom = famille?.nom ?? 'Famille';
    final usagerNom = famille?.usagerNom ?? '';
    final confirmation = _confirmationDe(uid);
    final consultation = _consultationDe(uid);

    late final StatutLecture statut;
    late final String statutLabel;
    if (confirmation != null) {
      statut = StatutLecture.confirme;
      statutLabel = 'Confirmé le ${_formatDateHeure(confirmation.dateConfirmation)}';
    } else if (consultation != null) {
      statut = StatutLecture.consulte;
      statutLabel = 'Consulté';
    } else {
      statut = StatutLecture.nonConsulte;
      statutLabel = 'Non consulté';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.turquoise,
            child: Text(
              _initials(nom),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nom${usagerNom.isNotEmpty ? ' ($usagerNom)' : ''}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.marine),
                ),
                const SizedBox(height: 4),
                StatutLecturePill(statut: statut, label: statutLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
