import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/consent_image.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/consent_toggle_card.dart';
import '../widgets/section_label.dart';
import '../widgets/simple_turquoise_header.dart';

/// Informations RGPD et exercice des droits (accès, suppression), et pour
/// une famille, modification du consentement à l'image (voir CLAUDE.md,
/// section « Consentement image (usagers) »).
class ConfidentialiteRGPDScreen extends StatefulWidget {
  const ConfidentialiteRGPDScreen({super.key, required this.isPro});

  /// Donnée factice simulant le rôle connecté — le consentement image ne
  /// concerne que les comptes famille (un pro n'a pas d'usager rattaché).
  final bool isPro;

  @override
  State<ConfidentialiteRGPDScreen> createState() => _ConfidentialiteRGPDScreenState();
}

class _ConfidentialiteRGPDScreenState extends State<ConfidentialiteRGPDScreen> {
  late final String _usagerId = mockFamilles[mockFamilleConnecteeUid]!.usagerId;

  late bool _individuelle;
  late bool _groupe;
  late bool _etablissement;

  @override
  void initState() {
    super.initState();
    if (!widget.isPro) {
      final consent = mockUsagersCatalogue.firstWhere((u) => u.id == _usagerId).consentImage;
      _individuelle = consent.individuelle;
      _groupe = consent.groupe;
      _etablissement = consent.etablissement;
    }
  }

  String get _prenom => mockUsagersCatalogue.firstWhere((u) => u.id == _usagerId).prenom;

  void _handleEnregistrerConsentement() {
    final index = mockUsagersCatalogue.indexWhere((u) => u.id == _usagerId);
    if (index != -1) {
      mockUsagersCatalogue[index] = mockUsagersCatalogue[index].copyWith(
        consentImage: ConsentImage(
          individuelle: _individuelle,
          groupe: _groupe,
          etablissement: _etablissement,
          dateConsentement: DateTime.now(),
          versionTexte: 'v1',
          saisiPar: mockFamilleConnecteeUid,
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vos choix ont été enregistrés.')),
    );
  }

  void _handlePolitique(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Politique de confidentialité (à venir)')),
    );
  }

  void _handleTelechargerDonnees(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Votre demande a été enregistrée. Vous recevrez vos données par email.'),
      ),
    );
  }

  Future<void> _handleSupprimerCompte(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demander la suppression de mon compte ?'),
        content: const Text(
          'Cette demande sera transmise à votre établissement, qui procédera à la suppression '
          'de vos données conformément au RGPD.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirmer la demande'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Votre demande de suppression a bien été enregistrée.')),
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
            const SimpleTurquoiseHeader(title: 'Confidentialité et RGPD'),
            Expanded(
              child: AuthBackground(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  children: [
                    Text(
                      "Relio traite les informations de votre enfant et de votre famille "
                      'conformément au Règlement Général sur la Protection des Données (RGPD). '
                      'Ces informations sont utilisées uniquement dans le cadre du suivi proposé '
                      "par votre établissement et ne sont partagées avec aucun tiers sans votre "
                      'consentement.',
                      style: TextStyle(fontSize: 14, color: AppColors.marine.withValues(alpha: 0.8), height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _handlePolitique(context),
                      child: Text(
                        'Consulter notre politique de confidentialité',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.turquoise,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SectionLabel('Mes droits'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _handleTelechargerDonnees(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.turquoise,
                        backgroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: AppColors.turquoise, width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Télécharger mes données'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _handleSupprimerCompte(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: Colors.red, width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Demander la suppression de mon compte'),
                    ),
                    if (!widget.isPro) ...[
                      const SizedBox(height: 24),
                      const SectionLabel('Autorisation à l\'image'),
                      const SizedBox(height: 8),
                      Text(
                        'Vous pouvez modifier à tout moment les photos de $_prenom que '
                        'les professionnels sont autorisés à partager, par type de '
                        'publication.',
                        style: TextStyle(fontSize: 13, color: AppColors.marine.withValues(alpha: 0.65), height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      ConsentToggleCard(
                        titre: 'Publications individuelles',
                        description:
                            'Photo de $_prenom visible uniquement par vous, dans une '
                            'publication qui le/la concerne personnellement.',
                        value: _individuelle,
                        onChanged: (v) => setState(() => _individuelle = v),
                      ),
                      const SizedBox(height: 12),
                      ConsentToggleCard(
                        titre: 'Publications de groupe',
                        description:
                            'Photo de $_prenom visible par les familles des enfants '
                            'présents lors d\'une activité de son unité.',
                        value: _groupe,
                        onChanged: (v) => setState(() => _groupe = v),
                      ),
                      const SizedBox(height: 12),
                      ConsentToggleCard(
                        titre: 'Publications établissement',
                        description:
                            'Photo de $_prenom visible par toutes les familles de '
                            'l\'établissement, lors d\'un événement ou d\'un temps fort '
                            'de la vie institutionnelle.',
                        value: _etablissement,
                        onChanged: (v) => setState(() => _etablissement = v),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _handleEnregistrerConsentement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.turquoise,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Enregistrer mes choix'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
