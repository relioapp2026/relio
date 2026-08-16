import 'package:cloud_firestore/cloud_firestore.dart';

import 'visibilite_type.dart';

/// État du consentement image pour un type de publication donné.
///
/// Chantier R3b — **trois états, pas deux.** Jusqu'ici l'app fusionnait
/// « refusé explicitement » et « jamais répondu » sous une même alerte orange,
/// point signalé comme ouvert dans CLAUDE.md et tranché ici : c'est
/// [ConsentImage.dateConsentement] qui les sépare. Tant qu'il est `null`,
/// aucune famille n'a rien validé — dire « refusé » serait prêter à un parent
/// un choix qu'il n'a jamais exprimé.
///
/// La distinction compte pour le pro : un refus explicite se respecte, une
/// absence de réponse se relance.
enum EtatConsentImage {
  /// Aucun choix validé à ce jour ([ConsentImage.dateConsentement] est `null`).
  /// Opt-in strict : traité comme un refus côté diffusion, jamais présenté
  /// comme tel côté affichage.
  nonRenseigne,

  /// La famille a explicitement autorisé ce type de publication.
  autorise,

  /// La famille a explicitement refusé ce type de publication.
  refuse,
}

/// Modèle correspondant au champ Firestore `usagers/{usagerId}.consentImage`
/// (voir CLAUDE.md, section « Consentement image (usagers) »). Aucune
/// présomption de consentement : les trois booléens valent `false` tant que
/// [dateConsentement] est absent.
class ConsentImage {
  const ConsentImage({
    this.individuelle = false,
    this.groupe = false,
    this.etablissement = false,
    this.dateConsentement,
    this.versionTexte,
    this.saisiPar,
  });

  final bool individuelle;
  final bool groupe;
  final bool etablissement;

  /// `null` tant qu'aucun choix n'a été validé par la famille (ou un
  /// admin/coordinateur en fallback).
  final DateTime? dateConsentement;

  /// Trace la version du texte de consentement présenté (ex. "v1").
  final String? versionTexte;

  /// Uid du compte famille ayant validé les choix, ou uid admin/coordinateur
  /// en fallback (parent sans smartphone).
  final String? saisiPar;

  /// Chantier Référentiel / R2 — construit l'objet depuis la map imbriquée
  /// `consentImage` d'un document `usagers`.
  ///
  /// Volontairement tolérant : une map `null` ou incomplète produit un objet
  /// valide (aucun consentement), jamais une exception. Aucune présomption de
  /// consentement — un champ absent vaut « refusé », jamais « accepté ».
  /// Faire planter l'app parce qu'un document de référentiel est incomplet
  /// serait un défaut de robustesse inacceptable en production.
  factory ConsentImage.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ConsentImage();

    final date = data['dateConsentement'];
    return ConsentImage(
      individuelle: data['individuelle'] as bool? ?? false,
      groupe: data['groupe'] as bool? ?? false,
      etablissement: data['etablissement'] as bool? ?? false,
      dateConsentement: date is Timestamp ? date.toDate() : null,
      versionTexte: data['versionTexte'] as String?,
      saisiPar: data['saisiPar'] as String?,
    );
  }

  /// Vrai si aucun choix n'a jamais été validé par la famille.
  bool get estNonRenseigne => dateConsentement == null;

  /// État affichable pour [type] — voir [EtatConsentImage].
  ///
  /// `etablissement` n'a plus aucune représentation visuelle depuis R3b : le
  /// champ reste dans le schéma (pas de migration) mais n'est ni affiché, ni
  /// modifiable. Ce chemin n'est jamais emprunté en pratique — il n'existe
  /// aucune sélection d'usager sur une publication d'établissement, donc
  /// aucun badge à calculer.
  EtatConsentImage etatPour(VisibiliteType type) {
    if (estNonRenseigne) return EtatConsentImage.nonRenseigne;
    final accorde = switch (type) {
      VisibiliteType.individuelle => individuelle,
      VisibiliteType.groupe => groupe,
      VisibiliteType.etablissement => etablissement,
    };
    return accorde ? EtatConsentImage.autorise : EtatConsentImage.refuse;
  }

  /// Map destinée au champ `consentImage` d'un document `usagers`.
  ///
  /// Chantier R3b — **le seul `toFirestore` du référentiel**, et il n'écrit
  /// qu'un champ. R2 avait posé « aucun `toFirestore` : le référentiel ne
  /// s'écrit pas depuis le client » ; R3b ouvre cette exception unique, bornée
  /// par la règle `consentImageValide()` de `firestore.rules`.
  ///
  /// Trois points qui doivent rester alignés avec cette règle, sous peine de
  /// `permission-denied` :
  /// - [etablissement] est **recopié tel quel**, jamais recalculé : la règle
  ///   vérifie qu'il n'a pas bougé.
  /// - `dateConsentement` part en `FieldValue.serverTimestamp()` — la règle
  ///   exige un timestamp, et l'horloge d'un téléphone peut être fausse alors
  ///   que ce champ sert de preuve d'un geste actif en cas de contestation.
  /// - `saisiPar` doit valoir l'uid de l'appelant.
  Map<String, dynamic> toFirestore({required String saisiParUid}) => {
        'individuelle': individuelle,
        'groupe': groupe,
        'etablissement': etablissement,
        'dateConsentement': FieldValue.serverTimestamp(),
        'versionTexte': versionTexte ?? 'v1',
        'saisiPar': saisiParUid,
      };

  ConsentImage copyWith({bool? individuelle, bool? groupe}) => ConsentImage(
        individuelle: individuelle ?? this.individuelle,
        groupe: groupe ?? this.groupe,
        etablissement: etablissement,
        dateConsentement: dateConsentement,
        versionTexte: versionTexte,
        saisiPar: saisiPar,
      );
}
