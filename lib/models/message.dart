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
    this.usagersIds = const [],
    this.uniteId,
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

  /// DEPRECATED — malgré son nom, contient des NOMS d'usagers (ex:
  /// `['Lucas']`), pas des ids. Renseigné uniquement si
  /// `portee == individuelle`. À retirer en Session C au profit de
  /// [usagersConcernesIds].
  final List<String> usagersIds;

  /// DEPRECATED — malgré son nom, contient un NOM d'unité (ex: `'Unité Les
  /// Papillons'`), pas un id. Renseigné uniquement si `portee == groupe`. À
  /// retirer en Session C au profit de [uniteConcerneeId].
  final String? uniteId;

  /// Renseigné uniquement si `portee == etablissement`.
  final String? etablissementId;

  /// Chantier 0 / Session B — vrais ids stables (`mockUsagersCatalogue`),
  /// résolus depuis [usagersIds]. `null`/absent si non résolvable (nom
  /// absent du catalogue, ou homonyme ambigu). À utiliser à la place de
  /// [usagersIds] dès la migration des écrans (Session C).
  final List<String> usagersConcernesIds;

  /// Chantier 0 / Session B — vrai id stable (`mockUnitesFamillesCatalogue`,
  /// le monde Documents/Messages/Profil), résolu depuis [uniteId]. À
  /// utiliser à la place de [uniteId] dès la migration des écrans
  /// (Session C).
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
      usagersIds: usagersIds,
      uniteId: uniteId,
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
