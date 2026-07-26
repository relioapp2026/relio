import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pro_user.dart';

/// Point d'entrée unique pour la connexion et la récupération du profil
/// utilisateur réel sur `relio-dev`. Seul le rôle "pro" est géré pour
/// l'instant — voir CLAUDE.md, section « Chantier Back ».
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Le [ProUser] actuellement connecté, renseigné par l'appelant après un
  /// [signInPro] réussi. `null` tant que personne n'est connecté. Les écrans
  /// pro continuent pour l'instant de lire les mocks de `mock_data.dart` —
  /// ce champ existe pour que le vrai profil soit disponible, avant de
  /// migrer chaque écran (voir CLAUDE.md, section « Chantier Back »).
  static ProUser? currentProUser;

  /// Connecte l'utilisateur puis charge son document `users/{uid}`.
  /// Lève une [FirebaseAuthException] si l'email/mot de passe est invalide,
  /// ou une [StateError] si aucun document `users/{uid}` n'existe, ou si
  /// son `role` n'est pas "pro".
  Future<ProUser> signInPro({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw StateError('Aucun profil Relio trouvé pour ce compte.');
    }
    if (doc.data()!['role'] != 'pro') {
      throw StateError('Ce compte n\'est pas un compte professionnel.');
    }

    return ProUser.fromFirestore(doc);
  }
}
