import 'package:flutter/material.dart';

import '../models/publication.dart';
import '../models/visibilite_type.dart';
import '../services/publication_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/chargement_perimetre_pro.dart';
import '../widgets/relio_footer.dart';
import '../widgets/section_label.dart';
import '../widgets/simple_turquoise_header.dart';
import '../widgets/visibilite_selector.dart';

class CreatePublicationScreen extends StatefulWidget {
  const CreatePublicationScreen({super.key, this.publicationAModifier});

  /// Non `null` en mode édition (menu « ⋮ » → *Modifier*).
  ///
  /// Seul le texte est modifiable : la portée, l'unité et les usagers
  /// concernés sont figés à la création — les règles Firestore les rendent
  /// immuables, et changer la portée d'une publication déjà lue par des
  /// familles reviendrait à la diffuser rétroactivement à d'autres.
  final Publication? publicationAModifier;

  @override
  State<CreatePublicationScreen> createState() => _CreatePublicationScreenState();
}

class _CreatePublicationScreenState extends State<CreatePublicationScreen> {
  final _service = PublicationService();

  VisibiliteSelection _visibilite = const VisibiliteSelection(type: VisibiliteType.individuelle);

  final _messageController = TextEditingController();

  /// Anti double-clic : sans ça, deux appuis rapides créent deux publications.
  bool _envoiEnCours = false;

  bool get _modeEdition => widget.publicationAModifier != null;

