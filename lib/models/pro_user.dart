import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle correspondant à un document Firestore `users/{uid}` pour un
/// compte professionnel (`role == "pro"`). Voir CLAUDE.md, section
/// « Chantier Back » pour le schéma et la trajectoire de ce champ.
class ProUser {
  const ProUser({
    required this.uid,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.etablissementId,
    required this.unitesAcces,
    required this.peutDiffuserEtablissement,
    required this.dateCreation,
  });

  final String uid;
  final String nom;
  final String prenom;
  final String email;
  final String etablissementId;
  final List<String> unitesAcces;

  /// Autorise la diffusion de documents/messages en portée "établissement"
  /// — voir CLAUDE.md, section « Permission diffusion établissement ».
  final bool peutDiffuserEtablissement;

  final DateTime dateCreation;

  factory ProUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ProUser(
      uid: doc.id,
      nom: data['nom'] as String,
      prenom: data['prenom'] as String,
      email: data['email'] as String,
      etablissementId: data['etablissementId'] as String,
      unitesAcces: List<String>.from(data['unitesAcces'] as List),
      peutDiffuserEtablissement: data['peutDiffuserEtablissement'] as bool? ?? false,
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
    );
  }
}
