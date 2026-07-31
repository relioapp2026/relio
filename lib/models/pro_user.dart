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
    required this.peutModerer,
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

  /// Autorise le masquage d'une publication ou d'un commentaire **dont on
  /// n'est pas l'auteur** — voir CLAUDE.md, section « Architecture des
  /// données ».
  ///
  /// Volontairement un booléen et non un troisième rôle : un rôle `admin`
  /// obligerait chaque règle, chaque requête et chaque écran à gérer un cas de
  /// plus, là où un booléen ajoute une clause `OR`.
  ///
  /// **Indépendant de [peutDiffuserEtablissement]** — ne jamais coupler les
  /// deux, ni dans le seed, ni dans les règles.
  final bool peutModerer;

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
      // Absent vaut `false` : aucune permission n'est jamais présumée.
      peutModerer: data['peutModerer'] as bool? ?? false,
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
    );
  }
}
