import 'package:flutter/material.dart';

import '../models/consent_image.dart';
import '../models/consultation.dart';
import '../models/document.dart';
import '../models/evenement.dart';
import '../models/message.dart';
import '../models/notification.dart';
import '../models/publication.dart';
import '../models/type_document.dart';
import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';

/// Données factices partagées le temps que Firestore soit branché.
///
/// ---
/// ## Chantier Référentiel / R3a — ce que ce fichier n'est plus
///
/// **Le référentiel (établissement, unités, usagers) vit désormais sur
/// Firestore.** Les écrans le lisent via `ReferentielService` et
/// `UsagerAffichage` ; plus aucun d'entre eux ne lit ici l'identité d'un
/// usager. `mockUsagersCatalogue` n'a été conservé que pour **deux ponts
/// temporaires**, explicitement délimités :
///
/// 1. **Le consentement image** — R2 a posé `allow write: if false` sur la
///    collection `usagers`, donc les 55 documents semés portent `consentImage`
///    à `false`. Le lire depuis Firestore afficherait « aucun consentement »
///    partout et casserait **silencieusement** le test du badge d'alerte. Seul
///    `usagerSansAutorisationImage` (et `UsagerAffichage` qui lui délègue) lit
///    encore ce champ ici. Levée prévue : **R3b**.
/// 2. **Le lien usager → famille** (`mockFamilles`, `familleUidPourUsagerId`)
///    — la règle `users/{uid}` n'autorise chacun à lire que son propre
///    document, donc aucune requête ne peut retrouver les comptes famille
///    rattachés à un usager. Levée prévue : **chantier Messagerie**.
///
/// Tout le reste de ce fichier (publications, agenda, documents, messages,
/// notifications) reste factice jusqu'à son propre chantier de câblage.
///
/// ---
/// CAS DE TEST HOMONYMIE VOLONTAIRE — conservé : deux entrées distinctes
/// s'appellent "Emma Bernard" (`usager_017`, Unité Polyvalence, rattachée à
/// `fam_bernard` ; et `usager_032`, Unité Orientation, aucune famille
/// rattachée). Même prénom + nom, ids différents, unités différentes. Ce
/// couple sert à vérifier qu'un filtrage par id (et non par nom) distingue
/// bien les deux personnes.
///
/// Ce catalogue reste le miroir Dart de `tools/seed/data/referentiel.json` et
/// doit lui rester cohérent (mêmes ids, mêmes unités) tant que les deux ponts
/// ci-dessus ne sont pas levés.
const mockEtablissementId = 'etab_001';

// `MockUnite` a été supprimée en R3a : les unités sont lues sur Firestore
// (`Unite`, `ReferentielService.getUnites`). Aucun écran n'a plus besoin d'un
// catalogue d'unités local.

class MockUsager {
  const MockUsager({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.age,
    required this.uniteId,
    required this.avatarColor,
    this.consentImage = const ConsentImage(),
  });

  final String id;
  final String prenom;
  final String nom;
  final int age;

  /// Référence stable vers l'id d'une unité (`unite_001` à `unite_003`) —
  /// jamais un nom d'unité.
  final String uniteId;
  final Color avatarColor;

  /// Autorisation à l'image par type de publication — voir CLAUDE.md,
  /// section « Consentement image (usagers) ». `const ConsentImage()` par
  /// défaut : aucun consentement recueilli tant que la famille (ou un
  /// admin/coordinateur en fallback) n'a pas validé ses choix.
  final ConsentImage consentImage;

  /// Affichage uniquement — ne jamais comparer/filtrer sur cette valeur.
  String get nomComplet => '$prenom $nom';

  MockUsager copyWith({ConsentImage? consentImage}) {
    return MockUsager(
      id: id,
      prenom: prenom,
      nom: nom,
      age: age,
      uniteId: uniteId,
      avatarColor: avatarColor,
      consentImage: consentImage ?? this.consentImage,
    );
  }
}

// --- Unités -------------------------------------------------------------
// Supprimées en R3a. `mockUnitesCatalogue` (les 3 unités), `mockUnites`
// (leurs libellés) et `mockUsagers` (un sous-ensemble de 5 usagers, choisi
// « pour garder les listes maniables en démo ») n'ont plus de consommateur :
// les sélecteurs reçoivent désormais les vraies unités et les vrais usagers
// du périmètre du pro connecté, lus sur Firestore.
//
// Les ids restent `unite_001` à `unite_003`, alignés sur
// `tools/seed/data/referentiel.json`. Rappel R1 : `nom` est la seule source
// du libellé affiché, aucun écran ne doit concaténer « Unité » devant.

// Dates relatives à "maintenant" pour que les événements factices restent
// toujours "à venir", quel que soit le jour d'exécution de l'app.
DateTime _relative(int daysFromNow, [int hour = 0, int minute = 0]) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + daysFromNow, hour, minute);
}

