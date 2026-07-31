import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/avatar_color.dart';
import 'visibilite_type.dart';

/// Commentaire d'une publication.
///
/// **Pas encore câblé sur Firestore** — les commentaires sont l'étape 3 du
/// chantier Publications. Ce modèle ne sert aujourd'hui qu'à `mockPublications`
/// (`mock_data.dart`), conservé jusque-là pour ses commentaires de
/// démonstration.
class PublicationCommentaire {
  const PublicationCommentaire({
    required this.auteurId,
    required this.auteurNom,
    required this.avatarColor,
    required this.texte,
    required this.date,
  });

  final String auteurId;
  final String auteurNom;

  /// Couleur d'avatar de l'auteur du commentaire (affichage uniquement).
  final Color avatarColor;
  final String texte;
  final DateTime date;
}

/// Modèle de la collection Firestore `publications`.
///
/// Chantier Publications / étape 1 — texte seul. Les photos (étape 2) et les
/// likes/commentaires (étape 3) s'ajouteront de façon **additive** : un
/// document qui ne porte pas encore ces champs doit rester lisible, d'où la
/// tolérance aux champs absents de [fromFirestore] (même principe qu'`Usager`
/// en R2).
class Publication {
  const Publication({
    required this.id,
    required this.auteurId,
    required this.auteurNom,
    required this.typePublication,
    required this.etablissementId,
    required this.texte,
    required this.dateCreation,
    this.usagersConcernesIds = const [],
    this.uniteId,
    this.cibles = const [],
    this.modifiee = false,
    this.dateModification,
    this.masquee = false,
    this.dateMasquage,
    this.masqueePar,
    this.motifMasquage,
    this.photos = const [],
    this.likes = const [],
    this.commentaires = const [],
  });

  final String id;

  /// Uid du pro auteur. Non falsifiable : la règle de création impose
  /// `auteurId == request.auth.uid`.
  final String auteurId;

  /// « Prénom Nom », **dénormalisé à la création**.
  ///
  /// Sans ça, afficher l'auteur coûterait un `get()` sur `users/{auteurId}`
  /// par publication du feed. Le nom est figé au moment de publier : s'il
  /// change ensuite, les publications passées gardent l'ancien. Compromis
  /// d'affichage assumé, pas une exigence d'exactitude rétroactive.
  final String auteurNom;

  final VisibiliteType typePublication;

  /// Usagers concernés — **champ sémantique**, c'est lui qui alimentera le
  /// Journal de vie (étape 5). Vide pour une publication d'établissement.
  ///
  /// À ne pas confondre avec [cibles], qui est le champ technique de
  /// requêtage.
  final List<String> usagersConcernesIds;

  /// Unité concernée pour une portée individuelle ou groupe. `null` pour
  /// établissement.
  final String? uniteId;

  final String etablissementId;

  /// **Champ technique de requêtage — ne jamais l'afficher.**
  ///
  /// Permet au feed pro et au feed famille d'utiliser la *même* requête
  /// (`array-contains-any`) et le *même* index, malgré des périmètres de
  /// nature différente (unités d'un côté, usagers de l'autre) :
  ///
  /// | Portée | `cibles` |
  /// |---|---|
  /// | individuelle | `[usagerId, uniteId]` |
  /// | groupe | `[...usagersPresents, uniteId]` |
  /// | établissement | `[etablissementId]` |
  ///
  /// Dénormalisation assumée : entièrement dérivable de [usagersConcernesIds],
  /// [uniteId] et [typePublication] — ce n'est pas une seconde source de
  /// vérité. Calculée à la création par [calculerCibles] et **jamais modifiée
  /// ensuite** (les champs qui la déterminent sont immuables côté règles).
  final List<String> cibles;

  final String texte;
  final DateTime dateCreation;

  /// Édition du texte par l'auteur.
  final bool modifiee;
  final DateTime? dateModification;

  /// Masquage (soft delete). **Jamais de suppression physique** : la règle
  /// Firestore pose `allow delete: if false` sans exception.
  final bool masquee;
  final DateTime? dateMasquage;

  /// Uid de qui a masqué — l'auteur, ou un compte `peutModerer`. Tracé pour
  /// que l'auteur voie *qui* a retiré sa publication.
  final String? masqueePar;
  final String? motifMasquage;

  /// Étape 2 — pas encore écrit ni lu depuis Firestore.
  final List<String> photos;

  /// Étape 3 — pas encore écrits ni lus depuis Firestore.
  final List<String> likes;
  final List<PublicationCommentaire> commentaires;

  /// Couleur d'avatar de l'auteur, **dérivée de son uid**.
  ///
  /// Le schéma Firestore ne porte aucune couleur (même décision qu'en R1 pour
  /// les usagers : une couleur d'affichage n'a rien à faire en base). On
  /// réutilise la fonction de R3a telle quelle — déterministe, identique sur
  /// Android et sur le Web.
  Color get avatarColor => avatarColorPourUsager(auteurId);

