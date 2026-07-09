import 'consultation.dart';
import 'visibilite_type.dart';

/// Modèle correspondant à la collection Firestore `messages`. Même logique
/// de portée que les documents/publications : un ou plusieurs usagers, une
/// unité, ou tout l'établissement.
class Message {
  const Message({
    required this.id,
    required this.contenu,
    required this.portee,
    this.etablissementId,
    this.usagersConcernesIds = const [],
    this.uniteConcerneeId,
    required this.expediteurId,
    required this.expediteurNom,
    required this.dateEnvoi,
    this.destinatairesUids = const [],
    this.consultations = const [],
    this.confirmationsLecture = const [],
  });

  final String id;
  final String contenu;
  final VisibiliteType portee;

  /// Renseigné uniquement si `portee == etablissement`.
  final String? etablissementId;

  /// Ids stables (`mockUsagersCatalogue`) des usagers concernés. Renseigné
  /// uniquement si `portee == individuelle`.
  final List<String> usagersConcernesIds;

  /// Id stable (`mockUnitesCatalogue`) de l'unité concernée. Renseigné
  /// uniquement si `portee == groupe`.
  final String? uniteConcerneeId;

  final String expediteurId;
  final String expediteurNom;
  final DateTime dateEnvoi;

  /// Uids des familles destinataires.
  final List<String> destinatairesUids;

  /// Ouvertures du message par les familles (automatique).
  final List<Consultation> consultations;

  /// Cases "j'ai bien lu et pris connaissance" cochées par les familles.
  final List<ConfirmationLecture> confirmationsLecture;

  Message copyWith({
    List<Consultation>? consultations,
    List<ConfirmationLecture>? confirmationsLecture,
  }) {
    return Message(
      id: id,
      contenu: contenu,
      portee: portee,
      etablissementId: etablissementId,
      usagersConcernesIds: usagersConcernesIds,
      uniteConcerneeId: uniteConcerneeId,
      expediteurId: expediteurId,
      expediteurNom: expediteurNom,
      dateEnvoi: dateEnvoi,
      destinatairesUids: destinatairesUids,
      consultations: consultations ?? this.consultations,
      confirmationsLecture: confirmationsLecture ?? this.confirmationsLecture,
    );
  }
}