final mockEvenements = [
  Evenement(
    id: 'evt1',
    titre: 'Rendez-vous orthophoniste',
    description: 'Séance individuelle de suivi avec Léo Martin.',
    touteLaJournee: false,
    dateDebut: _relative(2, 14, 0),
    dateFin: _relative(2, 14, 45),
    type: VisibiliteType.individuelle,
    // TEST DATA À NETTOYER (Chantier 0 / Session C1) — l'ancien champ
    // usagersIds valait ['Léo Martin'], qui ne correspond à aucun usager du
    // catalogue fusionné (ni "Léo Fournier"/"Léo Girard", ni "Lucas
    // Martin") : incohérence déjà présente dans les données mock d'origine,
    // antérieure à ce chantier. Décision prise en Session C1 : ne pas
    // deviner à qui cet événement était censé se rattacher (product
    // decision), donc laisser `usagersConcernesIds` vide plutôt que
    // d'inventer un id. À signaler à Séb : soit rattacher evt1 à un usager
    // réel, soit le supprimer des fixtures.
    usagersConcernesIds: const [],
    createdAt: _relative(-1),
  ),
  Evenement(
    id: 'evt2',
    titre: 'Atelier cuisine',
    description: "Préparation d'un goûter avec l'unité Orientation.",
    touteLaJournee: false,
    dateDebut: _relative(3, 10, 0),
    dateFin: _relative(3, 11, 30),
    type: VisibiliteType.groupe,
    uniteConcerneeId: 'unite_003',
    createdAt: _relative(-1),
  ),
  Evenement(
    id: 'evt3',
    titre: 'Sortie piscine',
    description: 'Sortie à la piscine municipale avec l\'unité Polyvalence.',
    touteLaJournee: true,
    dateDebut: _relative(5),
    type: VisibiliteType.groupe,
    uniteConcerneeId: 'unite_002',
    createdAt: _relative(-1),
  ),
  Evenement(
    id: 'evt4',
    titre: 'Fête de fin d\'année',
    description: "Grande fête pour tout l'établissement, familles bienvenues.",
    touteLaJournee: true,
    dateDebut: _relative(10),
    type: VisibiliteType.etablissement,
    createdAt: _relative(-1),
  ),
  // --- Cas de test homonymie volontaire -----------------------------------
  // Deux événements individuels pour deux usagers différents qui portent
  // EXACTEMENT le même nom ("Emma Bernard") : usager_017 (Unité
  // Polyvalence, rattachée à fam_bernard) et usager_032 (Unité Orientation,
  // aucune famille rattachée). Impossible de les distinguer par nom — c'est
  // précisément ce cas qui a fait supprimer la résolution nom → id en R3a.
  // `usagersConcernesIds` est donc fixé explicitement ici avec le bon id,
  // pas résolu depuis un nom. Sert à prouver que agenda_famille_screen.dart,
  // en filtrant par id, affiche uniquement l'événement du bon usager.
  Evenement(
    id: 'evt5',
    titre: 'Rendez-vous orthophonie',
    description: 'Séance individuelle de suivi avec Emma Bernard (Unité Polyvalence).',
    touteLaJournee: false,
    dateDebut: _relative(4, 15, 0),
    dateFin: _relative(4, 15, 45),
    type: VisibiliteType.individuelle,
    usagersConcernesIds: const ['usager_017'],
    createdAt: _relative(-1),
  ),
  Evenement(
    id: 'evt6',
    titre: 'Séance de kinésithérapie',
    description: 'Sortie à la piscine municipale avec Emma Bernard (Unité Orientation).',
    touteLaJournee: false,
    dateDebut: _relative(6, 10, 0),
    dateFin: _relative(6, 11, 0),
    type: VisibiliteType.individuelle,
    usagersConcernesIds: const ['usager_032'],
    createdAt: _relative(-1),
  ),
];

// --- Professionnels -------------------------------------------------------

class MockPro {
  const MockPro({
    required this.id,
    required this.nom,
    this.peutDiffuserEtablissement = false,
  });

  final String id;
  final String nom;

  /// Autorise la diffusion de documents/messages en portée "établissement"
  /// — voir CLAUDE.md, section « Permission diffusion établissement ».
  /// Faux par défaut, positionné manuellement ici pour le MVP (pas
  /// d'interface de gestion avant Relio Admin, Phase 2). Distinct du
  /// consentement image et des publications établissement du fil d'actu,
  /// qui restent ouvertes à tous les pros sans restriction.
  final bool peutDiffuserEtablissement;
}

/// Catalogue mock des comptes pro. Deux comptes coordination/direction ont
/// `peutDiffuserEtablissement` à true, pour valider visuellement les deux
/// états du chip "Établissement" dans EnvoyerDocumentScreen/
/// EnvoyerMessageScreen (voir [VisibiliteSelector.restrictionEtablissementActive]).
const mockProsCatalogue = [
  MockPro(id: 'pro_martin', nom: 'Thomas Martin'),
  MockPro(id: 'pro_coulon', nom: 'Séverine Coulon', peutDiffuserEtablissement: true),
  MockPro(id: 'pro_delattre', nom: 'Marc Delattre', peutDiffuserEtablissement: true),
  MockPro(id: 'greI7Ibic4eZCRNnfFnMCv1pTxw1', nom: 'Esteban', peutDiffuserEtablissement: true),
];

/// Cherche un pro par id dans le catalogue. `null` si absent.
MockPro? findProById(String? id) {
  if (id == null) return null;
  for (final pro in mockProsCatalogue) {
    if (pro.id == id) return pro;
  }
  return null;
}

// Donnée factice : le professionnel connecté. Change uniquement l'id
// ci-dessous pour tester un autre compte du catalogue (ex: 'pro_coulon',
// coordination) puis relance l'app — le nom et la permission de diffusion
// établissement suivent automatiquement.
// TEMPORAIRE - à retirer une fois les écrans migrés vers Firestore réel (mock_data.dart sera retiré dans un chantier ultérieur).
const mockProConnecteUid = 'greI7Ibic4eZCRNnfFnMCv1pTxw1';

String get mockProConnecteNom => findProById(mockProConnecteUid)!.nom;

/// Vrai si le pro connecté peut diffuser en portée établissement
/// (Document/Message) — voir CLAUDE.md, section « Permission diffusion
/// établissement ».
bool get mockProConnectePeutDiffuserEtablissement =>
    findProById(mockProConnecteUid)!.peutDiffuserEtablissement;

class FamilleInfo {
  const FamilleInfo({required this.nom, required this.usagerId});

  final String nom;

  /// Référence stable vers un usager de la collection Firestore `usagers`
  /// (`usager_001` à `usager_055`).
  final String usagerId;

  /// Prénom de l'usager rattaché, dérivé de [usagerId]. Affiché dans les
  /// listes « qui a consulté » de Documents/Messages.
  ///
  /// Lit encore le catalogue mock, comme le reste de `mockFamilles` : ces
  /// écrans partent au chantier Messagerie, pas en R3a (voir l'en-tête de ce
  /// fichier, second pont temporaire).
  String get usagerNom =>
      mockUsagersCatalogue.firstWhere((u) => u.id == usagerId).prenom;

  /// Nom complet de l'usager rattaché, dérivé de [usagerId]. Affiché par les
  /// écrans Documents/Messages et par l'en-tête du Cahier de liaison côté
  /// famille.
  String get usagerNomComplet =>
      mockUsagersCatalogue.firstWhere((u) => u.id == usagerId).nomComplet;
}

