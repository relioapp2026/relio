import 'package:flutter/material.dart';

import '../models/consultation.dart';
import '../models/document.dart';
import '../models/evenement.dart';
import '../models/message.dart';
import '../models/notification.dart';
import '../models/type_document.dart';
import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';

/// Données factices partagées le temps que Firestore soit branché.
/// À terme : usagers filtrés par unites_acces du pro, unités de son
/// établissement.
///
/// -------------------------------------------------------------------------
/// CHANTIER 0 / SESSION A — SOURCE UNIFIÉE AVEC IDS STABLES
/// (+ COMPLÉMENT : fusion du catalogue usagers)
/// -------------------------------------------------------------------------
/// [MockUsager] et [MockUnite] forment le modèle de référence (id stable +
/// attributs), destiné à remplacer à terme les 5 listes qui existaient avant
/// cette session, toutes basées sur des noms : `mockUsagers` (noms
/// complets), `mockUnites` (noms d'unité), `mockUnitesAvecFamilles` (une 3e
/// nomenclature d'unités), `mockUsagersAvecFamilles` (prénoms seuls), et les
/// usagers imbriqués dans `mockUnitesAvecUsagers`.
///
/// Ces 5 symboles existent toujours ci-dessous, avec exactement les mêmes
/// valeurs qu'avant : ils sont maintenant *dérivés* du catalogue à ids
/// stables, pour qu'aucun écran non migré ne casse (la migration des écrans
/// eux-mêmes vers les ids se fait en Session C).
///
/// Les usagers sont réunis dans UN SEUL catalogue (`mockUsagersCatalogue`,
/// ids `usager_001` à `usager_035`) : les 30 usagers historiquement liés à
/// Documents/Messages/Profil, complétés par les 5 usagers historiquement
/// utilisés pour Agenda/Publications (`usager_031` à `usager_035`, ex-
/// `usager_agenda_00X`) — ce sont en réalité les mêmes usagers d'un même
/// établissement.
///
/// CAS DE TEST HOMONYMIE VOLONTAIRE — conservé pour la Session C : deux
/// entrées distinctes s'appellent "Emma Bernard" (`usager_017`, Unité Les
/// Papillons, rattachée à `fam_bernard` ; et `usager_032`, Unité Étoiles du
/// monde Agenda, aucune famille rattachée). Même prénom + nom, ids
/// différents, unités différentes. Ce couple sert à vérifier en Session C
/// qu'un filtrage par id (et non par nom) distingue bien les deux personnes
/// — c'est le bug d'homonymie déjà démontré par l'audit
/// (`agenda_famille_screen.dart` filtre aujourd'hui par nom, pas par id).
///
/// Les UNITÉS, elles, restent dans deux catalogues séparés
/// (`mockUnitesAgendaCatalogue` pour Agenda/Publications — "Unité
/// Papillons", etc. ; `mockUnitesFamillesCatalogue` pour
/// Documents/Messages/Profil — "Unité Les Papillons", etc.) : leurs noms ne
/// coïncident pas terme à terme (ex. "Unité Papillons" ≠ "Unité Les
/// Papillons"). Les fusionner sans trancher lesquelles correspondent
/// vraiment entre elles serait une décision produit, pas une nécessité
/// technique de ce complément — à voir avec Séb si besoin, avant ou pendant
/// la Session C.
/// -------------------------------------------------------------------------

const mockEtablissementId = 'etablissement_horizons';

class MockUnite {
  const MockUnite({required this.id, required this.nom, required this.etablissementId});

  final String id;

  /// Affichage uniquement — ne jamais comparer/filtrer sur ce champ.
  final String nom;
  final String etablissementId;
}

class MockUsager {
  const MockUsager({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.age,
    required this.uniteId,
    required this.avatarColor,
  });

  final String id;
  final String prenom;
  final String nom;
  final int age;

  /// Référence stable vers [MockUnite.id] — jamais un nom d'unité.
  final String uniteId;
  final Color avatarColor;

  /// Affichage uniquement — ne jamais comparer/filtrer sur cette valeur.
  String get nomComplet => '$prenom $nom';
}

// --- Monde Agenda/Publications ---------------------------------------------
// Utilisé par CreateEvenementScreen, CreatePublicationScreen et par les
// `usagersIds`/`uniteId` (en réalité des noms) de `mockEvenements`.

