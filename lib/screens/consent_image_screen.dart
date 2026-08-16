import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/app_logo_header.dart';
import '../widgets/auth_background.dart';
import '../widgets/relio_footer.dart';
import 'feed_famille_screen.dart';

/// Écran d'information sur le consentement à l'image, affiché juste après la
/// création de compte famille par code d'invitation — voir CLAUDE.md, section
/// « Consentement image (usagers) ».
///
/// ## ⚠ NEUTRALISÉ en R3b (2026-08-16) — cet écran n'écrit plus rien
///
/// Il présentait trois toggles et écrivait dans `mockUsagersCatalogue`, donc
/// **nulle part** : R2 avait posé `allow write: if false` sur `usagers`. Tant
/// que rien n'était persisté nulle part, l'incohérence restait invisible.
///
/// R3b ouvre un vrai chemin d'écriture, mais sur un **seul** écran :
/// `ConfidentialiteRGPDScreen` (Paramètres). Laisser des toggles ici les
/// rendrait mensongers — un parent validerait ses choix à l'inscription, rien
/// ne serait enregistré, et il les découvrirait tous à zéro dans ses
/// paramètres. Un formulaire qui fait semblant d'enregistrer est pire que pas
/// de formulaire du tout, a fortiori sur un consentement RGPD.
///
/// L'écran conserve donc son rôle d'**information** — il explique ce que Relio
/// fera des photos et rassure sur le non-conditionnement (RGPD art. 7§4) — et
/// renvoie vers l'endroit où le choix se règle vraiment.
///
/// **Migration reportée en amélioration future**, à reprendre au moment de
/// l'étape 2 (photos) si l'onboarding le justifie : recueillir le consentement
/// dès l'inscription n'a de valeur que le jour où des photos circulent.
class ConsentImageScreen extends StatefulWidget {
  const ConsentImageScreen({super.key, required this.usagerId});

  final String usagerId;

  @override
  State<ConsentImageScreen> createState() => _ConsentImageScreenState();
}

class _ConsentImageScreenState extends State<ConsentImageScreen> {
  MockUsager get _usager =>
      mockUsagersCatalogue.firstWhere((u) => u.id == widget.usagerId);

  void _handleContinuer() {
    Navigator.of(context).pushReplacement(fadeRoute(const FeedFamilleScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final prenom = _usager.prenom;

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      const AppLogoHeader(
                        logoSize: 44,
                        titleFontSize: 20,
                        subtitleFontSize: 10,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Autorisation à l\'image',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.marine,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Relio permet aux professionnels de partager des photos du '
                        'quotidien de $prenom : ateliers, sorties, moments de vie en '
                        'unité. C\'est à vous de choisir ce que vous souhaitez autoriser. '
                        'Vous pourrez modifier ce choix à tout moment depuis votre profil.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.marine.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.favorite_border, size: 16, color: AppColors.turquoise),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Que vous acceptiez ou non, vous pourrez utiliser Relio '
                              'normalement : messagerie, agenda, documents et journal de '
                              'vie restent disponibles dans tous les cas.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.marine.withValues(alpha: 0.6),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Encart de renvoi : cet écran informe, il n'enregistre
                      // rien (voir la note de neutralisation en tête de
                      // fichier). Le choix se règle dans les paramètres.
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.turquoise.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.turquoise.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.settings_outlined, size: 18, color: AppColors.turquoise),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vous réglerez vos autorisations dans vos paramètres',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.marine,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rendez-vous dans Profil > Paramètres > Confidentialité '
                                    'et RGPD. Par défaut, aucune photo de $prenom n\'est '
                                    'partagée tant que vous n\'avez rien autorisé.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.marine.withValues(alpha: 0.7),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppColors.turquoise),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Si vous n\'autorisez rien, les professionnels pourront '
                              'tout de même partager des photos des activités de $prenom '
                              'sans qu\'il/elle y apparaisse.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.marine.withValues(alpha: 0.6),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _handleContinuer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.turquoise,
                        ),
                        child: const Text('Continuer'),
                      ),
                    ],
                  ),
                ),
              ),
              const RelioFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
