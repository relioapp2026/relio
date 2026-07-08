import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/consultation.dart';
import '../models/document.dart';
import '../models/type_document.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/fichier_icon.dart';
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

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
  return letters.toUpperCase();
}

/// Détail d'un document : côté pro, résumé + suivi des consultations et
/// confirmations de lecture famille par famille ; côté famille, résumé +
/// case "j'ai bien lu et pris connaissance" (une consultation est
/// enregistrée automatiquement à l'ouverture de la page).
class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key, required this.document, required this.isPro});

  final Document document;
  final bool isPro;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late Document _document;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    if (!widget.isPro) {
      _enregistrerConsultation();
    }
  }

  void _enregistrerConsultation() {
    final dejaConsulte = _document.consultations.any((c) => c.uid == mockFamilleConnecteeUid);
    if (dejaConsulte) return;
    _remplacerDocument(
      _document.copyWith(
        consultations: [
          ..._document.consultations,
          Consultation(uid: mockFamilleConnecteeUid, dateConsultation: DateTime.now()),
        ],
      ),
    );
  }

  void _handleConfirmation() {
    final dejaConfirme = _document.confirmationsLecture.any((c) => c.uid == mockFamilleConnecteeUid);
    if (dejaConfirme) return;
    setState(() {
      _remplacerDocument(
        _document.copyWith(
          confirmationsLecture: [
            ..._document.confirmationsLecture,
            ConfirmationLecture(uid: mockFamilleConnecteeUid, dateConfirmation: DateTime.now()),
          ],
        ),
      );
    });
  }

  void _remplacerDocument(Document updated) {
    final index = mockDocuments.indexWhere((d) => d.id == updated.id);
    if (index != -1) mockDocuments[index] = updated;
    _document = updated;
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(_document.type);

    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(title: 'Détail du document'),
            Expanded(
              child: AuthBackground(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    _buildEnteteCard(color),
                    const SizedBox(height: 20),
                    const SectionLabel('Résumé'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
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
                      child: Text(
                        _document.description,
                        style: TextStyle(fontSize: 14, color: AppColors.marine.withValues(alpha: 0.8), height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel('Document joint'),
                    const SizedBox(height: 8),
                    _buildFichierCard(),
                    const SizedBox(height: 20),
                    if (widget.isPro) ...[
                      const SectionLabel('Consultations par les familles'),
                      const SizedBox(height: 8),
                      _buildConsultationsCard(),
                    ] else
                      _buildConfirmationCard(),
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
            child: Icon(_typeIcon(_document.type), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _document.titre,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.marine),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _document.type.label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Envoyé par ${_document.envoyeParNom}',
                  style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Le ${_formatDateHeure(_document.dateEnvoi)}',
                  style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTelecharger(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Téléchargement du document (à brancher sur Firebase Storage)')),
    );
  }

  Widget _buildFichierCard() {
    return Builder(
      builder: (context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _handleTelecharger(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.roseViolet, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(fichierIcon(_document.fichierType), color: AppColors.roseViolet),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _document.fichierUrl,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.marine, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.download_outlined, color: AppColors.roseViolet),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationCard() {
    final confirmation = _confirmationDe(mockFamilleConnecteeUid);
    final confirme = confirmation != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.roseViolet.withValues(alpha: 0.14),
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
              Checkbox(
                value: confirme,
                activeColor: AppColors.roseViolet,
                onChanged: confirme ? null : (value) => _handleConfirmation(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    "J'ai bien lu et pris connaissance de ce document",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.marine),
                  ),
                ),
              ),
            ],
          ),
          if (confirme) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(
                'Confirmé le ${_formatDateHeure(confirmation.dateConfirmation)}',
                style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.55)),
              ),
            ),
          ],
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
          for (var i = 0; i < _document.destinatairesUids.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 68, color: AppColors.marine.withValues(alpha: 0.08)),
            _buildFamilleRow(_document.destinatairesUids[i]),
          ],
        ],
      ),
    );
  }

  Consultation? _consultationDe(String uid) {
    for (final consultation in _document.consultations) {
      if (consultation.uid == uid) return consultation;
    }
    return null;
  }

  ConfirmationLecture? _confirmationDe(String uid) {
    for (final confirmation in _document.confirmationsLecture) {
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
