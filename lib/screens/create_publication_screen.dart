import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/publication.dart';
import '../models/visibilite_type.dart';
import '../services/photo_service.dart';
import '../services/publication_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/chargement_perimetre_pro.dart';
import '../utils/messages_globaux.dart';
import '../widgets/dashed_border_painter.dart';
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
  final _picker = ImagePicker();

  VisibiliteSelection _visibilite = const VisibiliteSelection(type: VisibiliteType.individuelle);

  final _messageController = TextEditingController();

  /// Photos **déjà compressées**, dans l'ordre d'affichage.
  ///
  /// La compression a lieu au moment de la sélection, pas au moment de publier.
  /// Trois raisons : la mémoire reste bornée (5 × ~400 Ko au lieu de 5 × 8 Mo
  /// de photos brutes, sur lesquelles un téléphone modeste s'étrangle),
  /// l'appui sur « Publier » n'a plus que l'envoi réseau à faire, et un fichier
  /// illisible est signalé tout de suite — pas après que le professionnel a
  /// rédigé son texte.
  final List<Uint8List> _photos = [];

  /// Vrai pendant la préparation d'une photo qui vient d'être choisie.
  bool _compressionEnCours = false;

  /// Anti double-clic : sans ça, deux appuis rapides créent deux publications.
  bool _envoiEnCours = false;

  /// Progression de l'envoi des photos, affichée sous le bouton. Sur le wifi
  /// d'un établissement, cinq photos prennent plusieurs secondes : un compteur
  /// qui avance vaut mieux qu'un bouton qui tourne sans rien dire.
  int _photosEnvoyees = 0;

  bool get _modeEdition => widget.publicationAModifier != null;

  /// Les photos sont figées à la création, comme la portée : les règles
  /// Firestore et Storage refusent tout ajout dès que la liste n'est plus vide.
  /// Afficher un sélecteur en édition inviterait à essayer pour rien.
  bool get _photosModifiables => !_modeEdition;

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

  /// Nombre de photos encore ajoutables.
  int get _placesRestantes => PhotoService.maxPhotos - _photos.length;

  /// Demande la source, récupère les photos, les compresse, les ajoute.
  ///
  /// La compression n'utilise **pas** les options `maxWidth`/`imageQuality` du
  /// sélecteur : elles se comportent différemment selon la plateforme, alors
  /// que la consigne (JPEG, qualité 80, 1920 px) doit valoir à l'identique sur
  /// Android, sur le Web et sur iOS. Le sélecteur rend donc la photo brute, et
  /// [PhotoService] seul décide de ce qui part en ligne.
  Future<void> _ajouterPhotos() async {
    if (_placesRestantes <= 0 || _compressionEnCours) return;

    final source = await _choisirSource();
    if (source == null) return;

    final List<XFile> fichiers;
    try {
      if (source == ImageSource.camera) {
        final photo = await _picker.pickImage(source: ImageSource.camera);
        fichiers = photo == null ? const [] : [photo];
      } else {
        fichiers = await _picker.pickMultiImage(limit: _placesRestantes);
      }
    } catch (e) {
      if (!mounted) return;
      _erreur("Impossible d'ouvrir vos photos.");
      return;
    }

    if (fichiers.isEmpty || !mounted) return;

    setState(() => _compressionEnCours = true);

    var echecs = 0;
    // `limit` n'est qu'une indication pour le sélecteur système : certaines
    // galeries la respectent, d'autres non. La coupe est refaite ici, où elle
    // est garantie.
    for (final fichier in fichiers.take(_placesRestantes)) {
      try {
        final compressee = await PhotoService.compresser(await fichier.readAsBytes());
        if (!mounted) return;
        setState(() => _photos.add(compressee));
      } catch (e) {
        echecs++;
      }
    }

    if (!mounted) return;
    setState(() => _compressionEnCours = false);

    if (echecs > 0) {
      _erreur(
        echecs == 1
            ? "Une photo n'a pas pu être préparée."
            : "$echecs photos n'ont pas pu être préparées.",
      );
    }
  }

  /// Appareil photo ou galerie.
  ///
  /// L'appareil photo est en premier : un éducateur qui vient de terminer une
  /// activité photographie maintenant, il ne va pas chercher un fichier.
  Future<ImageSource?> _choisirSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.turquoise),
              title: Text('Prendre une photo', style: TextStyle(color: AppColors.marine)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.turquoise),
              title: Text('Choisir dans la galerie', style: TextStyle(color: AppColors.marine)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _retirerPhoto(int index) => setState(() => _photos.removeAt(index));

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

    setState(() {
      _envoiEnCours = true;
      _photosEnvoyees = 0;
    });

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
          photos: _photos,
          progressionPhotos: (envoyees, _) {
            if (!mounted) return;
            setState(() => _photosEnvoyees = envoyees);
          },
        );
      }
    } on PhotosNonEnvoyeesException {
      // La publication EXISTE, avec son texte. On ferme l'écran comme après un
      // succès : y rester inviterait à réappuyer sur « Publier », ce qui
      // créerait un doublon au lieu de récupérer les photos.
      //
      // Le message passe par le messenger racine et **avant** le test de
      // `mounted`, délibérément : un envoi peut échouer plusieurs dizaines de
      // secondes après l'appui, quand l'écran n'est plus là. C'est ce qui
      // s'était produit le 2026-08-19 — l'échec existait, personne ne l'a su.
      // Le message doit survivre à l'écran qui l'a déclenché.
      //
      // Il énonce le recours, pas seulement le problème : les photos ne sont
      // pas ajoutables après coup (règles Firestore et Storage), donc la seule
      // issue est de masquer et republier.
      afficherMessageGlobal(
        "Publication créée, mais les photos n'ont pas pu être envoyées. "
        'Pour les joindre, masquez la publication et republiez-la.',
        duree: const Duration(seconds: 7),
      );
      // `mounted` reste nécessaire ici : on ne dépile pas un écran déjà fermé.
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
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
  /// Le cas « établissement » est distingué depuis le 2026-08-16 : cette portée
  /// exige désormais `peutDiffuserEtablissement`, au même titre qu'un document
  /// ou un message (CLAUDE.md, « portée étendue »). Le chip est grisé en amont,
  /// donc ce refus ne devrait pas se produire — mais parler d'unité à quelqu'un
  /// qui publiait pour tout l'établissement l'enverrait chercher au mauvais
  /// endroit.
  String _messageErreur(Object e) {
    if (!PublicationService.estRefusDePermission(e)) {
      return "L'envoi a échoué. Vérifiez votre connexion, puis réessayez.";
    }
    return _visibilite.type == VisibiliteType.etablissement
        ? "Votre compte n'est pas autorisé à publier pour tout l'établissement."
        : "Vous n'êtes pas autorisé à publier sur cette unité.";
  }

  void _erreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Bande horizontale : case d'ajout puis miniatures, 80×80.
  ///
  /// La case d'ajout reste en **première** position (et non après les photos) :
  /// à cinq miniatures elle sortirait de l'écran, et une action qu'il faut
  /// chercher en faisant défiler n'est pas une action.
  Widget _buildSelecteurPhotos() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 1 + _photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _DashedAddTile(
              enabled: _placesRestantes > 0 && !_compressionEnCours,
              chargement: _compressionEnCours,
              onTap: _ajouterPhotos,
            );
          }
          final photoIndex = index - 1;
          return _PhotoTile(
            octets: _photos[photoIndex],
            onRemove: () => _retirerPhoto(photoIndex),
          );
        },
      ),
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
                                    // Depuis le 2026-08-16, publier pour tout
                                    // l'établissement exige
                                    // `peutDiffuserEtablissement`, comme un
                                    // document ou un message. Le chip grisé
                                    // double la règle Firestore `peutCreer()` :
                                    // sans lui, le pro composerait toute sa
                                    // publication avant de se voir refuser
                                    // l'envoi.
                                    restrictionEtablissementActive: true,
                                  ),
                                ),
                              const SizedBox(height: 20),
                              if (_photosModifiables) ...[
                                const SectionLabel('Photos'),
                                const SizedBox(height: 8),
                                _buildSelecteurPhotos(),
                                // Décision 6 du chantier étape 2 : un texte
                                // fixe, jamais une modale qu'on ferme une fois.
                                // Une publication d'établissement ne cible
                                // aucun usager, donc aucun consentement image
                                // ne s'y applique — c'est le seul garde-fou
                                // possible sur le contenu de la photo. Voir
                                // [_AlerteEtablissement].
                                if (_visibilite.type == VisibiliteType.etablissement) ...[
                                  const SizedBox(height: 12),
                                  const _AlerteEtablissement(),
                                ],
                                const SizedBox(height: 20),
                              ],
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
                              if (_envoiEnCours && _photos.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Envoi des photos… $_photosEnvoyees/${_photos.length}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.marine.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
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

/// Case « + Ajouter », bordure turquoise en pointillés.
class _DashedAddTile extends StatelessWidget {
  const _DashedAddTile({
    required this.onTap,
    this.enabled = true,
    this.chargement = false,
  });

  final VoidCallback onTap;
  final bool enabled;

  /// Vrai pendant la préparation d'une photo tout juste choisie. Compresser une
  /// photo de 8 Mo prend un instant visible : sans retour, le professionnel
  /// appuie une seconde fois.
  final bool chargement;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: CustomPaint(
          painter: DashedBorderPainter(color: AppColors.turquoise),
          child: SizedBox(
            width: 80,
            height: 80,
            child: chargement
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.turquoise,
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: AppColors.turquoise),
                      const SizedBox(height: 2),
                      Text(
                        'Ajouter',
                        style: TextStyle(
                          color: AppColors.turquoise,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Miniature d'une photo déjà choisie, avec sa croix de retrait.
class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.octets, required this.onRemove});

  /// Les octets **déjà compressés** — c'est exactement ce qui partira en ligne
  /// qui est montré, pas la photo d'origine.
  final Uint8List octets;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              octets,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              // `gaplessPlayback` évite le clignotement blanc lorsque la liste
              // se reconstruit après le retrait d'une autre miniature.
              gaplessPlayback: true,
            ),
          ),
          Positioned(
            top: -12,
            right: -12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.marine,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rappel affiché sous le sélecteur de photos pour une publication
/// d'établissement.
///
/// **Fixe et non fermable, à chaque publication** — pas une modale qu'on écarte
/// une fois pour toutes. C'est le garde-fou retenu (décision 6 de l'étape 2)
/// pour un angle mort structurel : une publication d'établissement ne cible
/// aucun usager, donc aucun consentement image ne peut lui être opposé, et
/// aucun badge d'alerte n'a de sens à afficher. `peutDiffuserEtablissement`
/// restreint *qui* publie ; ce texte est la seule chose qui parle de *ce que la
/// photo montre*.
///
/// Ni case à cocher de déclaration, ni détection automatique de visages : la
/// première transforme une vigilance en formalité qu'on coche sans lire, la
/// seconde n'existe pas de façon fiable et donnerait une fausse sécurité.
///
/// Orange `shade800` : exactement la teinte des refus de consentement image
/// ailleurs dans l'app. Un professionnel qui a appris à repérer cette couleur
/// sur les écrans de publication doit la reconnaître ici sans réapprentissage.
class _AlerteEtablissement extends StatelessWidget {
  const _AlerteEtablissement();

  @override
  Widget build(BuildContext context) {
    final couleur = Colors.orange.shade800;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: couleur),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Publication établissement : vérifiez qu’aucun visage n’est '
              'identifiable sur les photos partagées.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.marine,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rappel de la portée d'une publication en cours d'édition.
///
/// La portée, l'unité, les usagers concernés **et les photos** sont immuables —
/// les règles Firestore les protègent par `hasOnly()` sur les clés modifiées.
/// Afficher un sélecteur grisé inviterait à essayer ; une phrase explique.
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
                  'La portée, les usagers concernés et les photos ne peuvent '
                  'pas être modifiés après publication. Seul le texte est '
                  'modifiable.',
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
