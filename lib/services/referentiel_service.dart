import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/etablissement.dart';
import '../models/unite.dart';
import '../models/usager.dart';
import '../models/usager_affichage.dart';

/// Lecture du référentiel (`etablissements`, `unites`, `usagers`) depuis
/// Firestore. Chantier Référentiel / R2.
///
/// **Lecture seule.** Ces trois collections sont en `allow write: if false`
/// dans `firestore.rules` : elles se peuplent par le script de seed
/// (`tools/seed/`), plus tard par Relio Admin.
///
/// **`Future`, jamais `Stream`.** Le référentiel ne change pas pendant une
/// session : un flux temps réel coûterait des lectures pour rien. Les flux
/// temps réel seront pour `publications`.
///
/// **Aucun cache à cette étape.** Un cache masquerait les refus de règles
/// pendant la validation. À reconsidérer une fois R3 close, si la mesure de
/// consommation le justifie.
///
/// ---
/// ### Le contresens n°1 sur Firestore, à ne pas commettre ici
///
/// Pour une requête de liste, les règles sont évaluées **document par
/// document retourné** — elles ne filtrent pas. Une requête qui ramène ne
/// serait-ce qu'**un** document hors du périmètre du demandeur échoue **en
/// entier**, avec `permission-denied`.
///
/// Conséquence : chaque méthode ci-dessous contraint sa requête au périmètre
/// de l'appelant (`unitesAcces`, `usagersIds`). Il ne faut **jamais**
/// requêter large en comptant sur les règles pour restreindre le résultat.
class ReferentielService {
  ReferentielService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Plafond Firestore sur `whereIn` / `array-contains-any`.
  ///
  /// Sans conséquence au MVP (3 unités, 1 à 2 usagers par famille), mais à
  /// connaître avant le multi-établissement : au-delà, il faudra découper la
  /// requête en lots et concaténer les résultats.
  static const int limiteWhereIn = 30;

  /// Vrai si [erreur] est un refus de règle Firestore, par opposition à une
  /// panne réseau, un document malformé ou un bug.
  ///
  /// Les erreurs ne sont **jamais avalées** par ce service : elles remontent
  /// telles quelles. Ce helper permet à l'appelant de les classer — c'est ce
  /// qui permet de savoir si un problème vient des règles ou du code.
  static bool estRefusDePermission(Object erreur) =>
      erreur is FirebaseException && erreur.code == 'permission-denied';

  CollectionReference<Map<String, dynamic>> get _etablissements =>
      _firestore.collection('etablissements');
  CollectionReference<Map<String, dynamic>> get _unites => _firestore.collection('unites');
  CollectionReference<Map<String, dynamic>> get _usagers => _firestore.collection('usagers');

  /// `null` si le document n'existe pas. Une lecture hors de l'établissement
  /// du demandeur lève `permission-denied` (elle n'est pas silencieuse).
  Future<Etablissement?> getEtablissement(String id) async {
    final doc = await _etablissements.doc(id).get();
    if (!doc.exists) return null;
    return Etablissement.fromFirestore(doc);
  }

  /// Les unités demandées, **triées par `ordre`**.
  ///
  /// Tri fait côté client volontairement : `whereIn` + `orderBy` imposerait
  /// un index composite, pour au plus quelques documents. Même raisonnement
  /// que le filtrage de `actif` ci-dessous.
  Future<List<Unite>> getUnites(List<String> uniteIds) async {
    if (uniteIds.isEmpty) return const [];

    final snapshot = await _unites
        .where(FieldPath.documentId, whereIn: uniteIds.take(limiteWhereIn).toList())
        .get();

    final unites = snapshot.docs.map(Unite.fromFirestore).toList();
    unites.sort((a, b) => a.ordre.compareTo(b.ordre));
    return unites;
  }

  /// Les usagers **actifs** d'une unité, triés par nom puis prénom.
  ///
  /// Attention : appeler cette méthode avec une unité hors du périmètre du
  /// demandeur lève `permission-denied` sur la requête entière (voir la note
  /// de classe). C'est le comportement attendu, pas un bug.
  Future<List<Usager>> getUsagersParUnite(String uniteId) async {
    final snapshot = await _usagers.where('uniteId', isEqualTo: uniteId).get();
    return _trierEtFiltrer(snapshot.docs);
  }

