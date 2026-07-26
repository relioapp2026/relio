import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/famille_user.dart';
import '../models/pro_user.dart';

/// Point d'entrée unique pour la connexion, l'inscription et la
/// récupération du profil utilisateur réel sur `relio-dev`. Rôles "pro" et
/// "famille" gérés — voir CLAUDE.md, section « Chantier Back ».
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

  /// Crée un compte famille à partir d'un code d'invitation : compte
  /// Firebase Auth, puis document `users/{uid}` (`role: "famille"`) peuplé
  /// avec l'`etablissementId`/`usagerId` trouvés dans
  /// `codes_invitation/{codeInvitation}` (lecture directe par id — la règle
  /// Firestore interdit `list`, voir `firestore.rules`). Alimente
  /// [currentFamilleUser] en cas de succès.
  ///
  /// Lève une [FirebaseAuthException] pour les erreurs de création de
  /// compte classiques (email déjà utilisé, mot de passe trop faible,
  /// email malformé), ou une [StateError] si le code d'invitation est
  /// invalide ou si l'écriture du profil échoue (règle refusée, réseau).
  /// Dans ces deux derniers cas, le compte Auth fraîchement créé est
  /// supprimé pour ne pas laisser d'orphelin.
  Future<FamilleUser> signUpFamille({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String codeInvitation,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    try {
      final codeDoc = await _firestore.collection('codes_invitation').doc(codeInvitation).get();
      if (!codeDoc.exists) {
        throw StateError("Code d'invitation invalide.");
      }

      final codeData = codeDoc.data()!;
      final etablissementId = codeData['etablissementId'] as String;
      final usagerId = codeData['usagerId'] as String;

      await _firestore.collection('users').doc(user.uid).set({
        'role': 'famille',
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'etablissementId': etablissementId,
        'usagersIds': [usagerId],
        'codeInvitationUtilise': codeInvitation,
        'dateCreation': FieldValue.serverTimestamp(),
      });

      final familleUser = FamilleUser(
        uid: user.uid,
        nom: nom,
        prenom: prenom,
        email: email,
        etablissementId: etablissementId,
        usagersIds: [usagerId],
        codeInvitationUtilise: codeInvitation,
        dateCreation: DateTime.now(),
      );
      currentFamilleUser = familleUser;
      return familleUser;
    } catch (e) {
      await user.delete();
      if (e is StateError) rethrow;
      throw StateError('La création du compte a échoué. Merci de réessayer.');
    }
  }
}
