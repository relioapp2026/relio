import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/document.dart';
import '../models/type_document.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/simple_turquoise_header.dart';
import '../widgets/statut_lecture_pill.dart';
import 'document_detail_screen.dart';

const _mois = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String _formatDateHeure(DateTime date) =>
    '${date.day} ${_mois[date.month - 1]} à ${date.hour.toString().padLeft(2, '0')}h'
    '${date.minute.toString().padLeft(2, '0')}';

IconData _typeIcon(TypeDocument type) => switch (type) {
      TypeDocument.autorisationSortie => Icons.assignment_turned_in_outlined,
      TypeDocument.compteRendu => Icons.description_outlined,
      TypeDocument.information => Icons.info_outline,
      TypeDocument.autre => Icons.insert_drive_file_outlined,
    };

Color _typeColor(TypeDocument type) => switch (type) {
      TypeDocument.autorisationSortie => AppColors.roseViolet,
      TypeDocument.compteRendu => AppColors.turquoise,
      TypeDocument.information => AppColors.marine,
      TypeDocument.autre => Colors.grey.shade600,
    };

/// Liste des documents reçus par la famille connectée, avec son propre
/// statut de lecture (Non consulté / Consulté / Confirmé).
class DocumentsFamilleScreen extends StatelessWidget {
  const DocumentsFamilleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final documents = mockDocuments
        .where((document) => document.destinatairesUids.contains(mockFamilleConnecteeUid))
        .toList()
      ..sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi));

    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(title: 'Documents reçus'),
            Expanded(
              child: AuthBackground(
                child: documents.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: documents.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _DocumentCard(document: documents[index]),
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
              Icons.folder_off_outlined,
              size: 64,
              color: AppColors.turquoise.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              "Vous n'avez reçu aucun document",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.marine),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(document.type);
    final confirmation = document.confirmationsLecture
        .where((c) => c.uid == mockFamilleConnecteeUid)
        .toList();
    final consultation = document.consultations.where((c) => c.uid == mockFamilleConnecteeUid).toList();

    late final StatutLecture statut;
    late final String statutLabel;
    if (confirmation.isNotEmpty) {
      statut = StatutLecture.confirme;
      statutLabel = 'Confirmé';
    } else if (consultation.isNotEmpty) {
      statut = StatutLecture.consulte;
      statutLabel = 'Consulté';
    } else {
      statut = StatutLecture.nonConsulte;
      statutLabel = 'Non consulté';
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          fadeRoute(DocumentDetailScreen(document: document, isPro: false)),
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
                child: Icon(_typeIcon(document.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.titre,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.marine),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Envoyé le ${_formatDateHeure(document.dateEnvoi)}',
                      style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatutLecturePill(statut: statut, label: statutLabel),
            ],
          ),
        ),
      ),
    );
  }
}
