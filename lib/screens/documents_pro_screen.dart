import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/document.dart';
import '../models/type_document.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/simple_turquoise_header.dart';
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

/// Liste des documents envoyés par le pro connecté, avec pour chacun le
/// suivi des consultations par les familles concernées.
class DocumentsProScreen extends StatelessWidget {
  const DocumentsProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final documents = mockDocuments
        .where((document) => document.envoyePar == mockProConnecteUid)
        .toList()
      ..sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi));

    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(title: 'Documents envoyés'),
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
              "Vous n'avez envoyé aucun document",
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
    final consultedUids = document.consultations.map((c) => c.uid).toList();
    final nonLu = document.destinatairesUids.length - consultedUids.length;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          fadeRoute(DocumentDetailScreen(document: document, isPro: true)),
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
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            document.type.label,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.more_vert, color: AppColors.marine.withValues(alpha: 0.4)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Envoyé le ${_formatDateHeure(document.dateEnvoi)}',
                style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 10),
              Text(
                'Consulté par ${consultedUids.length}/${document.destinatairesUids.length} familles',
                style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 8),
              _buildAvatarsRow(consultedUids, nonLu),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarsRow(List<String> consultedUids, int nonLu) {
    const maxAvatars = 5;
    final shown = consultedUids.take(maxAvatars).toList();
    final overflow = consultedUids.length - shown.length;
    final slots = shown.length + (overflow > 0 ? 1 : 0);

    return Row(
      children: [
        SizedBox(
          height: 28,
          width: slots == 0 ? 0 : 28 + (slots - 1) * 18,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(left: i * 18, child: _miniAvatar(mockFamilles[shown[i]]?.nom ?? '?')),
              if (overflow > 0)
                Positioned(
                  left: shown.length * 18,
                  child: _miniAvatar('+$overflow', isOverflow: true),
                ),
            ],
          ),
        ),
        const Spacer(),
        if (nonLu > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.roseViolet.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$nonLu non lus',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.roseViolet),
            ),
          ),
        const SizedBox(width: 4),
        Icon(Icons.expand_more, color: AppColors.marine.withValues(alpha: 0.4)),
      ],
    );
  }

  Widget _miniAvatar(String label, {bool isOverflow = false}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        color: isOverflow ? AppColors.marine.withValues(alpha: 0.5) : AppColors.turquoise,
      ),
      alignment: Alignment.center,
      child: Text(
        isOverflow ? label : _initials(label),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.toUpperCase();
  }
}
