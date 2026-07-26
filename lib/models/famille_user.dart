import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle correspondant à un document Firestore `users/{uid}` pour un
/// compte famille (`role == "famille"`). Voir CLAUDE.md, section
/// « Chantier Back » pour le schéma et la trajectoire de ce champ.
class FamilleUser {
  const FamilleUser({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.etablissementId,
    required this.usagersIds,
    required this.codeInvitationUtilise,
    required this.dateCreation,
  });

  final String uid;
  final String nom;
  final String prenom;
  final String email;
  final String etablissementId;
  final List<String> usagersIds;

  /// Id du document `codes_invitation` utilisé à l'inscription — voir
  /// CLAUDE.md, section « Architecture des données ». Vérifié par la règle
  /// Firestore `users/{userId}` (create) au moment de la création du
  /// compte, jamais modifiable ensuite. Chaîne vide si absent en base
  /// (comptes famille créés à la main en console avant l'ajout de ce
  /// champ).
  final String codeInvitationUtilise;

  final DateTime dateCreation;

  factory FamilleUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FamilleUser(
      uid: doc.id,
      nom: data['nom'] as String,
      prenom: data['prenom'] as String,
      email: data['email'] as String,
      etablissementId: data['etablissementId'] as String,
      usagersIds: List<String>.from(data['usagersIds'] as List),
      codeInvitationUtilise: data['codeInvitationUtilise'] as String? ?? '',
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
    );
  }
}
