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
    this.usagersIds = const [],
    this.uniteId,
    this.etablissementId,
    this.auteurId,
    required this.createdAt,
  });

  final String id;
  final String titre;
  final String description;
  final bool touteLaJournee;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final VisibiliteType type;
  final List<String> usagersIds;
  final String? uniteId;
  final String? etablissementId;
  final String? auteurId;
  final DateTime createdAt;
}
