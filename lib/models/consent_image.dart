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
}