  @override
  void initState() {
    super.initState();
    final publication = widget.publicationAModifier;
    if (publication != null) {
      _messageController.text = publication.texte;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  /// Valide la saisie, puis écrit réellement dans Firestore.
  ///
  /// La validation porte sur les **ids** de [VisibiliteSelection], jamais sur
  /// les libellés affichés — ce sont eux qui partent en base.
  Future<void> _handlePublish() async {
    if (_envoiEnCours) return;

    final texte = _messageController.text.trim();

    // En édition, la portée est figée : seules les règles du texte
    // s'appliquent.
    if (!_modeEdition) {
      if (_visibilite.type == VisibiliteType.individuelle && _visibilite.usagerConcerneId == null) {
        _erreur('Merci de sélectionner un usager');
        return;
      }
      if (_visibilite.type == VisibiliteType.groupe && _visibilite.uniteConcerneeId == null) {
        _erreur('Merci de sélectionner une unité');
        return;
      }
      if (_visibilite.type == VisibiliteType.groupe && _visibilite.usagersPresentsConcernesIds.isEmpty) {
        _erreur('Merci de sélectionner au moins un usager présent');
        return;
      }
    }
    if (texte.isEmpty) {
      _erreur('Merci de décrire le moment partagé');
      return;
    }

    setState(() => _envoiEnCours = true);

    try {
      if (_modeEdition) {
        await _service.modifierTexte(
          publicationId: widget.publicationAModifier!.id,
          texte: texte,
        );
      } else {
        await _service.creer(
          type: _visibilite.type,
          usagersConcernesIds: _usagersConcernes(),
          uniteId: _uniteConcernee(),
          texte: texte,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _envoiEnCours = false);
      _erreur(_messageErreur(e));
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_modeEdition ? 'Publication modifiée' : 'Publication créée'),
      ),
    );
    Navigator.of(context).pop();
  }

  /// Les usagers réellement concernés, selon la portée choisie.
  ///
  /// Une publication d'établissement n'en cible aucun — c'est ce qui la
  /// distingue d'une publication de groupe couvrant tout le monde.
  List<String> _usagersConcernes() {
    switch (_visibilite.type) {
      case VisibiliteType.individuelle:
        final id = _visibilite.usagerConcerneId;
        return id == null ? const [] : [id];
      case VisibiliteType.groupe:
        return _visibilite.usagersPresentsConcernesIds;
      case VisibiliteType.etablissement:
        return const [];
    }
  }

  /// L'unité est portée par la publication individuelle **comme** par celle de
  /// groupe : c'est elle qui rend la publication visible aux collègues de
  /// l'unité, et c'est elle que la règle de création vérifie contre
  /// `unitesAcces`. Seule la portée établissement n'en a pas.
  ///
  /// C'est `VisibiliteSelector` qui la résout dans les deux cas — pour une
  /// publication individuelle, il la déduit de l'usager choisi.
  String? _uniteConcernee() =>
      _visibilite.type == VisibiliteType.etablissement
          ? null
          : _visibilite.uniteConcerneeId;

  /// Distingue un refus de règle d'une panne — la conduite à tenir n'est pas
  /// la même, et « une erreur est survenue » ne dit rien à personne.
  ///
  /// Aucun cas « établissement » ici : une publication d'établissement n'est
  /// soumise à aucune restriction d'auteur dans le fil d'actu (voir CLAUDE.md,
  /// section « Permission diffusion établissement »). Un refus sur ce type ne
  /// pourrait venir que d'un défaut, pas d'une permission manquante.
  String _messageErreur(Object e) {
    if (!PublicationService.estRefusDePermission(e)) {
      return "L'envoi a échoué. Vérifiez votre connexion, puis réessayez.";
    }
    return "Vous n'êtes pas autorisé à publier sur cette unité.";
  }

  void _erreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        // Turquoise : sans ça le bandeau d'en-tête ne rejoint pas le haut de
        // l'écran sous la SafeArea et laisse une bande blanche.
        backgroundColor: AppColors.turquoise,
        body: SafeArea(
          child: Column(
            children: [
              SimpleTurquoiseHeader(
                title: _modeEdition ? 'Modifier la publication' : 'Nouvelle publication',
              ),
              Expanded(
                child: AuthBackground(
                  // Le RelioFooter est dans l'AuthBackground, pas au niveau du
                  // Scaffold : son marine à 45 % serait illisible sur le
                  // turquoise. Il reste hors du ScrollView pour tenir le bas
                  // de l'écran plutôt que de défiler avec le formulaire.
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // En édition, la portée n'est pas rejouée : elle
                              // est immuable côté règles. Plutôt qu'un
                              // sélecteur grisé (qui invite à essayer), une
                              // phrase qui dit pourquoi.
                              if (_modeEdition)
                                _PorteeFigee(publication: widget.publicationAModifier!)
                              else
                                ChargementPerimetrePro(
                                  builder: (context, perimetre) => VisibiliteSelector(
                                    typeLabel: 'Type de publication',
                                    usagers: perimetre.usagers,
                                    unites: perimetre.unites,
                                    onChanged: (value) => setState(() => _visibilite = value),
                                    showConsentBadge: true,
                                  ),
                                ),
                              const SizedBox(height: 20),
                              const SectionLabel('Message'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _messageController,
                                maxLines: 5,
                                maxLength: 1000,
                                style: TextStyle(color: AppColors.marine),
                                decoration: InputDecoration(
                                  hintText: 'Décrivez le moment partagé...',
                                  hintStyle: TextStyle(color: AppColors.marine.withValues(alpha: 0.4)),
                                  filled: true,
                                  fillColor: AppColors.champText,
                                  counterStyle: TextStyle(
                                    color: AppColors.marine.withValues(alpha: 0.4),
                                    fontSize: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: AppColors.turquoise.withValues(alpha: 0.6),
                                      width: 1.4,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: AppColors.turquoise.withValues(alpha: 0.6),
                                      width: 1.4,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.turquoise, width: 2),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                // Désactivé pendant l'envoi : c'est ce qui
                                // empêche deux appuis rapides de créer deux
                                // publications.
                                onPressed: _envoiEnCours ? null : _handlePublish,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.roseViolet,
                                ),
                                child: _envoiEnCours
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(_modeEdition ? 'Enregistrer' : 'Publier'),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Rappel de la portée d'une publication en cours d'édition.
///
/// La portée, l'unité et les usagers concernés sont **immuables** — les règles
/// Firestore les protègent par `hasOnly()` sur les clés modifiées. Afficher un
/// sélecteur grisé inviterait à essayer ; une phrase explique.
class _PorteeFigee extends StatelessWidget {
  const _PorteeFigee({required this.publication});

  final Publication publication;

  String get _libellePortee {
    switch (publication.typePublication) {
      case VisibiliteType.individuelle:
        return 'Publication individuelle';
      // « groupe » en base, « Unité » à l'écran — règle de vocabulaire du
      // projet, voir CLAUDE.md. Un pro ne pense pas « groupe ».
      case VisibiliteType.groupe:
        return "Publication d'unité";
      case VisibiliteType.etablissement:
        return "Publication d'établissement";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 18, color: AppColors.marine.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _libellePortee,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.marine,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'La portée et les usagers concernés ne peuvent pas être '
                  'modifiés après publication. Seul le texte est modifiable.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.marine.withValues(alpha: 0.65),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
