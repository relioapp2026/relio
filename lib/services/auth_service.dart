import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/famille_user.dart';
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

  /// Le [ProUser] actuellement connecté, renseigné par [signIn] après une
  /// connexion réussie avec `role == "pro"`. `null` tant que personne n'est
  /// connecté. Les écrans pro continuent pour l'instant de lire les mocks
  /// de `mock_data.dart` pour tout ce qui n'est pas l'identité du pro
  /// connecté (voir CLAUDE.md, section « Chantier Back »).
  static ProUser? currentProUser;

  /// Le [FamilleUser] actuellement connecté, renseigné par [signIn] après
  /// une connexion réussie avec `role == "famille"`. `null` tant que
  /// personne n'est connecté. Même statut provisoire que [currentProUser] :
  /// aucun écran ne lit encore ce champ (voir CLAUDE.md, section
  /// « Chantier Back »).
  static FamilleUser? currentFamilleUser;

  /// Connecte l'utilisateur puis charge son document `users/{uid}`, sans
  /// présumer du rôle : retourne un [ProUser] ou un [FamilleUser] selon le
  /// champ `role` trouvé, et alimente respectivement [currentProUser] ou
  /// [currentFamilleUser]. Lève une [FirebaseAuthException] si l'email/mot
  /// de passe est invalide, ou une [StateError] si aucun document
  /// `users/{uid}` n'existe, ou si son `role` n'est ni "pro" ni "famille".
  Future<Object> signIn({
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

    switch (doc.data()!['role']) {
      case 'pro':
        final proUser = ProUser.fromFirestore(doc);
        currentProUser = proUser;
        return proUser;
      case 'famille':
        final familleUser = FamilleUser.fromFirestore(doc);
        currentFamilleUser = familleUser;
        return familleUser;
      default:
        throw StateError('Rôle de compte inconnu ou manquant.');
    }
  }
}
