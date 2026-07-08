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
const mockUsagers = [
  'Lucas Martin',
  'Emma Bernard',
  'Nathan Petit',
  'Chloé Rousseau',
  'Léo Girard',
];

const mockUnites = [
  'Unité Papillons',
  'Unité Étoiles',
  'Unité Soleil',
];

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
];

// Donnée factice : le professionnel connecté (Thomas Martin).
const mockProConnecteUid = 'pro_martin';
const mockProConnecteNom = 'Thomas Martin';

class FamilleInfo {
  const FamilleInfo({required this.nom, required this.usagerNom});

  final String nom;
  final String usagerNom;
}

// Donnée factice : uid -> famille + usager rattaché, pour afficher qui a
// consulté un document/message. À terme : issu des collections Firestore
// `users` / `usagers`.
const mockFamilles = {
  'fam_dubois': FamilleInfo(nom: 'Marie Dubois', usagerNom: 'Lucas'),
  'fam_leroy': FamilleInfo(nom: 'Sophie Leroy', usagerNom: 'Chloé'),
  'fam_petit': FamilleInfo(nom: 'Julien Petit', usagerNom: 'Léa'),
  'fam_moreau': FamilleInfo(nom: 'Nathalie Moreau', usagerNom: 'Tom'),
  'fam_bernard': FamilleInfo(nom: 'Paul Bernard', usagerNom: 'Emma'),
  'fam_rousseau': FamilleInfo(nom: 'Camille Rousseau', usagerNom: 'Hugo'),
  'fam_girard': FamilleInfo(nom: 'David Girard', usagerNom: 'Jules'),
  'fam_fontaine': FamilleInfo(nom: 'Claire Fontaine', usagerNom: 'Noah'),
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

// Donnée factice : unités utilisées par les écrans Documents/Messages
// (mêmes noms que la section "Mes unités" du Profil pro).
const mockUnitesAvecFamilles = [
  'Unité Les Écureuils',
  'Unité Les Papillons',
  'Unité Les Explorateurs',
];

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
const mockUnitesAvecUsagers = [
  UniteAvecUsagers(
    nom: 'Unité Les Écureuils',
    usagers: [
      UsagerUnite(prenom: 'Mathis', nom: 'Lambert', age: 9, avatarColor: AppColors.turquoise),
      UsagerUnite(prenom: 'Inès', nom: 'Fabre', age: 7, avatarColor: AppColors.roseViolet),
      UsagerUnite(prenom: 'Enzo', nom: 'Roux', age: 8, avatarColor: AppColors.marine),
      UsagerUnite(prenom: 'Camille', nom: 'Faure', age: 10, avatarColor: AppColors.turquoise),
      UsagerUnite(prenom: 'Adam', nom: 'Blanchard', age: 6, avatarColor: AppColors.roseViolet),
      UsagerUnite(prenom: 'Lina', nom: 'Gauthier', age: 9, avatarColor: AppColors.marine),
      UsagerUnite(prenom: 'Rayan', nom: 'Perrin', age: 8, avatarColor: AppColors.turquoise),
      UsagerUnite(prenom: 'Jade', nom: 'Morel', age: 11, avatarColor: AppColors.roseViolet),
      UsagerUnite(prenom: 'Nolan', nom: 'Barbier', age: 7, avatarColor: AppColors.marine),
      UsagerUnite(prenom: 'Léna', nom: 'Chevalier', age: 9, avatarColor: AppColors.turquoise),
      UsagerUnite(prenom: 'Timéo', nom: 'Vidal', age: 8, avatarColor: AppColors.roseViolet),
      UsagerUnite(prenom: 'Manon', nom: 'Caron', age: 10, avatarColor: AppColors.marine),
    ],
  ),
  UniteAvecUsagers(
    nom: 'Unité Les Papillons',
    usagers: [
      UsagerUnite(prenom: 'Lucas', nom: 'Dubois', age: 8, avatarColor: AppColors.turquoise),
      UsagerUnite(prenom: 'Chloé', nom: 'Leroy', age: 7, avatarColor: AppColors.roseViolet),
      UsagerUnite(prenom: 'Léa', nom: 'Petit', age: 9, avatarColor: AppColors.marine),
      UsagerUnite(prenom: 'Tom', nom: 'Moreau', age: 6, avatarColor: AppColors.turquoise),
      UsagerUnite(prenom: 'Emma', nom: 'Bernard', age: 8, avatarColor: AppColors.roseViolet),
      UsagerUnite(prenom: 'Hugo', nom: 'Rousseau', age: 10, avatarColor: AppColors.marine),
      UsagerUnite(prenom: 'Jules', nom: 'Girard', age: 7, avatarColor: AppColors.turquoise),
      UsagerUnite(prenom: 'Noah', nom: 'Fontaine', age: 9, avatarColor: AppColors.roseViolet),
    ],
  ),
  UniteAvecUsagers(
    nom: 'Unité Les Explorateurs',
    usagers: [
      UsagerUnite(prenom: 'Maël', nom: 'Bertrand', age: 9, avatarColor: AppColors.marine),
      UsagerUnite(prenom: 'Lou', nom: 'Renard', age: 7, avatarColor: AppColors.turquoise),
      UsagerUnite(prenom: 'Gabriel', nom: 'Marchand', age: 10, avatarColor: AppColors.roseViolet),
      UsagerUnite(prenom: 'Alice', nom: 'Bonnet', age: 8, avatarColor: AppColors.marine),
      UsagerUnite(prenom: 'Léo', nom: 'Fournier', age: 6, avatarColor: AppColors.turquoise),
      UsagerUnite(prenom: 'Juliette', nom: 'Aubert', age: 9, avatarColor: AppColors.roseViolet),
      UsagerUnite(prenom: 'Nino', nom: 'Dumas', age: 8, avatarColor: AppColors.marine),
      UsagerUnite(prenom: 'Anna', nom: 'Guérin', age: 11, avatarColor: AppColors.turquoise),
      UsagerUnite(prenom: 'Victor', nom: 'Leclerc', age: 7, avatarColor: AppColors.roseViolet),
      UsagerUnite(prenom: 'Rose', nom: 'Meunier', age: 9, avatarColor: AppColors.marine),
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
    uniteNom: 'Unité Les Papillons',
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
