import 'package:flutter/material.dart';

import '../models/consent_image.dart';
import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';

/// État complet du consentement image d'un usager, par type de publication.
///
/// **Informatif, jamais bloquant** — voir CLAUDE.md, section « Consentement
/// image (usagers) ». Un refus n'empêche techniquement rien : il informe le
/// professionnel avant qu'il ne diffuse une photo.
///
/// À distinguer de [ConsentImageBadge] (`consent_image_badge.dart`), qui reste
/// l'alerte orange affichée **au moment de publier** : là, la question est
/// « ai-je le droit pour le type que je suis en train de choisir ? », et une
/// alerte franche répond mieux qu'un état à déchiffrer. Ce composant-ci sert à
/// la **consultation** (Cahier de liaison, Mes unités), où le professionnel
/// veut voir la situation complète.
///
/// Deux densités pour la même information :
/// - [ConsentImageEtat.compact] — trois pastilles, tient sur une ligne de
///   liste (jusqu'à 27 usagers dans une unité).
/// - [ConsentImageEtat.detaille] — libellés en toutes lettres, pour un
///   en-tête où la place ne manque pas.
///
/// L'état n'est **jamais porté par la couleur seule** : chaque pastille porte
/// sa lettre et son signe, lisibles sans distinguer turquoise d'orange
/// (accessibilité, valeur fondamentale du projet).
///
/// Le groupe est précédé d'une **icône d'appareil photo** qui dit de quoi
/// parlent les pastilles — l'image. Elle ne porte aucun état : une seule par
/// groupe, jamais une par pastille. Voir [_IconeSujet] pour le raisonnement.
class ConsentImageEtat extends StatelessWidget {
  const ConsentImageEtat.compact({super.key, required this.consent})
      : detaille = false;

  const ConsentImageEtat.detaille({super.key, required this.consent})
      : detaille = true;

  final ConsentImage consent;
  final bool detaille;

  /// Libellés affichés, et non les noms des champs.
  ///
  /// Le champ Firestore s'appelle `groupe` (schéma `usagers.consentImage`,
  /// voir CLAUDE.md) mais l'app dit **« Unité »** partout ailleurs : chips du
  /// sélecteur de visibilité, tuiles d'agenda, en-têtes de message. Le nom du
  /// champ n'a pas à remonter jusqu'à l'écran — c'est le vocabulaire de
  /// l'établissement qui prime, et un pro ne pense pas « groupe », il pense
  /// « l'unité Polyvalence ».
  ///
  /// **Deux types, plus trois, depuis R3b.** La pastille « établissement » a
  /// été retirée : cette portée n'est plus gouvernée par le consentement image
  /// mais par `peutDiffuserEtablissement` (qui restreint les pros pouvant
  /// publier) et le texte d'alerte prévu à l'étape 2. Le champ
  /// `consentImage.etablissement` demeure dans le schéma — aucune migration —
  /// mais n'a plus ni écran, ni écriture, ni représentation visuelle. L'afficher
  /// en lecture seule aurait laissé croire à un réglage que plus personne ne
  /// peut modifier.
  static const _types = [
    ('I', 'individuelle', VisibiliteType.individuelle),
    ('U', 'unité', VisibiliteType.groupe),
  ];

  List<EtatConsentImage> get _etats =>
      [for (final (_, _, type) in _types) consent.etatPour(type)];

  /// Description en toutes lettres, pour les lecteurs d'écran — les pastilles
  /// « I ✓ U ✗ » seraient épelées lettre par lettre sans ça.
  String get _descriptionAccessible {
    final etats = _etats;
    final parties = <String>[];
    for (var i = 0; i < _types.length; i++) {
      parties.add('${_types[i].$2} ${_libelleEtat(etats[i])}');
    }
    return 'Autorisation image : ${parties.join(", ")}';
  }

  static String _libelleEtat(EtatConsentImage etat) => switch (etat) {
        EtatConsentImage.autorise => 'autorisée',
        EtatConsentImage.refuse => 'refusée',
        EtatConsentImage.nonRenseigne => 'non renseignée',
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _descriptionAccessible,
      excludeSemantics: true,
      child: detaille ? _buildDetaille() : _buildCompact(),
    );
  }

  Widget _buildCompact() {
    final etats = _etats;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const _IconeSujet(),
        for (var i = 0; i < _types.length; i++)
          _Pastille(libelle: _types[i].$1, etat: etats[i]),
      ],
    );
  }

  Widget _buildDetaille() {
    final etats = _etats;
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // L'icône remplace l'ancien libellé « Image : ». Les deux variantes se
        // lisent désormais pareil, et le sujet est enfin explicite en compact,
        // où rien ne le nommait.
        const _IconeSujet(),
        for (var i = 0; i < _types.length; i++)
          _Pastille(libelle: _types[i].$2, etat: etats[i]),
      ],
    );
  }
}

/// Icône de sujet, en tête du groupe : elle dit **de quoi** parlent les
/// pastilles (l'image), pas quel est leur état.
///
/// **Une seule par groupe, jamais une par pastille.** Trois raisons :
/// - les trois pastilles portent le même sujet — le répéter trois fois par
///   ligne dit trois fois la même chose ;
/// - une unité peut compter 27 usagers, soit 81 icônes à l'écran pour une
///   information constante ;
/// - à 11 px, un pictogramme barré est une tache : distinguer « plein » de
///   « barré » y est plus difficile que distinguer `✓` de `✗`. L'état reste
///   donc porté par le signe de chaque pastille, pas par une icône.
///
/// Neutre en couleur (marine à 55 %, celle de l'ancien libellé « Image : ») :
/// une icône teintée laisserait croire qu'elle porte un état.
class _IconeSujet extends StatelessWidget {
  const _IconeSujet();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.photo_camera_outlined,
      size: 14,
      color: AppColors.marine.withValues(alpha: 0.55),
    );
  }
}

/// Une pastille d'état : libellé + signe, sur fond teinté.
class _Pastille extends StatelessWidget {
  const _Pastille({required this.libelle, required this.etat});

  final String libelle;
  final EtatConsentImage etat;

  @override
  Widget build(BuildContext context) {
    // Trois états, trois couples couleur/signe.
    //
    // L'orange du refus est **exactement celui de [ConsentImageBadge]**
    // (`orange.shade800`) : un pro qui a appris à repérer cette teinte sur les
    // écrans de publication doit la reconnaître ici sans réapprentissage. Un
    // refus signalé dans une couleur différente selon l'écran se remarquerait
    // moins bien, ce qui est précisément ce qu'on ne veut pas sur une donnée
    // qui protège l'image d'un enfant.
    //
    // Le « non renseigné » porte un marine atténué et un « ? », pas un « ✗ » :
    // une famille qui n'a pas encore répondu n'a rien refusé, et l'afficher
    // comme un refus prêterait à un parent un choix qu'il n'a jamais exprimé.
    final (couleur, signe) = switch (etat) {
      EtatConsentImage.autorise => (AppColors.turquoise, '✓'),
      EtatConsentImage.refuse => (Colors.orange.shade800, '✗'),
      EtatConsentImage.nonRenseigne => (AppColors.marine.withValues(alpha: 0.55), '?'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$libelle $signe',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: couleur,
        ),
      ),
    );
  }
}
