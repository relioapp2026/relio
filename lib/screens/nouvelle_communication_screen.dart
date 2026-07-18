import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/simple_turquoise_header.dart';
import 'create_evenement_screen.dart';
import 'envoyer_document_screen.dart';
import 'envoyer_message_screen.dart';

/// Point d'entrée pro pour envoyer un document ou un message, accessible
/// depuis l'icône messagerie du header.
class NouvelleCommunicationScreen extends StatelessWidget {
  const NouvelleCommunicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(title: 'Nouvelle communication'),
            Expanded(
              child: AuthBackground(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  children: [
                    _ChoixCard(
                      icon: Icons.description_outlined,
                      color: AppColors.turquoise,
                      title: 'Envoyer un document',
                      subtitle: "Autorisation, compte-rendu, information...",
                      onTap: () => Navigator.of(context).push(
                        fadeRoute(const EnvoyerDocumentScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ChoixCard(
                      icon: Icons.chat_bubble_outline,
                      color: AppColors.roseViolet,
                      title: 'Envoyer un message',
                      subtitle: "Un message texte à une famille, un groupe ou tout l'établissement",
                      onTap: () => Navigator.of(context).push(
                        fadeRoute(const EnvoyerMessageScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ChoixCard(
                      icon: Icons.event_outlined,
                      color: AppColors.marine,
                      title: 'Créer un événement',
                      subtitle: 'Un rendez-vous ou une sortie pour un usager, une unité ou tout l\'établissement',
                      onTap: () => Navigator.of(context).push(
                        fadeRoute(const CreateEvenementScreen()),
                      ),
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

class _ChoixCard extends StatelessWidget {
  const _ChoixCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.marine),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.marine.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
