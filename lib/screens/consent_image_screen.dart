import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/consent_image.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/app_logo_header.dart';
import '../widgets/auth_background.dart';
import '../widgets/consent_toggle_card.dart';
import '../widgets/relio_footer.dart';
import 'login_screen.dart';

/// Écran de recueil du consentement à l'image, affiché juste après la
/// création de compte famille par code d'invitation, avant l'accès au reste
/// de l'app — voir CLAUDE.md, section « Consentement image (usagers) », et
/// `docs/brief-technique-consentement-image-invitations.md` (texte v1).
///
/// Trois toggles décochés par défaut : un refus n'empêche jamais d'utiliser
/// Relio, il informe seulement les pros (badge) qu'il ne faut pas rendre
/// [usagerId] visible sur une photo. Au clic sur "Valider mes choix",
/// l'état est écrit dans le mock (`mockUsagersCatalogue`), pas encore dans
/// Firestore.
class ConsentImageScreen extends StatefulWidget {
  const ConsentImageScreen({super.key, required this.usagerId});

  final String usagerId;

  @override
  State<ConsentImageScreen> createState() => _ConsentImageScreenState();
}

class _ConsentImageScreenState extends State<ConsentImageScreen> {
  bool _individuelle = false;
  bool _groupe = false;
  bool _etablissement = false;

  MockUsager get _usager =>
      mockUsagersCatalogue.firstWhere((u) => u.id == widget.usagerId);

  void _handleValider() {
    final index = mockUsagersCatalogue.indexWhere((u) => u.id == widget.usagerId);
    if (index != -1) {
      mockUsagersCatalogue[index] = mockUsagersCatalogue[index].copyWith(
        consentImage: ConsentImage(
          individuelle: _individuelle,
          groupe: _groupe,
          etablissement: _etablissement,
          dateConsentement: DateTime.now(),
          versionTexte: 'v1',
          // Placeholder en attendant Firebase Auth : uid de la famille
          // connectée, convention déjà utilisée ailleurs dans les mocks
          // (voir mockFamilleConnecteeUid).
          saisiPar: mockFamilleConnecteeUid,
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vos choix ont été enregistrés.')),
    );
    Navigator.of(context).pushReplacement(fadeRoute(const LoginScreen()));
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
                      ConsentToggleCard(
                        titre: 'Publications individuelles',
                        description:
                            'Photo de $prenom visible uniquement par vous, dans une '
                            'publication qui le/la concerne personnellement.',
                        value: _individuelle,
                        onChanged: (v) => setState(() => _individuelle = v),
                      ),
                      const SizedBox(height: 12),
                      ConsentToggleCard(
                        titre: 'Publications de groupe',
                        description:
                            'Photo de $prenom visible par les familles des enfants '
                            'présents lors d\'une activité de son unité.',
                        value: _groupe,
                        onChanged: (v) => setState(() => _groupe = v),
                      ),
                      const SizedBox(height: 12),
                      ConsentToggleCard(
                        titre: 'Publications établissement',
                        description:
                            'Photo de $prenom visible par toutes les familles de '
                            'l\'établissement, lors d\'un événement ou d\'un temps fort '
                            'de la vie institutionnelle.',
                        value: _etablissement,
                        onChanged: (v) => setState(() => _etablissement = v),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: AppColors.turquoise),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Si vous ne cochez pas une case, les professionnels pourront '
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
                        onPressed: _handleValider,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.turquoise,
                        ),
                        child: const Text('Valider mes choix'),
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
