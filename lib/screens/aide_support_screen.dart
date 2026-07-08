import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/simple_turquoise_header.dart';

class _Faq {
  const _Faq({required this.question, required this.reponse});

  final String question;
  final String reponse;
}

const _faqs = [
  _Faq(
    question: 'Qui peut voir mes publications ?',
    reponse:
        'Une publication individuelle est visible par la famille concernée et les professionnels '
        "autorisés. Une publication de groupe est visible par les familles et professionnels de "
        "l'unité concernée. Une publication d'établissement est visible par tous.",
  ),
  _Faq(
    question: 'Comment consulter le journal de vie de mon enfant ?',
    reponse:
        'Depuis l\'accueil, appuyez sur l\'icône « Journal de vie » dans le menu du bas pour '
        'retrouver toutes les publications le concernant.',
  ),
  _Faq(
    question: 'Comment modifier mes informations personnelles ?',
    reponse: 'Rendez-vous dans Profil > Infos personnelles pour modifier votre prénom, nom et photo.',
  ),
  _Faq(
    question: "Comment fonctionne le code d'invitation ?",
    reponse:
        "Le code d'invitation vous est transmis par votre établissement lors de l'inscription : "
        'il permet de rattacher votre compte au bon usager.',
  ),
  _Faq(
    question: 'Que faire si j\'ai oublié mon mot de passe ?',
    reponse:
        'Depuis l\'écran de connexion, appuyez sur « Mot de passe oublié » pour recevoir un lien '
        'de réinitialisation par email.',
  ),
];

/// Foire aux questions et contact du support.
class AideSupportScreen extends StatelessWidget {
  const AideSupportScreen({super.key});

  void _handleContact(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ouverture de votre application mail (à venir)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(title: 'Aide et support'),
            Expanded(
              child: AuthBackground(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  children: [
                    for (final faq in _faqs) ...[
                      _FaqTile(faq: faq),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _handleContact(context),
                      child: const Text('Nous contacter par email'),
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

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq});

  final _Faq faq;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.marine.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.turquoise,
          collapsedIconColor: AppColors.turquoise,
          title: Text(
            faq.question,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.marine),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.topLeft,
          children: [
            Text(
              faq.reponse,
              style: TextStyle(fontSize: 13, color: AppColors.marine.withValues(alpha: 0.7), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
