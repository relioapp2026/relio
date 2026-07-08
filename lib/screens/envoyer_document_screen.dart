import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/document.dart';
import '../models/type_document.dart';
import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/dashed_border_painter.dart';
import '../widgets/fichier_icon.dart';
import '../widgets/section_label.dart';
import '../widgets/simple_turquoise_header.dart';
import '../widgets/visibilite_selector.dart';

List<String> _resolveDestinataires(VisibiliteSelection selection) {
  switch (selection.type) {
    case VisibiliteType.individuelle:
      final usager = selection.usagerId;
      if (usager == null) return const [];
      final uid = familleUidPourUsager(usager);
      return uid == null ? const [] : [uid];
    case VisibiliteType.groupe:
      return selection.usagersPresentsIds.map(familleUidPourUsager).whereType<String>().toList();
    case VisibiliteType.etablissement:
      return mockFamilles.keys.toList();
  }
}

/// Formulaire d'envoi d'un document (pro) : portée, type, titre, description
/// et fichier joint (PDF/PNG/JPEG). Alimente `mockDocuments`.
class EnvoyerDocumentScreen extends StatefulWidget {
  const EnvoyerDocumentScreen({super.key});

  @override
  State<EnvoyerDocumentScreen> createState() => _EnvoyerDocumentScreenState();
}

class _EnvoyerDocumentScreenState extends State<EnvoyerDocumentScreen> {
  VisibiliteSelection _visibilite = const VisibiliteSelection(type: VisibiliteType.individuelle);
  TypeDocument _type = TypeDocument.autorisationSortie;
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _fichierNom;
  String _fichierType = '';

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  static const _pdfTypeGroup = XTypeGroup(
    label: 'PDF',
    extensions: ['pdf'],
    mimeTypes: ['application/pdf'],
    uniformTypeIdentifiers: ['com.adobe.pdf'],
  );

  // Wildcards (mimeTypes/uniformTypeIdentifiers/webWildCards) pour accepter
  // tout type d'image (y compris HEIC/HEIF des iPhone), pas seulement
  // PNG/JPEG. La liste d'extensions reste un filet de sécurité pour les
  // plateformes desktop qui ne supportent que les extensions.
  static const _imageTypeGroup = XTypeGroup(
    label: 'Image',
    extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif', 'tiff', 'tif'],
    mimeTypes: ['image/*'],
    uniformTypeIdentifiers: ['public.image'],
    webWildCards: ['image/*'],
  );

  Future<void> _pickFile() async {
    final file = await openFile(acceptedTypeGroups: const [_pdfTypeGroup, _imageTypeGroup]);
    if (file == null) return;
    final extension = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
    setState(() {
      _fichierNom = file.name;
      _fichierType = extension;
    });
  }

  void _handleEnvoyer() {
    if (_visibilite.type == VisibiliteType.individuelle && _visibilite.usagerId == null) {
      _showError('Merci de sélectionner un usager');
      return;
    }
    if (_visibilite.type == VisibiliteType.groupe && _visibilite.uniteId == null) {
      _showError('Merci de sélectionner une unité');
      return;
    }
    if (_titreController.text.trim().isEmpty) {
      _showError('Merci de renseigner un titre');
      return;
    }
    if (_fichierNom == null) {
      _showError('Merci de sélectionner un fichier');
      return;
    }

    final destinataires = _resolveDestinataires(_visibilite);
    if (destinataires.isEmpty) {
      _showError('Aucune famille concernée par cette sélection');
      return;
    }

    mockDocuments.insert(
      0,
      Document(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        titre: _titreController.text.trim(),
        type: _type,
        description: _descriptionController.text.trim(),
        portee: _visibilite.type,
        usagerNom: _visibilite.type == VisibiliteType.individuelle ? _visibilite.usagerId : null,
        uniteNom: _visibilite.type == VisibiliteType.groupe ? _visibilite.uniteId : null,
        envoyePar: mockProConnecteUid,
        envoyeParNom: mockProConnecteNom,
        dateEnvoi: DateTime.now(),
        fichierUrl: _fichierNom!,
        fichierType: _fichierType,
        destinatairesUids: destinataires,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document envoyé (à brancher sur Storage/Firestore)')),
    );
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.turquoise,
        body: SafeArea(
          child: Column(
            children: [
              const SimpleTurquoiseHeader(title: 'Envoyer un document'),
              Expanded(
                child: AuthBackground(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VisibiliteSelector(
                          typeLabel: 'Portée du document',
                          mockUsagers: mockUsagersAvecFamilles,
                          mockUnites: mockUnitesAvecFamilles,
                          onChanged: (value) => setState(() => _visibilite = value),
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Type de document'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final type in TypeDocument.values) _buildTypeChip(type),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Titre'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titreController,
                          style: TextStyle(color: AppColors.marine),
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Description'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          style: TextStyle(color: AppColors.marine),
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Fichier'),
                        const SizedBox(height: 8),
                        _buildFichierField(),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _handleEnvoyer,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseViolet),
                          child: const Text('Envoyer'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(TypeDocument type) {
    final isSelected = _type == type;
    return ChoiceChip(
      label: Text(type.label),
      selected: isSelected,
      onSelected: (_) => setState(() => _type = type),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      selectedColor: AppColors.turquoise,
      backgroundColor: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: AppColors.turquoise, width: 1.2)),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.turquoise,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildFichierField() {
    if (_fichierNom == null) {
      return InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: DashedBorderPainter(color: AppColors.turquoise, radius: 14),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.upload_file_outlined, color: AppColors.turquoise, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    'Choisir un fichier (PDF, PNG, JPEG)',
                    style: TextStyle(color: AppColors.turquoise, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(fichierIcon(_fichierType), color: AppColors.turquoise),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _fichierNom!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.marine, fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _fichierNom = null;
              _fichierType = '';
            }),
            child: Icon(Icons.close, color: AppColors.marine.withValues(alpha: 0.5), size: 20),
          ),
        ],
      ),
    );
  }
}
