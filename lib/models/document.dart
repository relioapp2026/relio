import 'consultation.dart';
import 'type_document.dart';
import 'visibilite_type.dart';

/// Modèle correspondant à la collection Firestore `documents`. Même logique
/// de portée que les publications et l'agenda : un usager, une unité, ou
/// tout l'établissement (un document peut être envoyé à toutes les familles
/// en même temps).
class Document {
  const Document({
    required this.id,
    required this.titre,
    required this.type,
    required this.description,
    required this.portee,
    this.usagerId,
    this.uniteId,
    required this.envoyePar,
    required this.envoyeParNom,
    required this.dateEnvoi,
    required this.fichierUrl,
    required this.fichierType,
    this.destinatairesUids = const [],
    this.consultations = const [],
    this.confirmationsLecture = const [],
  });

  final String id;
  final String titre;
  final TypeDocument type;
  final String description;
  final VisibiliteType portee;

  /// Id stable (`mockUsagersCatalogue`). Renseigné uniquement si
  /// `portee == individuelle`.
  final String? usagerId;

  /// Id stable (`mockUnitesFamillesCatalogue`, le monde
  /// Documents/Messages/Profil). Renseigné uniquement si
  /// `portee == groupe`.
  final String? uniteId;

  final String envoyePar;
  final String envoyeParNom;
  final DateTime dateEnvoi;

  /// Chemin/URL du fichier (Storage à terme). Mock : simple nom de fichier.
  final String fichierUrl;

  /// Extension du fichier ('pdf', 'png' ou 'jpg'/'jpeg'), pour l'icône.
  final String fichierType;

  /// Uids des familles destinataires (concernées par l'usager/l'unité, ou
  /// toutes les familles de l'établissement).
  final List<String> destinatairesUids;

  /// Ouvertures de la page détail par les familles (automatique).
  final List<Consultation> consultations;

  /// Cases "j'ai bien lu et pris connaissance" cochées par les familles.
  final List<ConfirmationLecture> confirmationsLecture;

  Document copyWith({
    List<Consultation>? consultations,
    List<ConfirmationLecture>? confirmationsLecture,
  }) {
    return Document(
      id: id,
      titre: titre,
      type: type,
      description: description,
      portee: portee,
      usagerId: usagerId,
      uniteId: uniteId,
      envoyePar: envoyePar,
      envoyeParNom: envoyeParNom,
      dateEnvoi: dateEnvoi,
      fichierUrl: fichierUrl,
      fichierType: fichierType,
      destinatairesUids: destinatairesUids,
      consultations: consultations ?? this.consultations,
      confirmationsLecture: confirmationsLecture ?? this.confirmationsLecture,
    );
  }
}
