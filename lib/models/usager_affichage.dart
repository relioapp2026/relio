import 'package:flutter/material.dart';

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
/// 2. **Consentement image** ([Usager.consentImage], depuis Firestore
///    également depuis R3b — voir ci-dessous).
/// 3. **Couleur d'avatar** ([avatarColorPourUsager]) — dérivée de l'id, parce
///    que le schéma Firestore n'en porte pas.
///
/// ---
/// ## Pont temporaire n°1 — LEVÉ en R3b (2026-08-16)
///
/// Le consentement image se lisait jusqu'ici depuis `mockUsagersCatalogue`,
/// faute de chemin d'écriture client : R2 avait posé `allow write: if false`
/// sur `usagers`, donc les 55 documents semés portaient `consentImage` à
/// `false` partout, et lire Firestore aurait affiché « aucun consentement »
/// sur les six usagers à état différencié — une régression silencieuse.
///
/// R3b a ouvert ce chemin (règle Firestore ciblée sur le seul champ
/// `consentImage`, écriture réservée à la famille rattachée) et reposé les six
/// cas de test dans `referentiel.json`. La source est donc désormais Firestore,
/// et **aucun écran n'a eu à être touché** — c'était l'objet de ce point de
/// composition.
///
/// Reste le pont n°2 (lien usager → comptes famille, `mockFamilles`), levée
/// prévue au chantier Messagerie.
class UsagerAffichage {
  const UsagerAffichage(this._usager);

  final Usager _usager;

  /// Compose la vue d'affichage d'un [Usager] Firestore.
  static UsagerAffichage composer(Usager usager) => UsagerAffichage(usager);

  // --- Identité (Firestore) --------------------------------------------

  String get id => _usager.id;
  String get prenom => _usager.prenom;
  String get nom => _usager.nom;
  /// « Prénom Nom » — pour les **titres** et en-têtes qui parlent d'un enfant
  /// en particulier (Journal de vie, Cahier de liaison, Agenda).
  String get nomComplet => _usager.nomComplet;

  /// « Nom Prénom » — pour les **listes triées** uniquement.
  ///
  /// Les listes d'usagers sont triées par nom de famille (voir
  /// `ReferentielService._trierEtFiltrer`). Les afficher en « Prénom Nom »
  /// donnait une liste qui paraissait désordonnée : l'œil lit « Nolan, Adam,
  /// Alice » là où le tri porte sur « Barbier, Blanchard, Bonnet ». Faire
  /// commencer la ligne par la clé de tri rend l'ordre évident.
  ///
  /// **Ne pas utiliser pour un titre de page** : « Dubois Lucas » se lit comme
  /// une fiche administrative, pas comme le nom d'un enfant.
  String get nomListe => '$nom $prenom';
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

  // --- Consentement image (Firestore depuis R3b) -------------------------

  /// Consentement image de l'usager, lu depuis Firestore.
  ///
  /// Un document dépourvu du champ produit un objet « aucun consentement »
  /// plutôt qu'une exception ([ConsentImage.fromMap] est tolérant) : aucune
  /// présomption d'accord, conformément à la règle du projet.
  ConsentImage get consentImage => _usager.consentImage;

  /// État du consentement image pour [type] — **informatif, jamais bloquant**
  /// (voir CLAUDE.md, section « Consentement image »).
  ///
  /// Trois états depuis R3b, et non plus un booléen : « jamais répondu » n'est
  /// pas « refusé ». Voir [EtatConsentImage].
  EtatConsentImage etatConsentImage(VisibiliteType type) =>
      consentImage.etatPour(type);

  /// Vrai si l'usager n'a pas d'autorisation image pour [type], au sens de la
  /// diffusion : un consentement non renseigné vaut refus (opt-in strict).
  ///
  /// Pour l'**affichage**, préférer [etatConsentImage], qui distingue un refus
  /// explicite d'une absence de réponse.
  bool sansAutorisationImage(VisibiliteType type) =>
      etatConsentImage(type) != EtatConsentImage.autorise;
}
