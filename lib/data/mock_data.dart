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
/// À terme : usagers filtrés par unitesAcces du pro, unités de son
/// établissement.
///
/// [MockUsager] et [MockUnite] forment le modèle de référence (id stable +
/// attributs). Les usagers sont réunis dans UN SEUL catalogue
/// (`mockUsagersCatalogue`, ids `usager_001` à `usager_035`) et les unités
/// dans UN SEUL catalogue (`mockUnitesCatalogue`, ids `unite_001` à
/// `unite_003` — Proximité/Polyvalence/Orientation, les 3 vraies unités de
/// l'établissement). Les anciens catalogues séparés `mockUnitesAgendaCatalogue`
/// (Agenda/Publications) et `mockUnitesFamillesCatalogue`
/// (Documents/Messages/Profil), avec leurs noms fictifs non coïncidents
/// ("Unité Papillons" ≠ "Unité Les Papillons"), ont été fusionnés dans ce
/// catalogue unique.
///
/// CAS DE TEST HOMONYMIE VOLONTAIRE — conservé : deux entrées distinctes
/// s'appellent "Emma Bernard" (`usager_017`, Unité Polyvalence, rattachée à
/// `fam_bernard` ; et `usager_032`, Unité Orientation, aucune famille
/// rattachée). Même prénom + nom, ids différents, unités différentes. Ce
/// couple sert à vérifier qu'un filtrage par id (et non par nom) distingue
/// bien les deux personnes.
const mockEtablissementId = 'ime_robert_seguy';

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
    this.consentImage = const ConsentImage(),
  });

  final String id;
  final String prenom;
  final String nom;
  final int age;

  /// Référence stable vers [MockUnite.id] — jamais un nom d'unité.
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
// Catalogue unique des 3 vraies unités de l'établissement (remplace les
// anciens catalogues séparés Agenda/Publications et Documents/Messages/
// Profil, dont les noms fictifs ne coïncidaient pas terme à terme).

const mockUnitesCatalogue = [
  MockUnite(id: 'unite_001', nom: 'Unité Proximité', etablissementId: mockEtablissementId),
  MockUnite(id: 'unite_002', nom: 'Unité Polyvalence', etablissementId: mockEtablissementId),
  MockUnite(id: 'unite_003', nom: 'Unité Orientation', etablissementId: mockEtablissementId),
];

/// Noms des 3 unités, pour les sélecteurs (CreatePublicationScreen,
/// CreateEvenementScreen, envoi de document/message).
final mockUnites = mockUnitesCatalogue.map((u) => u.nom).toList();

/// Sous-ensemble volontairement restreint d'usagers (noms complets) pour le
/// sélecteur "usager concerné" de CreatePublicationScreen/
/// CreateEvenementScreen — pas les 35 usagers du catalogue, pour garder ces
/// listes (recherche individuelle, cases "présents") maniables dans la démo.
final mockUsagers = const ['usager_031', 'usager_032', 'usager_033', 'usager_034', 'usager_035']
    .map((id) => findUsagerById(id)!.nomComplet)
    .toList();

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
  // aucune famille rattachée). Impossible de les distinguer par nom
  // (`resolveUsagerId('Emma Bernard')` retourne `null`, ambigu) :
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

  /// Chantier 0 / Session C2a — nom complet de l'usager rattaché, dérivé de
  /// [usagerId]. Utilisé par [familleUidPourUsager] en plus de [usagerNom]
  /// pour que la résolution par lien famille fonctionne aussi bien à partir
  /// d'un prénom seul que d'un nom complet.
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

