import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../utils/avatar_color.dart';
import 'consent_image.dart';
import 'usager.dart';
import 'visibilite_type.dart';

/// Un usager tel que les écrans doivent l'afficher.
///
/// Chantier Référentiel / R3a — **point de composition unique**. Les dix
/// écrans migrés passent tous par ici plutôt que de recomposer chacun de leur
/// côté « champs Firestore + consentement mock + couleur dérivée ».
///
/// Trois sources, une seule classe :
///
/// 1. **Identité** ([Usager], depuis Firestore) — prénom, nom, unité, année de
///    naissance, photo, actif.
/// 2. **Consentement image** (depuis `mockUsagersCatalogue`) — voir le pont
///    temporaire ci-dessous.
/// 3. **Couleur d'avatar** ([avatarColorPourUsager]) — dérivée de l'id, parce
///    que le schéma Firestore n'en porte pas.
///
/// ---
/// ## ⚠ PONT TEMPORAIRE — péremption prévue : R3b
///
/// **Le consentement image est lu depuis le mock, pas depuis Firestore, et
/// c'est délibéré.** R2 a posé `allow write: if false` sur la collection
/// `usagers` : il n'existe aujourd'hui aucun chemin d'écriture client pour le
/// consentement, donc les 55 documents semés portent `consentImage` à `false`
/// partout.
///
/// Lire ce champ depuis Firestore afficherait « aucun consentement » sur les
/// six usagers dont le mock porte un état volontairement différencié
/// (`usager_001`, `002`, `003`, `017`, `031`, `032`), et casserait
/// silencieusement le test du badge d'alerte — **sans qu'aucune erreur ne se
/// déclenche**. Une régression invisible est pire qu'une panne franche.
///
/// **R3b** ouvrira un chemin d'écriture (probablement une Cloud Function, pour
/// préserver `allow write: if false` sur le reste du document). Ce jour-là,
/// c'est [consentImage] ci-dessous — et lui seul — qui change de source :
/// remplacer l'appel à `findUsagerById` par `_usager.consentImage`. Aucun
/// écran n'a à être touché.
class UsagerAffichage {
  const UsagerAffichage(this._usager);

  final Usager _usager;

  /// Compose la vue d'affichage d'un [Usager] Firestore.
  static UsagerAffichage composer(Usager usager) => UsagerAffichage(usager);

  // --- Identité (Firestore) --------------------------------------------

  String get id => _usager.id;
  String get prenom => _usager.prenom;
  String get nom => _usager.nom;
  String get nomComplet => _usager.nomComplet;
  String get uniteId => _usager.uniteId;
  String get etablissementId => _usager.etablissementId;
  int get anneeNaissance => _usager.anneeNaissance;
  String? get photoUrl => _usager.photoUrl;
  bool get actif => _usager.actif;

  /// Âge en années révolues, calculé — jamais stocké (voir [Usager]).
  int get age => _usager.ageApproximatif();

  /// Initiales pour l'avatar, ex. « LD » pour Lucas Dubois.
  String get initiales {
    final lettres = [prenom, nom]
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .join();
    return lettres.toUpperCase();
  }

  // --- Couleur d'avatar (dérivée) ---------------------------------------

  Color get avatarColor => avatarColorPourUsager(id);

  // --- Consentement image (mock — voir le pont temporaire ci-dessus) -----

  /// Consentement image de l'usager, **lu depuis `mockUsagersCatalogue`**.
  ///
  /// Un usager absent du mock est traité comme sans consentement enregistré
  /// (tous les booléens à `false`) : aucune présomption d'accord, conformément
  /// à la règle du projet.
  ConsentImage get consentImage =>
      findUsagerById(id)?.consentImage ?? const ConsentImage();

  /// Vrai si l'usager n'a pas d'autorisation image pour [type] — sert à
  /// afficher le badge d'alerte, **informatif et jamais bloquant** (voir
  /// CLAUDE.md, section « Consentement image »).
  ///
  /// Délègue à `usagerSansAutorisationImage`, laissée inchangée dans
  /// `mock_data.dart` : une seule fonction lit le consentement dans toute
  /// l'app, ce qui garantit qu'aucun chemin ne pourra diverger d'ici R3b.
  bool sansAutorisationImage(VisibiliteType type) =>
      usagerSansAutorisationImage(id, type: type);
}
