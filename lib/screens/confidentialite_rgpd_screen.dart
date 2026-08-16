import 'package:flutter/material.dart';

import '../models/consent_image.dart';
import '../models/usager_affichage.dart';
import '../services/auth_service.dart';
import '../services/referentiel_service.dart';
import '../theme/app_colors.dart';
import '../utils/chargement_referentiel.dart';
import '../widgets/auth_background.dart';
import '../widgets/consent_toggle_card.dart';
import '../widgets/etat_referentiel.dart';
import '../widgets/section_label.dart';
import '../widgets/simple_turquoise_header.dart';

/// Informations RGPD et exercice des droits (accès, suppression), et pour
/// une famille, modification du consentement à l'image (voir CLAUDE.md,
/// section « Consentement image (usagers) »).
///
/// Chantier Référentiel / R3b — **le seul écran de l'app qui écrit réellement
/// le consentement image.** L'écran de recueil à l'inscription
/// (`consent_image_screen`) a été neutralisé : il renvoie ici plutôt que
/// d'écrire dans un mock que rien ne persistait.
class ConfidentialiteRGPDScreen extends StatefulWidget {
  const ConfidentialiteRGPDScreen({super.key, required this.isPro});

  /// Le consentement image ne concerne que les comptes famille — un pro n'a
  /// pas d'usager rattaché, et la règle Firestore lui refuse l'écriture.
  final bool isPro;

  @override
  State<ConfidentialiteRGPDScreen> createState() => _ConfidentialiteRGPDScreenState();
}

class _ConfidentialiteRGPDScreenState extends State<ConfidentialiteRGPDScreen> {
  final _service = ReferentielService();

  ChargementReferentiel<List<UsagerAffichage>>? _chargement;

  /// Choix en cours d'édition, par id d'usager. Initialisés depuis Firestore
  /// au chargement, puis modifiés par les toggles jusqu'à l'enregistrement.
  final Map<String, ConsentImage> _choix = {};

  /// Ids en cours d'écriture — désactive le bouton et évite un double envoi.
  final Set<String> _enregistrementEnCours = {};

  @override
  void initState() {
    super.initState();
    if (!widget.isPro) _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = null);

    final famille = AuthService.currentFamilleUser;
    if (famille == null) {
      // Pas de session famille : rien à afficher plutôt qu'un crash.
      setState(() => _chargement = const ChargementReferentiel.succes([]));
      return;
    }

    // Méthode groupée, jamais un appel par usager dans une boucle : une
    // fratrie de deux enfants ne doit pas coûter deux lectures (principe posé
    // en R3a).
    final resultat = await chargerReferentiel(
      () => _service.getUsagersAffichagePourFamille(famille.usagersIds),
    );

