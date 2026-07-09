import 'visibilite_type.dart';

/// Modèle correspondant à la collection Firestore `agenda`.
class Evenement {
  const Evenement({
    required this.id,
    required this.titre,
    required this.description,
    required this.touteLaJournee,
    required this.dateDebut,
    this.dateFin,
    required this.type,
    this.etablissementId,
    this.auteurId,
    this.usagersConcernesIds = const [],
    this.uniteConcerneeId,
    required this.createdAt,
  });

  final String id;
  final String titre;
  final String description;
  final bool touteLaJournee;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final VisibiliteType type;
  final String? etablissementId;
  final String? auteurId;

  /// Ids stables (`mockUsagersCatalogue`) des usagers concernés (portée
  /// individuelle). Vide si non résolvable (nom absent du catalogue, ou
  /// homonyme ambigu — voir le cas evt1, "test data à nettoyer" ci-dessus).
  final List<String> usagersConcernesIds;

  /// Id stable (`mockUnitesCatalogue`) de l'unité concernée (portée
  /// groupe).
  final String? uniteConcerneeId;

  final DateTime createdAt;
}
