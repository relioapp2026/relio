import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle correspondant à un document Firestore `unites/{id}`.
///
/// Chantier Référentiel / R2 — **lecture seule** (voir [Etablissement] pour
/// le motif de l'absence de `toFirestore`).
class Unite {
  const Unite({
    required this.id,
    required this.nom,
    required this.etablissementId,
    required this.ordre,
  });

  final String id;

  /// Libellé affiché, **source unique**. Décision actée en R1 : ne jamais
  /// concaténer de préfixe (« Unité Proximité »), la valeur est
  /// « Proximité ». Aucune règle ni requête ne dépend de ce champ, seulement
  /// de [id].
  final String nom;

  final String etablissementId;

  /// Ordre d'affichage dans les listes.
  final int ordre;

  /// L'`id` vient toujours de `doc.id`. Tolérant aux champs absents.
  factory Unite.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Unite(
      id: doc.id,
      nom: data['nom'] as String? ?? '',
      etablissementId: data['etablissementId'] as String? ?? '',
      ordre: (data['ordre'] as num?)?.toInt() ?? 0,
    );
  }
}
