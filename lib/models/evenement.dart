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

  /// DEPRECATED — malgré son nom, contient des NOMS d'usagers (ex:
  /// `['Léo Martin']`), pas des ids. À retirer en Session C au profit de
  /// [usagersConcernesIds].
  final List<String> usagersIds;

  /// DEPRECATED — malgré son nom, contient un NOM d'unité (ex: `'Unité
  /// Étoiles'`), pas un id. À retirer en Session C au profit de
  /// [uniteConcerneeId].
  final String? uniteId;
  final String? etablissementId;
  final String? auteurId;

  /// Chantier 0 / Session B — vrais ids stables (`mockUsagersCatalogue`),
  /// résolus depuis [usagersIds]. Vide si non résolvable (nom absent du
  /// catalogue, ou homonyme ambigu). À utiliser à la place de [usagersIds]
  /// dès la migration des écrans (Session C).
  final List<String> usagersConcernesIds;

  /// Chantier 0 / Session B — vrai id stable (`mockUnitesAgendaCatalogue`,
  /// le monde Agenda/Publications), résolu depuis [uniteId]. À utiliser à la
  /// place de [uniteId] dès la migration des écrans (Session C).
  final String? uniteConcerneeId;

  final DateTime createdAt;
}
