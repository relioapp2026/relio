/// Type d'un document envoyé par un professionnel : autorisation de sortie,
/// compte-rendu, information générale, ou autre.
enum TypeDocument { autorisationSortie, compteRendu, information, autre }

extension TypeDocumentLabel on TypeDocument {
  String get label => switch (this) {
        TypeDocument.autorisationSortie => 'Autorisation de sortie',
        TypeDocument.compteRendu => 'Compte-rendu',
        TypeDocument.information => 'Information',
        TypeDocument.autre => 'Autre',
      };
}
