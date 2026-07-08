import 'package:flutter/material.dart';

/// Modèle correspondant à la (future) collection Firestore `publications`.
/// Même logique de portée que les documents/messages/agenda : un ou
/// plusieurs usagers, une unité, ou tout l'établissement.
///
/// Créé en Chantier 0 / Session A, câblé au feed en Session C2b
/// (feed_famille_screen.dart / feed_pro_screen.dart, via mockPublications
/// dans mock_data.dart).
class PublicationCommentaire {
  const PublicationCommentaire({
    required this.auteurId,
    required this.auteurNom,
    required this.avatarColor,
    required this.texte,
    required this.date,
  });

  final String auteurId;
  final String auteurNom;

  /// Couleur d'avatar de l'auteur du commentaire (affichage uniquement).
  final Color avatarColor;
  final String texte;
  final DateTime date;
}

class Publication {
  const Publication({
    required this.id,
    required this.auteurId,
    required this.auteurNom,
    required this.avatarColor,
    required this.date,
    required this.typePublication,
    this.usagersConcernesIds = const [],
    this.uniteId,
    this.etablissementId,
    required this.texte,
    this.photos = const [],
    this.likes = const [],
    this.commentaires = const [],
    this.modifiee = false,
    this.dateModification,
    this.masquee = false,
    this.dateMasquage,
  });

  final String id;
  final String auteurId;
  final String auteurNom;

  /// Couleur d'avatar de l'auteur (affichage uniquement).
  final Color avatarColor;
  final DateTime date;

  /// "individuelle" / "groupe" / "etablissement". String (et non
  /// [VisibiliteType], utilisé par Document/Message/Evenement) car demandé
  /// tel quel pour ce modèle — à harmoniser si besoin lors de la migration
  /// des écrans en Session C.
  final String typePublication;

  /// Ids des usagers concernés — renseigné si [typePublication] vaut
  /// "individuelle" (un usager) ou "groupe" (les usagers présents).
  final List<String> usagersConcernesIds;

  /// Renseigné uniquement si [typePublication] == "groupe".
  final String? uniteId;

  /// Renseigné uniquement si [typePublication] == "etablissement".
  final String? etablissementId;

  final String texte;

  /// Urls/chemins des photos (Storage à terme), 1 à 5.
  final List<String> photos;

  /// Uids des personnes ayant liké la publication.
  final List<String> likes;
  final List<PublicationCommentaire> commentaires;

  /// Édition d'une publication déjà publiée.
  final bool modifiee;
  final DateTime? dateModification;

  /// Masquage (modération) sans suppression définitive.
  final bool masquee;
  final DateTime? dateMasquage;
}