// Donnée factice : uid -> famille + usager rattaché, pour afficher qui a
// consulté un document/message. À terme : issu des collections Firestore
// `users` / `usagers`.
const mockFamilles = {
  'fam_dubois': FamilleInfo(nom: 'Marie Dubois', usagerId: 'usager_013'),
  'fam_leroy': FamilleInfo(nom: 'Sophie Leroy', usagerId: 'usager_014'),
  'fam_petit': FamilleInfo(nom: 'Julien Petit', usagerId: 'usager_015'),
  'fam_moreau': FamilleInfo(nom: 'Nathalie Moreau', usagerId: 'usager_016'),
  'fam_bernard': FamilleInfo(nom: 'Paul Bernard', usagerId: 'usager_017'),
  'fam_rousseau': FamilleInfo(nom: 'Camille Rousseau', usagerId: 'usager_018'),
  'fam_girard': FamilleInfo(nom: 'David Girard', usagerId: 'usager_019'),
  'fam_fontaine': FamilleInfo(nom: 'Claire Fontaine', usagerId: 'usager_020'),
};

// Donnée factice : la famille connectée (Marie Dubois, maman de Lucas),
// pour simuler les consultations/confirmations de son point de vue.
const mockFamilleConnecteeUid = 'fam_dubois';

final _toutesLesFamilles = mockFamilles.keys.toList();

/// Retrouve l'uid de la famille rattachée à un usager, par id stable.
///
/// Chantier Référentiel / R3a — la variante par nom (`familleUidPourUsager`)
/// a été supprimée avec `resolveUsagerId` : toute la chaîne d'envoi de
/// document/message porte désormais des ids de bout en bout, ce qui ferme la
/// classe de bug des homonymes (voir `usager_017`/`usager_032`, deux « Emma
/// Bernard » dans deux unités — un nom ne désigne pas un usager).
String? familleUidPourUsagerId(String usagerId) {
  for (final entry in mockFamilles.entries) {
    if (entry.value.usagerId == usagerId) return entry.key;
  }
  return null;
}

/// Nombre de messages concernant cette famille qu'elle n'a pas encore
/// confirmés ("j'ai bien lu"), pour la bulle de l'icône messagerie.
int messagesNonConfirmesPour(String familleUid) {
  return mockMessages.where((message) {
    if (!message.destinatairesUids.contains(familleUid)) return false;
    return !message.confirmationsLecture.any((c) => c.uid == familleUid);
  }).length;
}

// --- Usagers --------------------------------------------------------------
// Utilisé par Profil (Mes unités), UniteDetailScreen, et par `mockFamilles`
// ci-dessus (les 8 usagers de l'Unité Polyvalence rattachés à une famille
// sont volontairement les mêmes que ceux référencés par Documents/Messages).

