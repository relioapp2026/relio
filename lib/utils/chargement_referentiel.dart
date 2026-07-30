import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/referentiel_service.dart';

/// Résultat d'une lecture du référentiel : une valeur, ou une erreur classée.
///
/// Chantier Référentiel / R3a — extrait de l'écran de diagnostic de R2 avant
/// sa suppression, pour que les dix écrans migrés partagent un seul tri
/// d'erreurs au lieu d'en réimplémenter chacun un.
///
/// **Pourquoi classer plutôt qu'un simple `try/catch`** : un refus de règle
/// Firestore et une panne réseau se présentent tous deux comme une exception,
/// mais ne veulent pas dire la même chose. Le premier signale un périmètre mal
/// borné (un bug qu'il faut corriger), le second une simple absence de
/// connexion (que l'utilisateur peut résoudre lui-même). Les confondre sous un
/// « une erreur est survenue » générique rendrait les deux indiscernables sur
/// le terrain — c'est exactement ce qui avait fait passer à côté du piège de
/// l'id réservé `__xxx__` en R2.
class ChargementReferentiel<T> {
  const ChargementReferentiel.succes(this.valeur)
      : erreur = null,
        codeErreur = null,
        refusDePermission = false;

  const ChargementReferentiel.echec(
    this.erreur, {
    required this.refusDePermission,
    this.codeErreur,
  }) : valeur = null;

  final T? valeur;

  /// Message technique brut. Destiné au diagnostic, pas à l'affichage — voir
  /// [messageUtilisateur].
  final String? erreur;

  /// Code brut de la [FirebaseException], ex. `permission-denied` ou
  /// `unavailable`. `null` si l'échec ne vient pas de Firebase.
  final String? codeErreur;

  /// Vrai si les règles Firestore ont refusé la lecture, par opposition à une
  /// panne réseau, un document malformé ou un bug.
  final bool refusDePermission;

  bool get enEchec => erreur != null;

  /// Message en français destiné à l'écran.
  ///
  /// Reste volontairement vague sur la cause technique côté utilisateur (« vos
  /// droits d'accès ») mais distingue les deux situations, parce que la
  /// conduite à tenir n'est pas la même : réessayer plus tard, ou signaler.
  String get messageUtilisateur {
    if (!enEchec) return '';
    if (refusDePermission) {
      return "Vos droits d'accès ne permettent pas d'afficher ces informations.";
    }
    return 'Impossible de charger les informations. Vérifiez votre connexion, '
        'puis réessayez.';
  }
}

/// Exécute [action] en classant l'échec éventuel, sans jamais le propager.
///
/// Un écran qui appelle cette fonction ne peut pas planter sur une lecture
/// Firestore : il obtient toujours un [ChargementReferentiel] exploitable.
Future<ChargementReferentiel<T>> chargerReferentiel<T>(
  Future<T> Function() action,
) async {
  try {
    return ChargementReferentiel.succes(await action());
  } catch (e) {
    return ChargementReferentiel.echec(
      e.toString(),
      refusDePermission: ReferentielService.estRefusDePermission(e),
      codeErreur: e is FirebaseException ? e.code : null,
    );
  }
}
