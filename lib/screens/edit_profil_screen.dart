import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/section_label.dart';
import '../widgets/simple_turquoise_header.dart';

const _liensUsager = ['Maman', 'Papa', 'Tuteur légal', 'Autre'];

/// Formulaire de modification des infos personnelles, contenu conditionné
/// par le rôle connecté (famille ou pro).
class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key, required this.isPro});

  final bool isPro;

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _prenomController = TextEditingController(
    text: widget.isPro ? 'Thomas' : 'Marie',
  );
  late final _nomController = TextEditingController(
    text: widget.isPro ? 'Martin' : 'Dubois',
  );
  late final _fonctionController = TextEditingController(
    text: 'Éducateur spécialisé',
  );
  String _lienUsager = 'Maman';

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _fonctionController.dispose();
    super.dispose();
  }

  String _initials() {
    final prenom = _prenomController.text.trim();
    final nom = _nomController.text.trim();
    final letters = [prenom, nom].where((p) => p.isNotEmpty).map((p) => p[0]).join();
    return letters.toUpperCase();
  }

  void _handlePhotoTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sélection de photo (à venir)')),
    );
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informations enregistrées (à brancher sur Firestore)')),
    );
    Navigator.of(context).pop();
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
              const SimpleTurquoiseHeader(title: 'Modifier mes informations'),
              Expanded(
                child: AuthBackground(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: _buildPhotoPicker()),
                          const SizedBox(height: 20),
                          const SectionLabel('Prénom'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _prenomController,
                            style: TextStyle(color: AppColors.marine),
                            onChanged: (_) => setState(() {}),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty) ? 'Merci de renseigner votre prénom' : null,
                          ),
                          const SizedBox(height: 20),
                          const SectionLabel('Nom'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nomController,
                            style: TextStyle(color: AppColors.marine),
                            onChanged: (_) => setState(() {}),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty) ? 'Merci de renseigner votre nom' : null,
                          ),
                          const SizedBox(height: 20),
                          if (widget.isPro) ...[
                            const SectionLabel('Fonction'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _fonctionController,
                              style: TextStyle(color: AppColors.marine),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty) ? 'Merci de renseigner votre fonction' : null,
                            ),
                            const SizedBox(height: 20),
                            const SectionLabel('Établissement'),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: 'Établissement Les Horizons',
                              enabled: false,
                              style: TextStyle(color: AppColors.marine.withValues(alpha: 0.6)),
                              decoration: const InputDecoration(
                                suffixIcon: Icon(Icons.lock_outline, size: 18),
                              ),
                            ),
                          ] else ...[
                            const SectionLabel('Lien avec l\'usager'),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _lienUsager,
                              style: TextStyle(color: AppColors.marine),
                              icon: const Icon(Icons.expand_more, color: AppColors.turquoise),
                              items: _liensUsager
                                  .map((lien) => DropdownMenuItem(value: lien, child: Text(lien)))
                                  .toList(),
                              onChanged: (value) => setState(() => _lienUsager = value ?? _lienUsager),
                            ),
                          ],
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _handleSave,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.turquoise),
                            child: const Text('Enregistrer les modifications'),
                          ),
                        ],
                      ),
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

  Widget _buildPhotoPicker() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: AppColors.turquoise,
          child: Text(
            _initials(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
          ),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Material(
            color: AppColors.roseViolet,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _handlePhotoTap,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