const mockUnitesAgendaCatalogue = [
  MockUnite(id: 'unite_agenda_papillons', nom: 'Unité Papillons', etablissementId: mockEtablissementId),
  MockUnite(id: 'unite_agenda_etoiles', nom: 'Unité Étoiles', etablissementId: mockEtablissementId),
  MockUnite(id: 'unite_agenda_soleil', nom: 'Unité Soleil', etablissementId: mockEtablissementId),
];

/// Ids (dans `mockUsagersCatalogue`, voir plus bas) des 5 usagers
/// historiquement utilisés pour Agenda/Publications — `usager_031` à
/// `usager_035`. Sert uniquement à dériver `mockUsagers` ci-dessous en
/// préservant l'ordre d'origine.
final _uniteIdsAgenda = mockUnitesAgendaCatalogue.map((u) => u.id).toSet();

/// Ancienne liste (noms complets) — dérivée du catalogue fusionné, valeurs
/// identiques à avant : `['Lucas Martin', 'Emma Bernard', 'Nathan Petit',
/// 'Chloé Rousseau', 'Léo Girard']`.
final mockUsagers = mockUsagersCatalogue
    .where((u) => _uniteIdsAgenda.contains(u.uniteId))
    .map((u) => u.nomComplet)
    .toList();

/// Ancienne liste (noms d'unité) — dérivée du catalogue, valeurs identiques
/// à avant : `['Unité Papillons', 'Unité Étoiles', 'Unité Soleil']`.
final mockUnites = mockUnitesAgendaCatalogue.map((u) => u.nom).toList();

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
    usagersIds: const ['Léo Martin'],
    // TEST DATA À NETTOYER (Chantier 0 / Session C1) — "Léo Martin" ne
    // correspond à aucun usager du catalogue fusionné (ni "Léo
    // Fournier"/"Léo Girard", ni "Lucas Martin") : incohérence déjà présente
    // dans les données mock d'origine, antérieure à ce chantier. Décision
    // prise en Session C1 : ne pas deviner à qui cet événement était censé
    // se rattacher (product decision), donc laisser `usagersConcernesIds`
    // vide plutôt que d'inventer un id. À signaler à Séb : soit rattacher
    // evt1 à un usager réel, soit le supprimer des fixtures.
    usagersConcernesIds: ['Léo Martin'].map(resolveUsagerId).whereType<String>().toList(),
    createdAt: _relative(-1),
  ),
  Evenement(
    id: 'evt2',
    titre: 'Atelier cuisine',
    description: "Préparation d'un goûter avec l'unité Étoiles.",
    touteLaJournee: false,
    dateDebut: _relative(3, 10, 0),
    dateFin: _relative(3, 11, 30),
    type: VisibiliteType.groupe,
    uniteId: 'Unité Étoiles',
    uniteConcerneeId: resolveUniteId('Unité Étoiles'),
    createdAt: _relative(-1),
  ),
  Evenement(
    id: 'evt3',
    titre: 'Sortie piscine',
    description: 'Sortie à la piscine municipale avec l\'unité Papillons.',
    touteLaJournee: true,
    dateDebut: _relative(5),
    type: VisibiliteType.groupe,
    uniteId: 'Unité Papillons',
    uniteConcerneeId: resolveUniteId('Unité Papillons'),
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
  // --- Chantier 0 / Session C1 — cas de test homonymie volontaire --------
  // Deux événements individuels pour deux usagers différents qui portent
  // EXACTEMENT le même nom ("Emma Bernard") : usager_017 (Unité Les
  // Papillons, rattachée à fam_bernard) et usager_032 (Unité Étoiles, monde
  // Agenda, aucune famille rattachée — voir Session A-bis). Impossible de
  // les distinguer par nom (`resolveUsagerId('Emma Bernard')` retourne
  // `null`, ambigu) : `usagersConcernesIds` est donc fixé explicitement ici
  // avec le bon id, pas résolu depuis un nom. Sert à prouver que
  // agenda_famille_screen.dart, en filtrant par id, affiche uniquement
  // l'événement du bon usager.
  Evenement(
    id: 'evt5',
    titre: 'Rendez-vous orthophonie',
    description: 'Séance individuelle de suivi avec Emma Bernard (Unité Les Papillons).',
    touteLaJournee: false,
    dateDebut: _relative(4, 15, 0),
    dateFin: _relative(4, 15, 45),
    type: VisibiliteType.individuelle,
    usagersIds: const ['Emma Bernard'],
    usagersConcernesIds: const ['usager_017'],
    createdAt: _relative(-1),
  ),
  Evenement(
    id: 'evt6',
    titre: 'Séance de kinésithérapie',
    description: 'Sortie à la piscine municipale avec Emma Bernard (Unité Étoiles, monde Agenda).',
    touteLaJournee: false,
    dateDebut: _relative(6, 10, 0),
    dateFin: _relative(6, 11, 0),
    type: VisibiliteType.individuelle,
    usagersIds: const ['Emma Bernard'],
    usagersConcernesIds: const ['usager_032'],
    createdAt: _relative(-1),
  ),
];