  /// Construit le champ [cibles] à partir de la portée choisie.
  ///
  /// Pure et testable à l'œil : c'est la pièce dont dépend *toute* la
  /// visibilité du feed. Une erreur ici ne provoque pas d'exception — elle
  /// rend une publication invisible, ou visible par les mauvaises personnes.
  static List<String> calculerCibles({
    required VisibiliteType type,
    required List<String> usagersConcernesIds,
    required String? uniteId,
    required String etablissementId,
  }) {
    switch (type) {
      case VisibiliteType.individuelle:
      case VisibiliteType.groupe:
        return [
          ...usagersConcernesIds,
          ?uniteId,
        ];
      case VisibiliteType.etablissement:
        return [etablissementId];
    }
  }

  /// Tolérant aux champs absents : un document incomplet produit un objet
  /// valide, jamais une exception. Faire planter le feed sur une publication
  /// mal formée serait un défaut de robustesse inacceptable.
  ///
  /// L'`id` vient **toujours** de `doc.id`, jamais d'un champ du document.
  factory Publication.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};

    return Publication(
      id: doc.id,
      auteurId: data['auteurId'] as String? ?? '',
      auteurNom: data['auteurNom'] as String? ?? 'Auteur inconnu',
      typePublication: _typeDepuisFirestore(data['typePublication']),
      usagersConcernesIds: _listeDeTextes(data['usagersConcernes']),
      uniteId: data['uniteId'] as String?,
      etablissementId: data['etablissementId'] as String? ?? '',
      cibles: _listeDeTextes(data['cibles']),
      texte: data['texte'] as String? ?? '',
      dateCreation: _date(data['dateCreation']) ?? DateTime.now(),
      modifiee: data['modifiee'] as bool? ?? false,
      dateModification: _date(data['dateModification']),
      masquee: data['masquee'] as bool? ?? false,
      dateMasquage: _date(data['dateMasquage']),
      masqueePar: data['masqueePar'] as String?,
      motifMasquage: data['motifMasquage'] as String?,
    );
  }

  /// Document envoyé à Firestore **à la création uniquement**.
  ///
  /// Les mises à jour (édition, masquage) n'utilisent pas cette méthode : elles
  /// écrivent un sous-ensemble strict de champs, parce que les règles imposent
  /// `hasOnly([...])` sur les clés modifiées.
  Map<String, dynamic> toFirestoreCreation() {
    return {
      'auteurId': auteurId,
      'auteurNom': auteurNom,
      'typePublication': typePublication.name,
      'usagersConcernes': usagersConcernesIds,
      'uniteId': uniteId,
      'etablissementId': etablissementId,
      'cibles': cibles,
      'texte': texte,
      'dateCreation': FieldValue.serverTimestamp(),
      'modifiee': false,
      'dateModification': null,
      'masquee': false,
      'dateMasquage': null,
      'masqueePar': null,
      'motifMasquage': null,
    };
  }

  /// Vrai si [uid] peut ouvrir le menu « ⋮ » : l'auteur, ou un modérateur.
  bool menuVisiblePour({required String? uid, required bool peutModerer}) =>
      uid != null && (auteurId == uid || peutModerer);

  /// Vrai si [uid] peut **modifier le texte**. Réservé à l'auteur, même pour
  /// un modérateur : modérer, c'est retirer, jamais réécrire les mots de
  /// quelqu'un d'autre.
  bool modifiablePar(String? uid) => uid != null && auteurId == uid;

  /// Une publication masquée reste visible pour son auteur et pour les
  /// modérateurs — avec une mention explicite, jamais une disparition
  /// silencieuse. Pour tous les autres, elle est filtrée du feed.
  bool visiblePour({required String? uid, required bool peutModerer}) =>
      !masquee || menuVisiblePour(uid: uid, peutModerer: peutModerer);

  Publication copyWith({
    String? texte,
    bool? modifiee,
    DateTime? dateModification,
    bool? masquee,
    DateTime? dateMasquage,
    String? masqueePar,
    String? motifMasquage,
  }) {
    return Publication(
      id: id,
      auteurId: auteurId,
      auteurNom: auteurNom,
      typePublication: typePublication,
      usagersConcernesIds: usagersConcernesIds,
      uniteId: uniteId,
      etablissementId: etablissementId,
      cibles: cibles,
      texte: texte ?? this.texte,
      dateCreation: dateCreation,
      modifiee: modifiee ?? this.modifiee,
      dateModification: dateModification ?? this.dateModification,
      masquee: masquee ?? this.masquee,
      dateMasquage: dateMasquage ?? this.dateMasquage,
      masqueePar: masqueePar ?? this.masqueePar,
      motifMasquage: motifMasquage ?? this.motifMasquage,
      photos: photos,
      likes: likes,
      commentaires: commentaires,
    );
  }
}

/// Une valeur inconnue retombe sur `etablissement` plutôt que de lever : c'est
/// la portée la plus large, donc celle qui ne fait disparaître aucune
/// publication du feed de qui que ce soit. Un document mal formé doit se voir,
/// pas s'évanouir.
VisibiliteType _typeDepuisFirestore(Object? valeur) {
  return VisibiliteType.values.firstWhere(
    (type) => type.name == valeur,
    orElse: () => VisibiliteType.etablissement,
  );
}

List<String> _listeDeTextes(Object? valeur) {
  if (valeur is! List) return const [];
  return valeur.whereType<String>().toList();
}

DateTime? _date(Object? valeur) => valeur is Timestamp ? valeur.toDate() : null;