/// Retrouve l'uid de la famille rattachée à un usager, à partir de son
/// prénom OU de son nom complet (Chantier 0 / Session C2a — élargi pour que
/// les écrans affichant le nom complet dans un sélecteur continuent de
/// résoudre correctement, y compris pour un homonyme comme "Emma Bernard" :
/// la comparaison reste circonscrite aux 8 usagers réellement rattachés à
/// une famille, donc jamais ambiguë, contrairement à une recherche dans tout
/// le catalogue). Utilisé pour résoudre les destinataires d'un
/// document/message "individuel" ou "groupe" créé depuis le formulaire
/// d'envoi.
String? familleUidPourUsager(String usagerNom) {
  for (final entry in mockFamilles.entries) {
    if (entry.value.usagerNom == usagerNom || entry.value.usagerNomComplet == usagerNom) {
      return entry.key;
    }
  }
  return null;
}

/// Chantier 0 / Session C2a — équivalent de [familleUidPourUsager] mais par
/// id stable plutôt que par prénom. À préférer dès qu'un id est disponible
/// (ex: `VisibiliteSelection.usagerConcerneId`) : contrairement à la
/// comparaison de prénoms, celle-ci ne peut pas se tromper d'usager en cas
/// d'homonyme.
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
// Répartition des 35 usagers sur les 3 vraies unités : 10 en Proximité
// (unite_001, usager_001..010), 16 en Polyvalence (unite_002,
// usager_011..026), 9 en Orientation (unite_003, usager_027..035).
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
  // Unité Polyvalence (unite_002)
  MockUsager(id: 'usager_011', prenom: 'Timéo', nom: 'Vidal', age: 8, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_012', prenom: 'Manon', nom: 'Caron', age: 10, uniteId: 'unite_002', avatarColor: AppColors.marine),
  // Rattachés à une famille, voir `mockFamilles`.
  MockUsager(id: 'usager_013', prenom: 'Lucas', nom: 'Dubois', age: 8, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_014', prenom: 'Chloé', nom: 'Leroy', age: 7, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_015', prenom: 'Léa', nom: 'Petit', age: 9, uniteId: 'unite_002', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_016', prenom: 'Tom', nom: 'Moreau', age: 6, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  // CAS DE TEST HOMONYMIE VOLONTAIRE (1/2) — voir aussi usager_032 plus bas :
  // même prénom + nom ("Emma Bernard"), ids différents, unités différentes.
  // Consentement image : tout accepté (saisi par la famille fam_bernard) —
  // volontairement opposé à usager_032 pour prouver que le badge suit l'id,
  // jamais le nom affiché.
  MockUsager(
    id: 'usager_017',
    prenom: 'Emma',
    nom: 'Bernard',
    age: 8,
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
  MockUsager(id: 'usager_018', prenom: 'Hugo', nom: 'Rousseau', age: 10, uniteId: 'unite_002', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_019', prenom: 'Jules', nom: 'Girard', age: 7, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_020', prenom: 'Noah', nom: 'Fontaine', age: 9, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_021', prenom: 'Maël', nom: 'Bertrand', age: 9, uniteId: 'unite_002', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_022', prenom: 'Lou', nom: 'Renard', age: 7, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_023', prenom: 'Gabriel', nom: 'Marchand', age: 10, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_024', prenom: 'Alice', nom: 'Bonnet', age: 8, uniteId: 'unite_002', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_025', prenom: 'Léo', nom: 'Fournier', age: 6, uniteId: 'unite_002', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_026', prenom: 'Juliette', nom: 'Aubert', age: 9, uniteId: 'unite_002', avatarColor: AppColors.roseViolet),
  // Unité Orientation (unite_003)
  MockUsager(id: 'usager_027', prenom: 'Nino', nom: 'Dumas', age: 8, uniteId: 'unite_003', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_028', prenom: 'Anna', nom: 'Guérin', age: 11, uniteId: 'unite_003', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_029', prenom: 'Victor', nom: 'Leclerc', age: 7, uniteId: 'unite_003', avatarColor: AppColors.roseViolet),
  MockUsager(id: 'usager_030', prenom: 'Rose', nom: 'Meunier', age: 9, uniteId: 'unite_003', avatarColor: AppColors.marine),
  // Consentement image : tout accepté — seul cas "sans badge" parmi les 5
  // usagers historiquement utilisés pour Agenda/Publications (usager_031..
  // 035), pour pouvoir tester les deux états du badge dans
  // CreatePublicationScreen.
  MockUsager(
    id: 'usager_031',
    prenom: 'Lucas',
    nom: 'Martin',
    age: 10,
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
    age: 7,
    uniteId: 'unite_003',
    avatarColor: AppColors.roseViolet,
    consentImage: ConsentImage(
      dateConsentement: _relative(-5),
      versionTexte: 'v1',
      saisiPar: mockProConnecteUid,
    ),
  ),
  MockUsager(id: 'usager_033', prenom: 'Nathan', nom: 'Petit', age: 9, uniteId: 'unite_003', avatarColor: AppColors.marine),
  MockUsager(id: 'usager_034', prenom: 'Chloé', nom: 'Rousseau', age: 6, uniteId: 'unite_003', avatarColor: AppColors.turquoise),
  MockUsager(id: 'usager_035', prenom: 'Léo', nom: 'Girard', age: 8, uniteId: 'unite_003', avatarColor: AppColors.roseViolet),
];

/// Prénoms des usagers ayant une famille rattachée (mock). Conservée pour
/// compatibilité ascendante ; les écrans Documents/Messages utilisent
/// désormais [mockUsagersAvecFamillesNomComplet] pour l'affichage (Session
/// C2a — uniformisation avec le sélecteur d'Agenda/Publications).
final mockUsagersAvecFamilles = mockFamilles.values.map((f) => f.usagerNom).toList();

/// Chantier 0 / Session C2a — noms complets (prénom + nom) des usagers ayant
/// une famille rattachée, même ordre que [mockUsagersAvecFamilles]. Affiché
/// dans le sélecteur d'usager d'envoyer_document_screen.dart/
/// envoyer_message_screen.dart pour éviter toute confusion entre usagers de
/// prénom identique (voir usager_017/usager_032, "Emma Bernard") — la
/// résolution vers l'id reste correcte grâce à `familleUidPourUsager`, qui
/// compare maintenant sur le prénom ET le nom complet.
final mockUsagersAvecFamillesNomComplet =
    mockFamilles.values.map((f) => f.usagerNomComplet).toList();

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
  const UniteAvecUsagers({required this.id, required this.nom, required this.usagers});

  /// Id stable (`mockUnitesCatalogue`), à utiliser pour identifier/naviguer
  /// plutôt que sur [nom].
  final String id;
  final String nom;
  final List<UsagerUnite> usagers;
}

// Donnée factice : usagers de chaque unité du pro connecté, pour le détail
// accessible depuis "Mes unités" dans le Profil. L'Unité Polyvalence
// contient volontairement les usagers déjà rattachés à une famille dans
// mockFamilles, pour rester cohérent avec Documents/Messages.
final mockUnitesAvecUsagers = mockUnitesCatalogue.map((unite) {
  final usagers = mockUsagersCatalogue
      .where((usager) => usager.uniteId == unite.id)
      .map((usager) => UsagerUnite(
            prenom: usager.prenom,
            nom: usager.nom,
            age: usager.age,
            avatarColor: usager.avatarColor,
          ))
      .toList();
  return UniteAvecUsagers(id: unite.id, nom: unite.nom, usagers: usagers);
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
/// stable dans [mockUnitesCatalogue]. Retourne `null` si aucune unité ne
/// correspond.
String? resolveUniteId(String nom) {
  final correspondances = mockUnitesCatalogue.where((u) => u.nom == nom).toList();
  return correspondances.length == 1 ? correspondances.first.id : null;
}

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
final mockPublications = [
  Publication(
    id: 'pub1',
    auteurId: resolveAuteurId('Marie Dubois'),
    auteurNom: 'Marie Dubois',
    avatarColor: AppColors.roseViolet,
    date: _ilYA(const Duration(hours: 2)),
    typePublication: 'etablissement',
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
    avatarColor: AppColors.marine,
    date: _ilYA(const Duration(hours: 5)),
    typePublication: 'etablissement',
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