// Donnée factice : le professionnel connecté (Thomas Martin).
const mockProConnecteUid = 'pro_martin';
const mockProConnecteNom = 'Thomas Martin';

class FamilleInfo {
  const FamilleInfo({required this.nom, required this.usagerId});

  final String nom;

  /// Référence stable vers [MockUsager.id] (voir `mockUsagersCatalogue`) —
  /// remplace l'ancien champ `usagerNom`.
  final String usagerId;

  /// Prénom de l'usager rattaché, dérivé de [usagerId]. Conservé pour ne pas
  /// casser les écrans (Documents/Messages) qui lisent encore `usagerNom`
  /// avant leur migration en Session C.
  String get usagerNom =>
      mockUsagersCatalogue.firstWhere((u) => u.id == usagerId).prenom;
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

/// Retrouve l'uid de la famille rattachée à un usager, à partir de son
/// prénom. Utilisé pour résoudre les destinataires d'un document/message
/// "individuel" ou "groupe" créé depuis le formulaire d'envoi.
String? familleUidPourUsager(String usagerNom) {
  for (final entry in mockFamilles.entries) {
    if (entry.value.usagerNom == usagerNom) return entry.key;
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

// --- Monde Documents/Messages/Profil ----------------------------------------
// Utilisé par Profil (Mes unités), UniteDetailScreen, et par `mockFamilles`
// ci-dessus (les 8 usagers de "Unité Les Papillons" sont volontairement les
// mêmes que ceux rattachés à une famille, pour rester cohérent avec
// Documents/Messages).

const mockUnitesFamillesCatalogue = [
  MockUnite(id: 'unite_ecureuils', nom: 'Unité Les Écureuils', etablissementId: mockEtablissementId),
  MockUnite(id: 'unite_papillons', nom: 'Unité Les Papillons', etablissementId: mockEtablissementId),
  MockUnite(id: 'unite_explorateurs', nom: 'Unité Les Explorateurs', etablissementId: mockEtablissementId),
];

const mockUsagersCatalogue = [
  // Unité Les Écureuils
  MockUsager(id: 'usager_001', prenom: 'Mathis', nom: 'Lambert', age: 9, uniteId: 'unite_ecureuils', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_002', prenom: 'Inès', nom: 'Fabre', age: 7, uniteId: 'unite_ecureuils', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_003', prenom: 'Enzo', nom: 'Roux', age: 8, uniteId: 'unite_ecureuils', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_004', prenom: 'Camille', nom: 'Faure', age: 10, uniteId: 'unite_ecureuils', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_005', prenom: 'Adam', nom: 'Blanchard', age: 6, uniteId: 'unite_ecureuils', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_006', prenom: 'Lina', nom: 'Gauthier', age: 9, uniteId: 'unite_ecureuils', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_007', prenom: 'Rayan', nom: 'Perrin', age: 8, uniteId: 'unite_ecureuils', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_008', prenom: 'Jade', nom: 'Morel', age: 11, uniteId: 'unite_ecureuils', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_009', prenom: 'Nolan', nom: 'Barbier', age: 7, uniteId: 'unite_ecureuils', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_010', prenom: 'Léna', nom: 'Chevalier', age: 9, uniteId: 'unite_ecureuils', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_011', prenom: 'Timéo', nom: 'Vidal', age: 8, uniteId: 'unite_ecureuils', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_012', prenom: 'Manon', nom: 'Caron', age: 10, uniteId: 'unite_ecureuils', avatarColor: AppColors.marine),
  // Unité Les Papillons (rattachés à une famille, voir `mockFamilles`)
  MockUsager(id: 'usager_013', prenom: 'Lucas', nom: 'Dubois', age: 8, uniteId: 'unite_papillons', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_014', prenom: 'Chloé', nom: 'Leroy', age: 7, uniteId: 'unite_papillons', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_015', prenom: 'Léa', nom: 'Petit', age: 9, uniteId: 'unite_papillons', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_016', prenom: 'Tom', nom: 'Moreau', age: 6, uniteId: 'unite_papillons', avatarColor: AppColors.turquoise),
  // CAS DE TEST HOMONYMIE VOLONTAIRE (1/2) — voir aussi usager_032 plus bas :
  // même prénom + nom ("Emma Bernard"), ids différents, unités différentes.
  MockUsager(id: 'usager_017', prenom: 'Emma', nom: 'Bernard', age: 8, uniteId: 'unite_papillons', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_018', prenom: 'Hugo', nom: 'Rousseau', age: 10, uniteId: 'unite_papillons', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_019', prenom: 'Jules', nom: 'Girard', age: 7, uniteId: 'unite_papillons', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_020', prenom: 'Noah', nom: 'Fontaine', age: 9, uniteId: 'unite_papillons', avatarColor: AppColors.roseViolet),
  // Unité Les Explorateurs
  MockUsager(id: 'usager_021', prenom: 'Maël', nom: 'Bertrand', age: 9, uniteId: 'unite_explorateurs', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_022', prenom: 'Lou', nom: 'Renard', age: 7, uniteId: 'unite_explorateurs', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_023', prenom: 'Gabriel', nom: 'Marchand', age: 10, uniteId: 'unite_explorateurs', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_024', prenom: 'Alice', nom: 'Bonnet', age: 8, uniteId: 'unite_explorateurs', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_025', prenom: 'Léo', nom: 'Fournier', age: 6, uniteId: 'unite_explorateurs', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_026', prenom: 'Juliette', nom: 'Aubert', age: 9, uniteId: 'unite_explorateurs', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_027', prenom: 'Nino', nom: 'Dumas', age: 8, uniteId: 'unite_explorateurs', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_028', prenom: 'Anna', nom: 'Guérin', age: 11, uniteId: 'unite_explorateurs', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_029', prenom: 'Victor', nom: 'Leclerc', age: 7, uniteId: 'unite_explorateurs', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_030', prenom: 'Rose', nom: 'Meunier', age: 9, uniteId: 'unite_explorateurs', avatarColor: AppColors.marine),
  // Anciennement "monde Agenda/Publications" (usager_agenda_001..005),
  // fusionnés ici car ce sont en réalité les mêmes usagers d'un même
  // établissement. uniteId pointe vers `mockUnitesAgendaCatalogue` — ces
  // unités restent séparées de celles ci-dessus (voir le commentaire de
  // fusion en tête de fichier).
  MockUsager(id: 'usager_031', prenom: 'Lucas', nom: 'Martin', age: 10, uniteId: 'unite_agenda_papillons', avatarColor: AppColors.turquoise),
  // CAS DE TEST HOMONYMIE VOLONTAIRE (2/2) — homonyme de usager_017
  // ("Emma Bernard" également), aucune famille rattachée, unité différente.
  MockUsager(id: 'usager_032', prenom: 'Emma', nom: 'Bernard', age: 7, uniteId: 'unite_agenda_etoiles', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_033', prenom: 'Nathan', nom: 'Petit', age: 9, uniteId: 'unite_agenda_soleil', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_034', prenom: 'Chloé', nom: 'Rousseau', age: 6, uniteId: 'unite_agenda_papillons', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_035', prenom: 'Léo', nom: 'Girard', age: 8, uniteId: 'unite_agenda_etoiles', avatarColor: AppColors.roseViolet),
];

// Donnée factice : unités utilisées par les écrans Documents/Messages
// (mêmes noms que la section "Mes unités" du Profil pro).
//
// Ancienne liste (noms d'unité) — dérivée du catalogue, valeurs identiques à
// avant : `['Unité Les Écureuils', 'Unité Les Papillons', 'Unité Les
// Explorateurs']`.
final mockUnitesAvecFamilles = mockUnitesFamillesCatalogue.map((u) => u.nom).toList();

/// Prénoms des usagers ayant une famille rattachée (mock), utilisés comme
/// liste d'usagers sélectionnables dans les écrans Documents/Messages.
final mockUsagersAvecFamilles = mockFamilles.values.map((f) => f.usagerNom).toList();

class UsagerUnite {
  const UsagerUnite({
    required this.prenom,
    required this.nom,
    required this.age,
    required this.avatarColor,
  });

  final String prenom;
  final String nom;
  final int age;
  final Color avatarColor;
}

class UniteAvecUsagers {
  const UniteAvecUsagers({required this.nom, required this.usagers});

  final String nom;
  final List<UsagerUnite> usagers;
}

// Donnée factice : usagers de chaque unité du pro connecté, pour le détail
// accessible depuis "Mes unités" dans le Profil. "Unité Les Papillons"
// reprend volontairement les usagers déjà rattachés à une famille dans
// mockFamilles, pour rester cohérent avec Documents/Messages.
//
// Dérivée du catalogue à ids stables (`mockUnitesFamillesCatalogue` /
// `mockUsagersCatalogue`) — même contenu et même ordre qu'avant. Le filtre
// par `uniteId` exclut naturellement les usagers fusionnés du monde Agenda
// (usager_031..035), dont l'uniteId pointe vers `mockUnitesAgendaCatalogue`.
final mockUnitesAvecUsagers = mockUnitesFamillesCatalogue.map((unite) {
  final usagers = mockUsagersCatalogue
      .where((usager) => usager.uniteId == unite.id)
      .map((usager) => UsagerUnite(
            prenom: usager.prenom,
            nom: usager.nom,
            age: usager.age,
            avatarColor: usager.avatarColor,
          ))
      .toList();
  return UniteAvecUsagers(nom: unite.nom, usagers: usagers);
}).toList();

// -----------------------------------------------------------------------
// CHANTIER 0 / SESSION B — résolution nom → id pour les données mock
// -----------------------------------------------------------------------
// Utilisées ci-dessous pour renseigner les nouveaux champs id (en parallèle
// des anciens champs "Nom"/"Ids" qui contiennent en réalité des noms — voir
// les commentaires DEPRECATED dans document.dart/message.dart/evenement.dart)
// et par `VisibiliteSelector` (Session B) pour émettre des ids en plus des
// noms choisis dans l'UI.

/// Résout un nom d'usager (prénom seul ou nom complet, tel que choisi dans
/// l'UI) vers son vrai id stable dans [mockUsagersCatalogue]. Retourne
/// `null` si non résolvable — volontairement prudent face aux homonymes
/// (voir `usager_017`/`usager_032`, "Emma Bernard") : mieux vaut ne pas
/// résoudre que résoudre au hasard.
///
/// Stratégie :
/// 1. Lien famille (`familleUidPourUsager`) : résout un prénom de façon non
///    ambiguë pour le monde Documents/Messages/Profil (chaque prénom de
///    `mockFamilles` désigne un usager précis, indépendamment des
///    homonymes qui peuvent exister ailleurs dans le catalogue).
/// 2. Sinon, recherche d'un nom complet unique dans le catalogue fusionné —
///    si 0 ou plusieurs usagers correspondent, retourne `null`.
String? resolveUsagerId(String nomOuPrenom) {
  final familleUid = familleUidPourUsager(nomOuPrenom);
  if (familleUid != null) return mockFamilles[familleUid]!.usagerId;

  final correspondances =
      mockUsagersCatalogue.where((u) => u.nomComplet == nomOuPrenom).toList();
  return correspondances.length == 1 ? correspondances.first.id : null;
}

/// Résout un nom d'unité (tel que choisi dans l'UI) vers son vrai id
/// stable, en cherchant dans les deux catalogues d'unités (Agenda et
/// Documents/Messages/Profil — voir la note de fusion en tête de fichier).
/// Les deux nomenclatures ne se recoupant jamais en tant que chaînes
/// exactes, la recherche combinée est sans ambiguïté. Retourne `null` si
/// aucune unité ne correspond.
String? resolveUniteId(String nom) {
  final correspondances = [
    ...mockUnitesAgendaCatalogue,
    ...mockUnitesFamillesCatalogue,
  ].where((u) => u.nom == nom).toList();
  return correspondances.length == 1 ? correspondances.first.id : null;
}

final mockDocuments = [
  Document(
    id: 'doc1',
    titre: 'Autorisation sortie – Zoo',
    type: TypeDocument.autorisationSortie,
    description: 'Autorisation pour la sortie au Zoo de la Tête d\'Or le 25 mai de 9h à 16h.',
    portee: VisibiliteType.groupe,
    uniteNom: 'Unité Les Papillons',
    uniteId: resolveUniteId('Unité Les Papillons'),
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
    usagerNom: 'Lucas',
    usagerId: resolveUsagerId('Lucas'),
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
    usagersIds: const ['Lucas'],
    usagersConcernesIds: ['Lucas'].map(resolveUsagerId).whereType<String>().toList(),
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
        'Rappel : la sortie piscine de l\'unité Les Papillons aura lieu vendredi prochain, prévoir '
        'maillot et serviette.',
    portee: VisibiliteType.groupe,
    uniteId: 'Unité Les Papillons',
    uniteConcerneeId: resolveUniteId('Unité Les Papillons'),
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
    description: "Julie Renard a publié dans l'unité Les Papillons.",
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
    description: "Une sortie piscine a été ajoutée pour l'unité Les Papillons.",
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
