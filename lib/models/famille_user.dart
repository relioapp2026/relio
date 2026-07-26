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
    required this.dateCreation,
  });

  final String uid;
  final String nom;
  final String prenom;
  final String email;
  final String etablissementId;
  final List<String> usagersIds;

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
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
    );
  }
}