    if (!mounted) return;
    setState(() {
      _chargement = resultat;
      _choix
        ..clear()
        ..addEntries(
          (resultat.valeur ?? []).map((u) => MapEntry(u.id, u.consentImage)),
        );
    });
  }

  Future<void> _handleEnregistrerConsentement(UsagerAffichage usager) async {
    final famille = AuthService.currentFamilleUser;
    final consent = _choix[usager.id];
    if (famille == null || consent == null) return;

    setState(() => _enregistrementEnCours.add(usager.id));

    try {
      await _service.enregistrerConsentImage(
        usagerId: usager.id,
        consent: consent,
        saisiParUid: famille.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vos choix pour ${usager.prenom} ont été enregistrés.')),
      );
    } catch (e) {
      if (!mounted) return;
      // Un refus de règle n'est pas une panne réseau : le dire, sinon un
      // périmètre mal borné passerait pour un problème de connexion.
      final refus = ReferentielService.estRefusDePermission(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refus
                ? "Vos droits ne permettent pas de modifier ce choix."
                : "Enregistrement impossible. Vérifiez votre connexion, puis réessayez.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _enregistrementEnCours.remove(usager.id));
    }
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

  /// Bloc « Autorisation à l'image » : une section par enfant rattaché.
  ///
  /// **Fratrie — sections empilées, pas de sélecteur.** Un compte famille peut
  /// porter plusieurs usagers (`usagersIds`, tableau depuis le MVP). Chaque
  /// enfant a ses propres autorisations, et tout doit rester visible d'un seul
  /// défilement : un sélecteur ajouterait un état à gérer et cacherait
  /// l'existence du second enfant derrière une interaction.
  ///
  /// Chaque section a **son propre bouton d'enregistrement**, parce que chaque
  /// enfant est un document Firestore distinct : un bouton unique laisserait
  /// croire à une écriture atomique que la base ne garantit pas.
  List<Widget> _buildBlocConsentement() {
    final chargement = _chargement;
    if (chargement == null) return const [ReferentielEnChargement()];
    if (chargement.enEchec) {
      return [ReferentielEnErreur(resultat: chargement, onReessayer: _charger)];
    }

    final usagers = chargement.valeur ?? const <UsagerAffichage>[];
    if (usagers.isEmpty) {
      return const [
        ReferentielVide(
          message: 'Aucun enfant rattaché à votre compte.',
          icone: Icons.child_care_outlined,
        ),
      ];
    }

    return [
      Text(
        usagers.length > 1
            ? 'Vous pouvez modifier à tout moment les photos que les professionnels '
                'sont autorisés à partager, pour chacun de vos enfants.'
            : 'Vous pouvez modifier à tout moment les photos de ${usagers.first.prenom} '
                'que les professionnels sont autorisés à partager, par type de publication.',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.marine.withValues(alpha: 0.65),
          height: 1.4,
        ),
      ),
      for (final usager in usagers) ..._buildSectionUsager(usager, plusieurs: usagers.length > 1),
    ];
  }

  List<Widget> _buildSectionUsager(UsagerAffichage usager, {required bool plusieurs}) {
    final consent = _choix[usager.id] ?? const ConsentImage();
    final prenom = usager.prenom;
    final enCours = _enregistrementEnCours.contains(usager.id);

    return [
      const SizedBox(height: 20),
      // Le nom n'est affiché qu'en présence d'une fratrie : sur un enfant
      // unique, il répéterait ce que la phrase d'introduction vient de dire.
      if (plusieurs) ...[
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: usager.avatarColor,
              child: Text(
                usager.initiales,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                usager.nomComplet,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.marine,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
      ConsentToggleCard(
        titre: 'Publications individuelles',
        description:
            'Photo de $prenom visible uniquement par vous, dans une '
            'publication qui le/la concerne personnellement.',
        value: consent.individuelle,
        onChanged: (v) => setState(
          () => _choix[usager.id] = consent.copyWith(individuelle: v),
        ),
      ),
      const SizedBox(height: 12),
      ConsentToggleCard(
        // « Unité » et non « groupe » : le champ Firestore reste `groupe`,
        // mais l'app dit « Unité » partout (CLAUDE.md, vocabulaire affiché).
        titre: 'Publications d\'unité',
        description:
            'Photo de $prenom visible par les familles des enfants '
            'présents lors d\'une activité de son unité.',
        value: consent.groupe,
        onChanged: (v) => setState(
          () => _choix[usager.id] = consent.copyWith(groupe: v),
        ),
      ),
      // Pas de toggle « établissement » : depuis R3b, cette portée n'est plus
      // gérée par le consentement image mais par `peutDiffuserEtablissement`
      // (qui restreint les pros pouvant publier) et le texte d'alerte prévu à
      // l'étape 2. Le champ reste dans le schéma, sans écran ni écriture.
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: enCours ? null : () => _handleEnregistrerConsentement(usager),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.turquoise,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: enCours
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(plusieurs ? 'Enregistrer pour $prenom' : 'Enregistrer mes choix'),
      ),
    ];
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
                      ..._buildBlocConsentement(),
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
