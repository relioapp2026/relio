import 'package:cloud_firestore/cloud_firestore.dart';

import 'consent_image.dart';

/// Modèle correspondant à un document Firestore `usagers/{id}`.
///
/// Chantier Référentiel / R2 — **lecture seule** (voir [Etablissement] pour
/// le motif de l'absence de `toFirestore`).
///
/// **Aucun champ `age`** : l'âge se calcule à l'affichage depuis
/// [anneeNaissance], qui est la valeur de référence. Un `age` stocké
/// périmerait tout seul. Le champ `age` de `MockUsager` (`mock_data.dart`)
/// reste en place jusqu'à R3 et n'est pas concerné.
///
/// **Aucun champ `avatarColor`** non plus : il n'existe pas dans le schéma
/// Firestore. `MockUsager` en porte un, utilisé par tous les écrans validés
/// — R3 devra donc dériver la couleur de [id] de façon déterministe, sinon
/// les avatars changeraient de couleur à chaque lancement (voir CLAUDE.md).
class Usager {
  const Usager({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.uniteId,
    required this.etablissementId,
    required this.anneeNaissance,
    required this.photoUrl,
    required this.actif,
    required this.consentImage,
  });

  final String id;
  final String prenom;
  final String nom;

  /// Référence stable vers [Unite.id] — jamais un nom d'unité.
  final String uniteId;
  final String etablissementId;

  /// Valeur de référence pour l'âge. `null` au seed n'existe pas : le champ
  /// est toujours présent, mais vaut 0 si le document est incomplet.
  final int anneeNaissance;

  /// `null` tant qu'aucune photo n'a été téléversée (chantier Publications,
  /// étape 3).
  final String? photoUrl;

  /// Faux pour un usager sorti de l'établissement. Filtré **côté client**
  /// par [ReferentielService] : un `where` supplémentaire imposerait un
  /// index composite inutile à cette volumétrie.
  final bool actif;

  /// Autorisation à l'image par type de publication — voir CLAUDE.md,
  /// section « Consentement image (usagers) ».
  final ConsentImage consentImage;

  /// Affichage uniquement — ne jamais comparer/filtrer sur cette valeur
  /// (deux usagers peuvent être homonymes, voir `usager_017`/`usager_032`).
  String get nomComplet => '$prenom $nom';

  /// Âge en années révolues à la date [maintenant] (par défaut, aujourd'hui).
  /// Approximation à l'année près : seule l'année de naissance est connue,
  /// pas la date exacte — volontaire, c'est une donnée d'affichage.
  int ageApproximatif({DateTime? maintenant}) =>
      (maintenant ?? DateTime.now()).year - anneeNaissance;

  /// L'`id` vient **toujours** de `doc.id`, jamais d'un champ du document.
  ///
  /// Volontairement tolérant aux champs absents : un document incomplet
  /// produit un objet valide plutôt qu'une exception. `actif` vaut `true`
  /// par défaut (un usager sans le champ est considéré présent), les
  /// booléens de consentement valent `false` (aucune présomption de
  /// consentement, voir [ConsentImage.fromMap]).
  factory Usager.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Usager(
      id: doc.id,
      prenom: data['prenom'] as String? ?? '',
      nom: data['nom'] as String? ?? '',
      uniteId: data['uniteId'] as String? ?? '',
      etablissementId: data['etablissementId'] as String? ?? '',
      anneeNaissance: (data['anneeNaissance'] as num?)?.toInt() ?? 0,
      photoUrl: data['photoUrl'] as String?,
      actif: data['actif'] as bool? ?? true,
      consentImage: ConsentImage.fromMap(data['consentImage'] as Map<String, dynamic>?),
    );
  }
}
