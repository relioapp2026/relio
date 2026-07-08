/// Consultation d'un document ou d'un message par une famille : qui, et quand.
class Consultation {
  const Consultation({required this.uid, required this.dateConsultation});

  final String uid;
  final DateTime dateConsultation;
}

/// Confirmation de lecture ("j'ai bien lu et pris connaissance") d'un
/// document ou d'un message par une famille : qui, et quand.
class ConfirmationLecture {
  const ConfirmationLecture({required this.uid, required this.dateConfirmation});

  final String uid;
  final DateTime dateConfirmation;
}