// Plus `const` : quelques usagers ci-dessous ont un `consentImage` explicite
// dont la date se calcule via `_relative(...)` (non constant), voir Chantier
// 0 pour la convention "dates relatives, jamais de date calendaire figée".
// La liste reste mutable pour la même raison qu'un `copyWith`/remplacement
// par index est nécessaire pour enregistrer le résultat de l'écran de
// recueil (voir ConsentImageScreen) — même pattern que `mockNotifications`/
// `mockDocuments`.
// Chantier Référentiel / R1 — répartition des 55 usagers sur les 3 unités,
// alignée sur `tools/seed/data/referentiel.json`. 55 = agrément de l'IME,
// pas l'effectif du jour : semer à pleine charge évite de découvrir un
// problème de liste longue le jour où l'établissement est complet.
//   unite_001 Proximité   : 14 (usager_001..010 + usager_036..039)
//   unite_002 Polyvalence : 27 (usager_011..026 + usager_040..050)
//   unite_003 Orientation : 14 (usager_027..035 + usager_051..055)
// Le déséquilibre est intentionnel : il reproduit la structure réelle et
// fait apparaître les problèmes de listes longues et de pagination qu'une
// répartition égale masquerait.
//
// `age` dérive de `anneeNaissance` (la valeur de référence, côté
// referentiel.json) : age = 2026 - anneeNaissance. Le champ reste `age` ici
// pour ne pas casser les écrans qui l'affichent — renommage hors périmètre
// R1. Amplitudes par unité : Proximité 5-12 ans, Polyvalence 12-16,
// Orientation 16-20. Les âges de usager_011..035 ont été réécrits en R1
// pour les respecter (ils valaient tous 6-11 ans, incohérent pour une unité
// d'orientation vers l'âge adulte) ; usager_001..010 étaient déjà dans leur
// amplitude et n'ont pas été touchés.
final List<MockUsager> mockUsagersCatalogue = [
  // Unité Proximité (unite_001)
  // Consentement image : tout accepté, saisi par un coordinateur en
  // fallback — sert à tester le cas "aucun badge affiché".
  MockUsager(
    id: 'usager_001',
    prenom: 'Mathis',
    nom: 'Lambert',
    age: 9,
    uniteId: 'unite_001',
    avatarColor: AppColors.turquoise,
    consentImage: ConsentImage(
      individuelle: true,
      groupe: true,
      etablissement: true,
      dateConsentement: _relative(-30),
      versionTexte: 'v1',
      saisiPar: mockProConnecteUid,
    ),
  ),
  // Consentement image : tout refusé explicitement (choix déjà recueilli,
  // pas seulement la valeur par défaut) — sert à tester le badge sur les
  // trois types de publication.
  MockUsager(
    id: 'usager_002',
    prenom: 'Inès',
    nom: 'Fabre',
    age: 7,
    uniteId: 'unite_001',
    avatarColor: AppColors.roseViolet,
    consentImage: ConsentImage(
      dateConsentement: _relative(-20),
      versionTexte: 'v1',
      saisiPar: mockProConnecteUid,
    ),
  ),
  // Consentement image : mixte (individuelle/établissement acceptés, groupe
  // refusé) — sert à tester le badge uniquement sur le type de publication
  // "groupe".
  MockUsager(
    id: 'usager_003',
    prenom: 'Enzo',
    nom: 'Roux',
    age: 8,
    uniteId: 'unite_001',
    avatarColor: AppColors.marine,
    consentImage: ConsentImage(
      individuelle: true,
      groupe: false,
      etablissement: true,
      dateConsentement: _relative(-15),
      versionTexte: 'v1',
      saisiPar: mockProConnecteUid,
    ),
  ),
  MockUsager(id: 'usager_004', prenom: 'Camille', nom: 'Faure', age: 10, uniteId: 'unite_001', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_005', prenom: 'Adam', nom: 'Blanchard', age: 6, uniteId: 'unite_001', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_006', prenom: 'Lina', nom: 'Gauthier', age: 9, uniteId: 'unite_001', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_007', prenom: 'Rayan', nom: 'Perrin', age: 8, uniteId: 'unite_001', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_008', prenom: 'Jade', nom: 'Morel', age: 11, uniteId: 'unite_001', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_009', prenom: 'Nolan', nom: 'Barbier', age: 7, uniteId: 'unite_001', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_010', prenom: 'Léna', nom: 'Chevalier', age: 9, uniteId: 'unite_001', avatarColor: AppColors.turquoise),
  // R1 — complément Proximité pour atteindre l'effectif cible (14).
  MockUsager(id: 'usager_036', prenom: 'Sacha', nom: 'Delaunay', age: 5, uniteId: 'unite_001', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_037', prenom: 'Ambre', nom: 'Colin', age: 12, uniteId: 'unite_001', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_038', prenom: 'Ethan', nom: 'Masson', age: 6, uniteId: 'unite_001', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_039', prenom: 'Zoé', nom: 'Legrand', age: 11, uniteId: 'unite_001', avatarColor: AppColors.roseViolet),
  // Unité Polyvalence (unite_002)
  MockUsager(id: 'usager_011', prenom: 'Timéo', nom: 'Vidal', age: 13, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_012', prenom: 'Manon', nom: 'Caron', age: 14, uniteId: 'unite_002', avatarColor: AppColors.marine),
  // Rattachés à une famille, voir `mockFamilles`.
  MockUsager(id: 'usager_013', prenom: 'Lucas', nom: 'Dubois', age: 12, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_014', prenom: 'Chloé', nom: 'Leroy', age: 13, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_015', prenom: 'Léa', nom: 'Petit', age: 15, uniteId: 'unite_002', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_016', prenom: 'Tom', nom: 'Moreau', age: 12, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  // CAS DE TEST HOMONYMIE VOLONTAIRE (1/2) — voir aussi usager_032 plus bas :
  // même prénom + nom ("Emma Bernard"), ids différents, unités différentes.
  // Consentement image : tout accepté (saisi par la famille fam_bernard) —
  // volontairement opposé à usager_032 pour prouver que le badge suit l'id,
  // jamais le nom affiché.
  MockUsager(
    id: 'usager_017',
    prenom: 'Emma',
    nom: 'Bernard',
    age: 14,
    uniteId: 'unite_002',
    avatarColor: AppColors.roseViolet,
    consentImage: ConsentImage(
      individuelle: true,
      groupe: true,
      etablissement: true,
      dateConsentement: _relative(-10),
      versionTexte: 'v1',
      saisiPar: 'fam_bernard',
    ),
  ),
  MockUsager(id: 'usager_018', prenom: 'Hugo', nom: 'Rousseau', age: 16, uniteId: 'unite_002', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_019', prenom: 'Jules', nom: 'Girard', age: 13, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_020', prenom: 'Noah', nom: 'Fontaine', age: 15, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_021', prenom: 'Maël', nom: 'Bertrand', age: 14, uniteId: 'unite_002', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_022', prenom: 'Lou', nom: 'Renard', age: 12, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_023', prenom: 'Gabriel', nom: 'Marchand', age: 16, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_024', prenom: 'Alice', nom: 'Bonnet', age: 13, uniteId: 'unite_002', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_025', prenom: 'Léo', nom: 'Fournier', age: 12, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_026', prenom: 'Juliette', nom: 'Aubert', age: 15, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  // R1 — complément Polyvalence pour atteindre l'effectif cible (27).
  MockUsager(id: 'usager_040', prenom: 'Yanis', nom: 'Charpentier', age: 12, uniteId: 'unite_002', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_041', prenom: 'Louna', nom: 'Deschamps', age: 14, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_042', prenom: 'Ilan', nom: 'Berger', age: 15, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_043', prenom: 'Maya', nom: 'Lefèvre', age: 13, uniteId: 'unite_002', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_044', prenom: 'Théo', nom: 'Gaillard', age: 16, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_045', prenom: 'Sarah', nom: 'Poirier', age: 12, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_046', prenom: 'Malo', nom: 'Rey', age: 14, uniteId: 'unite_002', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_047', prenom: 'Elsa', nom: 'Baron', age: 15, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_048', prenom: 'Kylian', nom: 'Noël', age: 13, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_049', prenom: 'Norah', nom: 'Vasseur', age: 16, uniteId: 'unite_002', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_050', prenom: 'Axel', nom: 'Guillot', age: 14, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  // Unité Orientation (unite_003)
  MockUsager(id: 'usager_027', prenom: 'Nino', nom: 'Dumas', age: 17, uniteId: 'unite_003', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_028', prenom: 'Anna', nom: 'Guérin', age: 19, uniteId: 'unite_003', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_029', prenom: 'Victor', nom: 'Leclerc', age: 16, uniteId: 'unite_003', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_030', prenom: 'Rose', nom: 'Meunier', age: 18, uniteId: 'unite_003', avatarColor: AppColors.marine),
  // Consentement image : tout accepté — seul cas "sans badge" parmi les 5
  // usagers historiquement utilisés pour Agenda/Publications (usager_031..
  // 035), pour pouvoir tester les deux états du badge dans
  // CreatePublicationScreen.
  MockUsager(
    id: 'usager_031',
    prenom: 'Lucas',
    nom: 'Martin',
    age: 17,
    uniteId: 'unite_003',
    avatarColor: AppColors.turquoise,
    consentImage: ConsentImage(
      individuelle: true,
      groupe: true,
      etablissement: true,
      dateConsentement: _relative(-12),
      versionTexte: 'v1',
      saisiPar: mockProConnecteUid,
    ),
  ),
  // CAS DE TEST HOMONYMIE VOLONTAIRE (2/2) — homonyme de usager_017
  // ("Emma Bernard" également), aucune famille rattachée, unité différente.
  // Consentement image : tout refusé (saisi par un coordinateur en
  // fallback, faute de compte famille) — voir le commentaire sur usager_017.
  MockUsager(
    id: 'usager_032',
    prenom: 'Emma',
    nom: 'Bernard',
    age: 16,
    uniteId: 'unite_003',
    avatarColor: AppColors.roseViolet,
    consentImage: ConsentImage(
      dateConsentement: _relative(-5),
      versionTexte: 'v1',
      saisiPar: mockProConnecteUid,
    ),
  ),
  MockUsager(id: 'usager_033', prenom: 'Nathan', nom: 'Petit', age: 18, uniteId: 'unite_003', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_034', prenom: 'Chloé', nom: 'Rousseau', age: 20, uniteId: 'unite_003', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_035', prenom: 'Léo', nom: 'Girard', age: 19, uniteId: 'unite_003', avatarColor: AppColors.roseViolet),
  // R1 — complément Orientation pour atteindre l'effectif cible (14).
  MockUsager(id: 'usager_051', prenom: 'Océane', nom: 'Maillard', age: 16, uniteId: 'unite_003', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_052', prenom: 'Samuel', nom: 'Bourgeois', age: 18, uniteId: 'unite_003', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_053', prenom: 'Lilou', nom: 'Perez', age: 20, uniteId: 'unite_003', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_054', prenom: 'Antoine', nom: 'Schmitt', age: 17, uniteId: 'unite_003', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_055', prenom: 'Naïa', nom: 'Roussel', age: 19, uniteId: 'unite_003', avatarColor: AppColors.marine),
];

/// Chantier Référentiel / R3a — ids des usagers ayant une famille rattachée.
///
/// Remplace les anciennes listes de noms (`mockUsagersAvecFamilles` /
/// `mockUsagersAvecFamillesNomComplet`, supprimées) : les sélecteurs d'envoi
/// de document/message travaillent désormais sur des ids, plus sur des
/// chaînes affichées.
///
/// **Reste sur le mock — second pont temporaire de R3a.** Firestore ne peut
/// pas répondre à la question « quels usagers ont une famille rattachée » :
/// la règle `users/{uid}` n'autorise chacun à lire que son propre document
/// (`firestore.rules`), donc aucune requête ne peut relier un usager aux
/// comptes famille qui le suivent. À reprendre au chantier Messagerie.
final mockUsagerIdsAvecFamilles =
    mockFamilles.values.map((f) => f.usagerId).toList();

// `UsagerUnite`, `UniteAvecUsagers` et `mockUnitesAvecUsagers` ont été
// supprimés en R3a : « Mes unités » (Profil) et le détail d'une unité lisent
// désormais `ReferentielService.getUnites` et
// `ReferentielService.getUsagersAffichageParUnite`.

// -----------------------------------------------------------------------
// RÉSOLUTION NOM → ID : SUPPRIMÉE EN R3a
// -----------------------------------------------------------------------
// `resolveUsagerId` (et sa dépendance `familleUidPourUsager`) traduisaient un
// nom choisi dans l'UI vers un id stable. Elles retournaient `null` sur un
// homonyme — deux « Emma Bernard » dans deux unités différentes ne peuvent pas
// être départagées par leur nom — ce qui rendait un usager silencieusement
// non sélectionnable.
//
// `VisibiliteSelector` porte désormais des `UsagerAffichage` complets, donc
// des ids, et n'a plus rien à résoudre. Les sélecteurs d'unité fonctionnent de
// la même façon, sur `Unite` plutôt que sur des libellés.

/// Cherche un usager par id dans le catalogue fusionné. `null` si absent
/// (ou si [id] est `null`) — utilisé par le badge de consentement image.
MockUsager? findUsagerById(String? id) {
  if (id == null) return null;
  for (final usager in mockUsagersCatalogue) {
    if (usager.id == id) return usager;
  }
  return null;
}

/// Vrai si [usagerId] n'a pas d'autorisation image pour [type] — sert à
/// afficher le badge d'alerte (informatif, jamais bloquant) sur les écrans
/// de sélection d'usager. Voir CLAUDE.md, section « Consentement image
/// (usagers) ». Toujours `false` pour `etablissement` (pas de sélection
/// d'usager sur ce type).
bool usagerSansAutorisationImage(String? usagerId, {required VisibiliteType type}) {
  final usager = findUsagerById(usagerId);
  if (usager == null) return false;
  return switch (type) {
    VisibiliteType.individuelle => !usager.consentImage.individuelle,
    VisibiliteType.groupe => !usager.consentImage.groupe,
    VisibiliteType.etablissement => false,
  };
}

/// Chantier 0 / Session C2b — résout un nom d'auteur de publication/
/// commentaire vers un id, en cherchant parmi les familles connues
/// (`mockFamilles`, par nom complet) et le pro connecté
/// (`mockProConnecteNom`). Retourne un id `auteur_inconnu_...` si le nom ne
/// correspond à personne de connu.
///
/// Cas réel : "Camille Bernard" (auteure de pub2, commentatrice de pub1)
/// ne correspond à aucune famille ni au pro connecté — un mélange de
/// "Camille Rousseau" et "Paul/Emma Bernard" déjà présent dans les données
/// mock d'origine, antérieur à ce chantier. Plutôt que d'inventer un id
/// réel (ce serait une décision de contenu, pas technique), un id
/// placeholder clairement identifiable est utilisé — à nettoyer avec Séb.
String resolveAuteurId(String nom) {
  if (nom == mockProConnecteNom) return mockProConnecteUid;
  for (final entry in mockFamilles.entries) {
    if (entry.value.nom == nom) return entry.key;
  }
  return 'auteur_inconnu_${nom.toLowerCase().replaceAll(' ', '_')}';
}

// Chantier 0 / Session C2b — publications du feed, migrées des littéraux
// inline de feed_famille_screen.dart/feed_pro_screen.dart vers de vraies
// instances de Publication (modèle créé en Session A). Aucune des deux
// publications d'origine ne mentionnait un usager ou une unité précis dans
// son texte, et les deux s'affichaient déjà sans filtre à tout le monde :
// `typePublication: 'etablissement'` est donc le choix qui reflète le mieux
// leur comportement actuel, plutôt que d'inventer un usager/une unité qui
// ne figure pas dans les données d'origine (décision de contenu, pas
// technique — à revoir avec Séb si ces publications sont en réalité
// destinées à une unité précise).
//
// `likes` n'existait pas avant (seulement un compteur `likeCount`) : la
// liste ci-dessous est un placeholder qui préserve uniquement le nombre
// affiché, pas des identités réelles de personnes ayant liké.
//
// TEMPORAIRE — chantier Publications / étape 1.
// Les deux feeds lisent désormais la vraie collection `publications` sur
// Firestore : cette liste n'alimente plus aucun écran. Elle n'est conservée
// que pour ses COMMENTAIRES de démonstration, qui serviront de fixtures à
// l'étape 3 (likes et commentaires). À supprimer avec `PublicationCommentaire`
// une fois cette étape câblée.
final mockPublications = [
  Publication(
    id: 'pub1',
    auteurId: resolveAuteurId('Marie Dubois'),
    auteurNom: 'Marie Dubois',
    dateCreation: _ilYA(const Duration(hours: 2)),
    typePublication: VisibiliteType.etablissement,
    etablissementId: mockEtablissementId,
    texte: 'Atelier peinture ce matin ! Les enfants ont laissé libre '
        'cours à leur imagination. De magnifiques créations hautes '
        'en couleurs 🎨✨',
    photos: const ['mock_photo_1.png', 'mock_photo_2.png', 'mock_photo_3.png'],
    likes: List.generate(24, (i) => 'like_mock_$i'),
    commentaires: [
      PublicationCommentaire(
        auteurId: resolveAuteurId('Thomas Martin'),
        auteurNom: 'Thomas Martin',
        avatarColor: AppColors.turquoise,
        texte: 'Waouh ! Ils sont vraiment talentueux 👏',
        date: _ilYA(const Duration(hours: 1, minutes: 50)),
      ),
      PublicationCommentaire(
        auteurId: resolveAuteurId('Sophie Leroy'),
        auteurNom: 'Sophie Leroy',
        avatarColor: AppColors.marine,
        texte: 'Les couleurs sont superbes ! Bravo à tous 😊',
        date: _ilYA(const Duration(hours: 1, minutes: 40)),
      ),
      PublicationCommentaire(
        auteurId: resolveAuteurId('Julien Petit'),
        auteurNom: 'Julien Petit',
        avatarColor: AppColors.roseViolet,
        texte: 'Quelle belle énergie créative !',
        date: _ilYA(const Duration(hours: 1, minutes: 30)),
      ),
      PublicationCommentaire(
        auteurId: resolveAuteurId('Nathalie Moreau'),
        auteurNom: 'Nathalie Moreau',
        avatarColor: AppColors.turquoise,
        texte: 'Ça leur fait tellement de bien de créer.',
        date: _ilYA(const Duration(hours: 1, minutes: 20)),
      ),
      PublicationCommentaire(
        auteurId: resolveAuteurId('Camille Bernard'),
        auteurNom: 'Camille Bernard',
        avatarColor: AppColors.marine,
        texte: 'Merci pour le partage, ça fait plaisir à voir !',
        date: _ilYA(const Duration(hours: 1, minutes: 10)),
      ),
    ],
  ),
  Publication(
    id: 'pub2',
    auteurId: resolveAuteurId('Camille Bernard'),
    auteurNom: 'Camille Bernard',
    dateCreation: _ilYA(const Duration(hours: 5)),
    typePublication: VisibiliteType.etablissement,
    etablissementId: mockEtablissementId,
    texte: 'Jardinage au programme cet après-midi ! Plantation de '
        'fleurs et découverte de la nature 🌱🌻',
    photos: const ['mock_photo_1.png'],
    likes: List.generate(18, (i) => 'like_mock_$i'),
    commentaires: [
      PublicationCommentaire(
        auteurId: resolveAuteurId('Julien Petit'),
        auteurNom: 'Julien Petit',
        avatarColor: AppColors.roseViolet,
        texte: 'Super activité en plein air ! 🌿',
        date: _ilYA(const Duration(hours: 4, minutes: 40)),
      ),
      PublicationCommentaire(
        auteurId: resolveAuteurId('Nathalie Moreau'),
        auteurNom: 'Nathalie Moreau',
        avatarColor: AppColors.turquoise,
        texte: 'Ça fait du bien de voir les enfants dehors ! ☀️',
        date: _ilYA(const Duration(hours: 4, minutes: 20)),
      ),
      PublicationCommentaire(
        auteurId: resolveAuteurId('Marie Dubois'),
        auteurNom: 'Marie Dubois',
        avatarColor: AppColors.roseViolet,
        texte: 'Quelle belle idée de sortie !',
        date: _ilYA(const Duration(hours: 4)),
      ),
    ],
  ),
];

final mockDocuments = [
  Document(
    id: 'doc1',
    titre: 'Autorisation sortie – Zoo',
    type: TypeDocument.autorisationSortie,
    description: 'Autorisation pour la sortie au Zoo de la Tête d\'Or le 25 mai de 9h à 16h.',
    portee: VisibiliteType.groupe,
    uniteId: 'unite_002',
    envoyePar: mockProConnecteUid,
    envoyeParNom: mockProConnecteNom,
    dateEnvoi: _relative(-6, 14, 30),
    fichierUrl: 'autorisation_sortie_zoo.pdf',
    fichierType: 'pdf',
    destinatairesUids: _toutesLesFamilles,
    consultations: [
      Consultation(uid: 'fam_dubois', dateConsultation: _relative(-5, 9, 15)),
      Consultation(uid: 'fam_leroy', dateConsultation: _relative(-5, 11, 42)),
      Consultation(uid: 'fam_petit', dateConsultation: _relative(-4, 8, 30)),
      Consultation(uid: 'fam_rousseau', dateConsultation: _relative(-4, 14, 20)),
      Consultation(uid: 'fam_fontaine', dateConsultation: _relative(-3, 10, 5)),
    ],
    confirmationsLecture: [
      ConfirmationLecture(uid: 'fam_dubois', dateConfirmation: _relative(-5, 9, 16)),
      ConfirmationLecture(uid: 'fam_leroy', dateConfirmation: _relative(-5, 11, 43)),
      ConfirmationLecture(uid: 'fam_fontaine', dateConfirmation: _relative(-3, 10, 6)),
    ],
  ),
  Document(
    id: 'doc2',
    titre: 'Compte-rendu activité',
    type: TypeDocument.compteRendu,
    description: "Compte-rendu de l'atelier d'activités sportives organisé cette semaine.",
    portee: VisibiliteType.etablissement,
    envoyePar: mockProConnecteUid,
    envoyeParNom: mockProConnecteNom,
    dateEnvoi: _relative(-8, 10, 15),
    fichierUrl: 'compte_rendu_activite.pdf',
    fichierType: 'pdf',
    destinatairesUids: _toutesLesFamilles,
    consultations: [
      Consultation(uid: 'fam_dubois', dateConsultation: _relative(-7, 18, 0)),
      Consultation(uid: 'fam_leroy', dateConsultation: _relative(-7, 19, 30)),
      Consultation(uid: 'fam_moreau', dateConsultation: _relative(-6, 8, 0)),
      Consultation(uid: 'fam_girard', dateConsultation: _relative(-6, 20, 10)),
      Consultation(uid: 'fam_fontaine', dateConsultation: _relative(-5, 9, 0)),
    ],
    confirmationsLecture: [
      ConfirmationLecture(uid: 'fam_dubois', dateConfirmation: _relative(-7, 18, 1)),
      ConfirmationLecture(uid: 'fam_moreau', dateConfirmation: _relative(-6, 8, 1)),
      ConfirmationLecture(uid: 'fam_fontaine', dateConfirmation: _relative(-5, 9, 1)),
    ],
  ),
  Document(
    id: 'doc3',
    titre: 'Information – Fermeture exceptionnelle',
    type: TypeDocument.information,
    description:
        "L'établissement sera exceptionnellement fermé le 30 mai pour une journée pédagogique. "
        'Merci de prévoir une solution de garde.',
    portee: VisibiliteType.etablissement,
    envoyePar: mockProConnecteUid,
    envoyeParNom: mockProConnecteNom,
    dateEnvoi: _relative(-10, 16, 45),
    fichierUrl: 'information_fermeture.pdf',
    fichierType: 'pdf',
    destinatairesUids: _toutesLesFamilles,
    consultations: [
      Consultation(uid: 'fam_dubois', dateConsultation: _relative(-9, 9, 0)),
      Consultation(uid: 'fam_petit', dateConsultation: _relative(-9, 17, 30)),
      Consultation(uid: 'fam_rousseau', dateConsultation: _relative(-8, 7, 45)),
    ],
    confirmationsLecture: [
      ConfirmationLecture(uid: 'fam_dubois', dateConfirmation: _relative(-9, 9, 1)),
    ],
  ),
  Document(
    id: 'doc4',
    titre: 'Sortie piscine',
    type: TypeDocument.autre,
    description: 'Sortie à la piscine municipale, prévoir maillot et serviette.',
    portee: VisibiliteType.individuelle,
    usagerId: 'usager_013', // Lucas Dubois (fam_dubois)
    envoyePar: mockProConnecteUid,
    envoyeParNom: mockProConnecteNom,
    dateEnvoi: _relative(-2, 9, 20),
    fichierUrl: 'sortie_piscine_info.png',
    fichierType: 'png',
    destinatairesUids: const ['fam_dubois'],
    consultations: [
      Consultation(uid: 'fam_dubois', dateConsultation: _relative(-1, 18, 0)),
    ],
    confirmationsLecture: [
      ConfirmationLecture(uid: 'fam_dubois', dateConfirmation: _relative(-1, 18, 1)),
    ],
  ),
];

final mockMessages = [
  Message(
    id: 'msg1',
    contenu: 'Bonjour, Lucas a très bien mangé ce midi et a beaucoup aimé l\'atelier peinture cet après-midi 🎨',
    portee: VisibiliteType.individuelle,
    usagersConcernesIds: const ['usager_013'], // Lucas Dubois (fam_dubois)
    expediteurId: mockProConnecteUid,
    expediteurNom: mockProConnecteNom,
    dateEnvoi: _relative(-1, 16, 0),
    destinatairesUids: const ['fam_dubois'],
    consultations: const [],
    confirmationsLecture: const [],
  ),
  Message(
    id: 'msg2',
    contenu:
        'Rappel : la sortie piscine de l\'unité Polyvalence aura lieu vendredi prochain, prévoir '
        'maillot et serviette.',
    portee: VisibiliteType.groupe,
    uniteConcerneeId: 'unite_002',
    expediteurId: mockProConnecteUid,
    expediteurNom: mockProConnecteNom,
    dateEnvoi: _relative(-2, 9, 30),
    destinatairesUids: _toutesLesFamilles,
    consultations: [
      Consultation(uid: 'fam_dubois', dateConsultation: _relative(-1, 10, 0)),
      Consultation(uid: 'fam_leroy', dateConsultation: _relative(-1, 12, 0)),
      Consultation(uid: 'fam_petit', dateConsultation: _relative(-1, 14, 0)),
    ],
    confirmationsLecture: [
      ConfirmationLecture(uid: 'fam_dubois', dateConfirmation: _relative(-1, 10, 1)),
    ],
  ),
  Message(
    id: 'msg3',
    contenu: "Merci à toutes les familles pour votre participation à la fête de fin d'année, ce fut un moment magnifique !",
    portee: VisibiliteType.etablissement,
    expediteurId: mockProConnecteUid,
    expediteurNom: mockProConnecteNom,
    dateEnvoi: _relative(-4, 18, 0),
    destinatairesUids: _toutesLesFamilles,
    consultations: [
      Consultation(uid: 'fam_dubois', dateConsultation: _relative(-3, 9, 0)),
      Consultation(uid: 'fam_rousseau', dateConsultation: _relative(-3, 20, 0)),
    ],
    confirmationsLecture: [
      ConfirmationLecture(uid: 'fam_dubois', dateConfirmation: _relative(-3, 9, 1)),
      ConfirmationLecture(uid: 'fam_rousseau', dateConfirmation: _relative(-3, 20, 1)),
    ],
  ),
];

// Un instant dans le passé récent, pour que les notifications factices
// affichent des horodatages relatifs réalistes ("il y a 2h").
DateTime _ilYA(Duration duree) => DateTime.now().subtract(duree);

final mockNotifications = [
  AppNotification(
    id: 'notif1',
    type: TypeNotification.nouvellePublication,
    titre: 'Nouvelle publication',
    description: "Julie Renard a publié dans l'unité Polyvalence.",
    cibleId: 'feed',
    cibleType: CibleType.publication,
    destinataireId: mockProConnecteUid,
    dateCreation: _ilYA(const Duration(hours: 2)),
  ),
  AppNotification(
    id: 'notif2',
    type: TypeNotification.confirmationDocument,
    titre: 'Document confirmé',
    description: 'Marie Dubois a confirmé la lecture de « Autorisation sortie – Zoo ».',
    cibleId: 'doc1',
    cibleType: CibleType.document,
    destinataireId: mockProConnecteUid,
    dateCreation: _ilYA(const Duration(minutes: 40)),
  ),
  AppNotification(
    id: 'notif3',
    type: TypeNotification.confirmationMessage,
    titre: 'Message confirmé',
    description: 'Marie Dubois a confirmé la lecture de votre message.',
    cibleId: 'msg2',
    cibleType: CibleType.message,
    destinataireId: mockProConnecteUid,
    dateCreation: _ilYA(const Duration(hours: 5)),
  ),
  AppNotification(
    id: 'notif6',
    type: TypeNotification.nouvelEvenement,
    titre: 'Nouvel événement',
    description: 'Un rendez-vous orthophoniste a été ajouté pour Léo Martin.',
    cibleId: 'evt1',
    cibleType: CibleType.evenement,
    destinataireId: mockProConnecteUid,
    dateCreation: _ilYA(const Duration(hours: 3)),
  ),
  AppNotification(
    id: 'notif7',
    type: TypeNotification.nouvelEvenement,
    titre: 'Nouvel événement',
    description: "Une sortie piscine a été ajoutée pour l'unité Polyvalence.",
    cibleId: 'evt3',
    cibleType: CibleType.evenement,
    destinataireId: mockProConnecteUid,
    lu: true,
    dateCreation: _ilYA(const Duration(days: 1)),
  ),
  AppNotification(
    id: 'notif4',
    type: TypeNotification.nouvellePublication,
    titre: 'Nouvelle publication',
    description: "Camille Bernard a publié pour tout l'établissement.",
    cibleId: 'feed',
    cibleType: CibleType.publication,
    destinataireId: mockProConnecteUid,
    lu: true,
    dateCreation: _ilYA(const Duration(days: 1, hours: 3)),
  ),
  AppNotification(
    id: 'notif5',
    type: TypeNotification.confirmationDocument,
    titre: 'Document confirmé',
    description: 'Camille Rousseau a confirmé la lecture de « Compte-rendu activité ».',
    cibleId: 'doc2',
    cibleType: CibleType.document,
    destinataireId: mockProConnecteUid,
    lu: true,
    dateCreation: _ilYA(const Duration(days: 2)),
  ),
  AppNotification(
    id: 'notif8',
    type: TypeNotification.nouvellePublication,
    titre: 'Nouvelle publication',
    description: "Thomas Martin a publié pour tout l'établissement.",
    cibleId: 'feed',
    cibleType: CibleType.publication,
    destinataireId: mockFamilleConnecteeUid,
    dateCreation: _ilYA(const Duration(hours: 1)),
  ),
  AppNotification(
    id: 'notif9',
    type: TypeNotification.nouveauDocument,
    titre: 'Nouveau document',
    description: 'Un nouveau document a été envoyé : « Sortie piscine ».',
    cibleId: 'doc4',
    cibleType: CibleType.document,
    destinataireId: mockFamilleConnecteeUid,
    dateCreation: _ilYA(const Duration(hours: 20)),
  ),
  AppNotification(
    id: 'notif10',
    type: TypeNotification.nouveauMessage,
    titre: 'Nouveau message',
    description: 'Vous avez reçu un nouveau message de Thomas Martin.',
    cibleId: 'msg1',
    cibleType: CibleType.message,
    destinataireId: mockFamilleConnecteeUid,
    dateCreation: _ilYA(const Duration(hours: 26)),
  ),
  AppNotification(
    id: 'notif11',
    type: TypeNotification.nouvelEvenement,
    titre: 'Nouvel événement',
    description: "La fête de fin d'année a été ajoutée à l'agenda.",
    cibleId: 'evt4',
    cibleType: CibleType.evenement,
    destinataireId: mockFamilleConnecteeUid,
    lu: true,
    dateCreation: _ilYA(const Duration(days: 2)),
  ),
];

/// Nombre de notifications non lues pour ce destinataire (pro ou famille),
/// pour la bulle de la cloche.
int notificationsNonLuesPour(String destinataireId) {
  return mockNotifications.where((n) => n.destinataireId == destinataireId && !n.lu).length;
}

// --- Cahier de liaison : filtrage par usager --------------------------
// Un élément (événement/message/document) "concerne" un usager s'il est
// individuel et le nomme, de groupe et rattaché à son unité, ou destiné à
// tout l'établissement. Même logique que le filtrage déjà utilisé dans
// agenda_famille_screen.dart, généralisée ici pour être partagée par le
// Cahier de liaison (famille ET pro, tous types de contenus).

List<Evenement> evenementsPourUsager(String usagerId) {
  final uniteId = findUsagerById(usagerId)?.uniteId;
  return mockEvenements.where((evenement) {
    switch (evenement.type) {
      case VisibiliteType.individuelle:
        return evenement.usagersConcernesIds.contains(usagerId);
      case VisibiliteType.groupe:
        return evenement.uniteConcerneeId == uniteId;
      case VisibiliteType.etablissement:
        return true;
    }
  }).toList();
}

List<Message> messagesPourUsager(String usagerId) {
  final uniteId = findUsagerById(usagerId)?.uniteId;
  return mockMessages.where((message) {
    switch (message.portee) {
      case VisibiliteType.individuelle:
        return message.usagersConcernesIds.contains(usagerId);
      case VisibiliteType.groupe:
        return message.uniteConcerneeId == uniteId;
      case VisibiliteType.etablissement:
        return true;
    }
  }).toList();
}

List<Document> documentsPourUsager(String usagerId) {
  final uniteId = findUsagerById(usagerId)?.uniteId;
  return mockDocuments.where((document) {
    switch (document.portee) {
      case VisibiliteType.individuelle:
        return document.usagerId == usagerId;
      case VisibiliteType.groupe:
        return document.uniteId == uniteId;
      case VisibiliteType.etablissement:
        return true;
    }
  }).toList();
}

/// Nombre de messages concernant cet usager que sa famille n'a pas encore
/// confirmés, pour le badge de la tuile Messagerie du Cahier de liaison.
int messagesNonConfirmesPourUsager(String usagerId) {
  final familleUid = familleUidPourUsagerId(usagerId);
  if (familleUid == null) return 0;
  return messagesPourUsager(usagerId)
      .where((message) => !message.confirmationsLecture.any((c) => c.uid == familleUid))
      .length;
}

/// Équivalent de [messagesNonConfirmesPourUsager] pour les documents.
int documentsNonConfirmesPourUsager(String usagerId) {
  final familleUid = familleUidPourUsagerId(usagerId);
  if (familleUid == null) return 0;
  return documentsPourUsager(usagerId)
      .where((document) => !document.confirmationsLecture.any((c) => c.uid == familleUid))
      .length;
}

/// Infos de la famille connectée (mock), pour résoudre son usager rattaché
/// sans répéter `mockFamilles[mockFamilleConnecteeUid]!` partout.
FamilleInfo get mockFamilleConnecteeInfo => mockFamilles[mockFamilleConnecteeUid]!;
