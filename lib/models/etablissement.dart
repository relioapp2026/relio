import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle correspondant à un document Firestore `etablissements/{id}`.
///
/// Chantier Référentiel / R2 — **lecture seule** : le référentiel se peuple
/// par le script de seed (`tools/seed/`), plus tard par Relio Admin. Aucune
/// écriture cliente n'est autorisée (`allow write: if false` dans
/// `firestore.rules`), d'où l'absence volontaire de `toFirestore`.
class Etablissement {
  const Etablissement({required this.id, required this.nom});

  final String id;
  final String nom;

  /// L'`id` vient **toujours** de `doc.id`, jamais d'un champ du document :
  /// un champ `id` interne pourrait diverger du vrai identifiant.
  ///
  /// Tolérant aux champs absents (voir [ConsentImage.fromMap] pour le motif).
  factory Etablissement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Etablissement(
      id: doc.id,
      nom: data['nom'] as String? ?? '',
    );
  }
}
