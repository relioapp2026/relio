import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/section_label.dart';
import '../widgets/simple_turquoise_header.dart';

/// Informations RGPD et exercice des droits (accès, suppression).
class ConfidentialiteRGPDScreen extends StatelessWidget {
  const ConfidentialiteRGPDScreen({super.key});

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
