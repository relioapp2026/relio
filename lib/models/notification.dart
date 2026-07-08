enum TypeNotification {
  nouvellePublication,
  confirmationDocument,
  confirmationMessage,
  nouvelEvenement,
  nouveauDocument,
  nouveauMessage,
}

enum CibleType { publication, document, message, evenement }

/// Modèle correspondant à la collection Firestore `notifications`.
/// Nommée `AppNotification` (et non `Notification`) pour éviter le conflit
/// avec la classe `Notification` du framework Flutter (système de bulles
/// de notification de widgets, `NotificationListener`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.titre,
    required this.description,
    required this.cibleId,
    required this.cibleType,
    required this.destinataireId,
    this.lu = false,
    required this.dateCreation,
  });

  final String id;
  final TypeNotification type;
  final String titre;
  final String description;

  /// Id de l'élément concerné (id de document, de message, ou de la
  /// publication à l'origine de la notification).
  final String cibleId;
  final CibleType cibleType;
  final String destinataireId;
  final bool lu;
  final DateTime dateCreation;

  AppNotification copyWith({bool? lu}) {
    return AppNotification(
      id: id,
      type: type,
      titre: titre,
      description: description,
      cibleId: cibleId,
      cibleType: cibleType,
      destinataireId: destinataireId,
      lu: lu ?? this.lu,
      dateCreation: dateCreation,
    );
  }
}
