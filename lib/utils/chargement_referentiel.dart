import 'dart:async';

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
        refusDePermission = false,
        delaiDepasse = false;

  const ChargementReferentiel.echec(
    this.erreur, {
    required this.refusDePermission,
    this.codeErreur,
    this.delaiDepasse = false,
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

  /// Vrai si la lecture n'a pas abouti dans [delaiMaxLecture].
  final bool delaiDepasse;

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
    if (delaiDepasse) {
      return 'Pas de connexion. Vérifiez votre réseau, puis réessayez.';
    }
    return 'Impossible de charger les informations. Vérifiez votre connexion, '
        'puis réessayez.';
  }
}

/// Au-delà de ce délai, une lecture est considérée comme échouée.
///
/// **Firestore n'expire jamais de lui-même.** Hors connexion, `get()` met
/// l'opération en file d'attente et attend le retour du réseau — sans limite.
/// Sans ce garde-fou, un écran affiche donc un indicateur de chargement qui
/// tourne indéfiniment : ni erreur, ni bouton « Réessayer », ni moyen pour
/// l'utilisateur de comprendre ce qui se passe. Constaté sur Pixel 9a en mode
/// avion.
///
/// 10 secondes : assez long pour un réseau lent dans un bâtiment d'IME, assez
/// court pour ne pas passer pour un blocage. Le cache hors ligne de Firestore
/// répond bien avant ce délai quand il a la donnée, donc ce plafond ne pénalise
/// pas le cas « hors connexion mais déjà consulté ».
const delaiMaxLecture = Duration(seconds: 10);

/// Exécute [action] en classant l'échec éventuel, sans jamais le propager.
///
/// Un écran qui appelle cette fonction ne peut pas planter sur une lecture
/// Firestore : il obtient toujours un [ChargementReferentiel] exploitable.
Future<ChargementReferentiel<T>> chargerReferentiel<T>(
  Future<T> Function() action, {
  Duration delaiMax = delaiMaxLecture,
}) async {
  try {
    return ChargementReferentiel.succes(await action().timeout(delaiMax));
  } on TimeoutException catch (e) {
    return ChargementReferentiel.echec(
      e.toString(),
      refusDePermission: false,
      delaiDepasse: true,
    );
  } catch (e) {
    return ChargementReferentiel.echec(
      e.toString(),
      refusDePermission: ReferentielService.estRefusDePermission(e),
      codeErreur: e is FirebaseException ? e.code : null,
    );
  }
}