  /// Les usagers actifs des unités auxquelles le pro a accès.
  ///
  /// La requête est bornée à [unitesAcces] : elle ne peut donc jamais
  /// ramener un document hors périmètre, ce qui ferait échouer l'appel
  /// entier (voir la note de classe).
  Future<List<Usager>> getUsagersPourPro(List<String> unitesAcces) async {
    if (unitesAcces.isEmpty) return const [];

    final snapshot = await _usagers
        .where('uniteId', whereIn: unitesAcces.take(limiteWhereIn).toList())
        .get();
    return _trierEtFiltrer(snapshot.docs);
  }

  /// Les usagers actifs rattachés à un compte famille.
  ///
  /// `usagersIds` est un tableau même à un seul élément (cas fratrie prévu
  /// dès le MVP, voir `FamilleUser`).
  Future<List<Usager>> getUsagersPourFamille(List<String> usagersIds) async {
    if (usagersIds.isEmpty) return const [];

    final snapshot = await _usagers
        .where(FieldPath.documentId, whereIn: usagersIds.take(limiteWhereIn).toList())
        .get();
    return _trierEtFiltrer(snapshot.docs);
  }

  /// `null` si l'usager n'existe pas. Une lecture hors périmètre lève
  /// `permission-denied`.
  Future<Usager?> getUsager(String usagerId) async {
    final doc = await _usagers.doc(usagerId).get();
    if (!doc.exists) return null;
    return Usager.fromFirestore(doc);
  }

  // -------------------------------------------------------------------------
  // Vues d'affichage (chantier Référentiel / R3a)
  //
  // Les écrans consomment ces méthodes-ci, jamais celles qui retournent un
  // `Usager` brut : un écran ne doit pas avoir à savoir que le consentement
  // image vient encore du mock ni comment la couleur d'avatar est dérivée.
  // Toute cette composition vit dans `UsagerAffichage` — un seul endroit à
  // reprendre en R3b.
  // -------------------------------------------------------------------------

  /// Les usagers d'une unité, prêts à afficher.
  Future<List<UsagerAffichage>> getUsagersAffichageParUnite(String uniteId) async =>
      (await getUsagersParUnite(uniteId)).map(UsagerAffichage.composer).toList();

  /// Les usagers des unités du pro, prêts à afficher.
  Future<List<UsagerAffichage>> getUsagersAffichagePourPro(
    List<String> unitesAcces,
  ) async =>
      (await getUsagersPourPro(unitesAcces)).map(UsagerAffichage.composer).toList();

  /// Les usagers rattachés à un compte famille, prêts à afficher.
  Future<List<UsagerAffichage>> getUsagersAffichagePourFamille(
    List<String> usagersIds,
  ) async =>
      (await getUsagersPourFamille(usagersIds)).map(UsagerAffichage.composer).toList();

  /// Un usager précis, prêt à afficher. `null` s'il n'existe pas.
  Future<UsagerAffichage?> getUsagerAffichage(String usagerId) async {
    final usager = await getUsager(usagerId);
    return usager == null ? null : UsagerAffichage.composer(usager);
  }

  /// Écarte les usagers inactifs et trie par nom puis prénom.
  ///
  /// Le filtrage de `actif` est fait **côté client** délibérément : un
  /// `where('actif', isEqualTo: true)` combiné aux autres contraintes
  /// imposerait un index composite dont on n'a pas besoin à cette
  /// volumétrie (55 usagers au maximum).
  List<Usager> _trierEtFiltrer(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final usagers = docs.map(Usager.fromFirestore).where((u) => u.actif).toList();
    usagers.sort((a, b) {
      final parNom = a.nom.compareTo(b.nom);
      return parNom != 0 ? parNom : a.prenom.compareTo(b.prenom);
    });
    return usagers;
  }
}
