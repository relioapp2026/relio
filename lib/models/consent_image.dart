import 'package:cloud_firestore/cloud_firestore.dart';

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
}
