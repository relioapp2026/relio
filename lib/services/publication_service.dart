import 'dart:developer';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/publication.dart';
import '../models/visibilite_type.dart';
import 'auth_service.dart';
import 'photo_service.dart';

/// La publication a bien été créée, mais ses photos ne sont pas arrivées.
///
/// Ce cas mérite son propre type parce que la conduite à tenir est l'inverse
/// d'un échec ordinaire : **il ne faut surtout pas réessayer**. Le texte du
/// professionnel est en base ; relancer la création produirait un doublon.
/// L'écran doit donc le prévenir, puis se fermer normalement.
class PhotosNonEnvoyeesException implements Exception {
  const PhotosNonEnvoyeesException(this.publicationId, this.cause);

  /// La publication existe réellement, avec son texte, sans ses photos.
  final String publicationId;

  /// L'erreur d'origine (réseau, refus de règle Storage…).
  final Object cause;

  @override
  String toString() =>
      'PhotosNonEnvoyeesException(publication $publicationId créée sans photos : $cause)';
}

/// Une page du feed : les publications lues, et de quoi demander la suivante.
class PagePublications {
  const PagePublications({
    required this.publications,
    required this.dernierDocument,
    required this.finAtteinte,
  });

  final List<Publication> publications;

  /// Curseur à repasser à [PublicationService.chargerPage] pour la page
  /// suivante. `null` quand il n'y a plus rien à charger.
  final DocumentSnapshot<Map<String, dynamic>>? dernierDocument;

  /// Vrai quand Firestore a renvoyé moins que [PublicationService.taillePage] :
  /// il n'y a plus de page après celle-ci.
  final bool finAtteinte;
}

/// Lecture et écriture de la collection `publications`.
///
/// Chantier Publications / étape 1. **Premier chemin d'écriture client d'une
/// vraie collection de contenu** du projet : jusqu'ici seules les collections
/// d'authentification acceptaient une écriture, et le référentiel est en
/// lecture seule par conception.
///
/// ---
/// ### `Future` paginé, pas de `Stream` — décision d'architecture
///
/// Un flux temps réel (`snapshots()`) serait le choix naturel à terme, mais le
/// combiner avec une pagination par curseur est nettement plus complexe qu'un
/// seul des deux. Pour un cahier de liaison, qu'une publication mette deux
/// secondes à apparaître après un tirer-pour-actualiser ne gêne personne.
///
/// Le passage au temps réel est reporté à l'étape 3 (likes/commentaires), où
/// l'instantanéité apporte une vraie valeur — un compteur qui bouge en direct.
///
/// **Ce choix engage Messages, Documents et Agenda** : le même pattern sera
/// réutilisé tel quel pour les trois.
///
/// ---
/// ### Le contresens Firestore à ne pas commettre (rappel de R2)
///
/// Pour une requête de liste, les règles sont évaluées **document par document
/// retourné** — elles ne filtrent pas. Une requête qui ramène ne serait-ce
/// qu'un document hors périmètre échoue **en entier**.
///
/// Chaque lecture ci-dessous borne donc sa requête au périmètre de l'appelant
/// via `cibles`, exactement comme la règle le vérifiera de son côté. Ne jamais
/// requêter large en comptant sur les règles pour restreindre.
class PublicationService {
  PublicationService({FirebaseFirestore? firestore, PhotoService? photoService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _photoService = photoService ?? PhotoService();

  final FirebaseFirestore _firestore;
  final PhotoService _photoService;

  /// Nombre de publications par page.
  ///
  /// 15 : assez pour remplir plusieurs écrans de défilement, assez peu pour
  /// que la première page s'affiche vite sur un réseau d'établissement.
  static const int taillePage = 15;

  /// Plafond Firestore sur `array-contains-any`.
  ///
  /// Sans conséquence au MVP (3 unités + 1 établissement = 4 valeurs côté pro,
  /// 2 usagers + 1 côté famille), mais à connaître avant le multi-unité large :
  /// au-delà, il faudra découper la requête en lots.
  static const int limiteArrayContainsAny = 30;

  CollectionReference<Map<String, dynamic>> get _publications =>
      _firestore.collection('publications');

  /// Vrai si [erreur] est un refus de règle Firestore, par opposition à une
  /// panne réseau ou un bug. Les erreurs ne sont jamais avalées par ce
  /// service : elles remontent telles quelles, à l'appelant de les classer.
  static bool estRefusDePermission(Object erreur) =>
      erreur is FirebaseException && erreur.code == 'permission-denied';

  /// Le périmètre de lecture du compte connecté, tel qu'il alimente
  /// `array-contains-any` sur `cibles`.
  ///
  /// **Doit rester le miroir exact de la fonction `accesLecture()` de
  /// `firestore.rules`.** Si les deux divergent, la requête ramène un document
  /// que la règle refuse, et c'est la requête entière qui échoue — pas une
  /// ligne manquante, un feed vide avec `permission-denied`.
  ///
  /// La fusion des unités, des usagers et de l'établissement dans une seule
  /// liste n'est sûre que parce que les ids sont préfixés par type
  /// (`unite_`, `usager_`, `etab_`) et globalement uniques — décision
  /// verrouillée, voir CLAUDE.md, section « Architecture des données ».
  ///
  /// **Invariant dont dépend l'ordre des tests ci-dessous** : au plus un des
  /// deux champs d'identité est renseigné à un instant donné.
  /// `AuthService.signIn` les vide tous les deux avant d'en poser un, et
  /// `AuthService.signOut` les vide tous les deux. Sans cet invariant, une
  /// session famille ouverte après une session pro renverrait le périmètre du
  /// pro : la requête ramènerait des documents que la règle refuse à la
  /// famille, et **la requête entière échouerait** en `permission-denied` —
  /// pas une ligne manquante, un feed vide avec un cadenas.
  static List<String> perimetreLecture() {
    final pro = AuthService.currentProUser;
    if (pro != null) {
      return [...pro.unitesAcces, pro.etablissementId];
    }

    final famille = AuthService.currentFamilleUser;
    if (famille != null) {
      return [...famille.usagersIds, famille.etablissementId];
    }

    return const [];
  }

  /// Une page du feed, la plus récente d'abord.
  ///
  /// [apres] est le curseur renvoyé par l'appel précédent ; `null` pour la
  /// première page.
  ///
  /// **Nécessite l'index composite** déclaré dans `firestore.indexes.json`
  /// (`cibles` en tableau + `dateCreation` décroissant). Sans lui, Firestore
  /// refuse la requête — ce n'est pas une optimisation, c'est une condition.
  Future<PagePublications> chargerPage({
    DocumentSnapshot<Map<String, dynamic>>? apres,
  }) async {
    final perimetre = perimetreLecture();
    if (perimetre.isEmpty) {
      return const PagePublications(
        publications: [],
        dernierDocument: null,
        finAtteinte: true,
      );
    }

    var requete = _publications
        .where(
          'cibles',
          arrayContainsAny: perimetre.take(limiteArrayContainsAny).toList(),
        )
        .orderBy('dateCreation', descending: true)
        .limit(taillePage);

    if (apres != null) {
      requete = requete.startAfterDocument(apres);
    }

    final snapshot = await requete.get();

    return PagePublications(
      publications: snapshot.docs.map(Publication.fromFirestore).toList(),
      dernierDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
      finAtteinte: snapshot.docs.length < taillePage,
    );
  }

  /// Crée une publication et retourne son id.
  ///
  /// `auteurId` et `auteurNom` viennent du compte connecté, jamais d'un
  /// paramètre : la règle impose `auteurId == request.auth.uid`, et laisser
  /// l'appelant les fournir ouvrirait la porte à une publication signée d'un
  /// collègue.
  ///
  /// Lève une [StateError] si aucun pro n'est connecté, et laisse remonter
  /// [FirebaseException] (`permission-denied` si la règle refuse — unité hors
  /// `unitesAcces`).
  ///
  /// **Une portée établissement exige `peutDiffuserEtablissement` sur le
  /// compte pro** — depuis le 2026-08-16, la permission gate le fil d'actu
  /// comme elle gate déjà les documents et les messages. La règle
  /// `peutCreer()` refuse la création sinon (`permission-denied`) ; côté
  /// interface, le chip « Établissement » est grisé en amont. Voir
  /// CLAUDE.md, section « Permission diffusion établissement », sous-section
  /// « portée étendue ».
  ///
  /// ---
  /// ### Ordre des opérations avec photos (étape 2) : document d'abord
  ///
  /// Le document est créé (`photos: []`), **puis** les photos partent vers
  /// `publications/{id}/…`, **puis** une mise à jour y inscrit les URLs.
  ///
  /// L'ordre inverse — pré-générer l'id, envoyer les photos, créer le document
  /// complet — serait plus élégant : `photos` serait immuable sans règle
  /// supplémentaire. Il a été écarté pour deux raisons. D'abord la règle
  /// Storage n'aurait **rien à vérifier**, le document n'existant pas encore :
  /// n'importe quel pro pourrait déposer des fichiers sous un id inventé.
  /// Ensuite un professionnel qui abandonne après l'envoi laisserait des
  /// fichiers **orphelins et définitifs** — aucun document ne les référence, la
  /// suppression physique est exclue au MVP, et le script de seed a interdiction
  /// de toucher à Storage. Une fuite lente sans personne pour faire le ménage.
  ///
  /// Contrepartie assumée de l'ordre retenu : si l'envoi échoue, la publication
  /// existe en texte seul et [PhotosNonEnvoyeesException] est levée. On ne perd
  /// jamais le texte écrit par le professionnel.
  Future<String> creer({
    required VisibiliteType type,
    required List<String> usagersConcernesIds,
    required String? uniteId,
    required String texte,
    List<Uint8List> photos = const [],
    void Function(int envoyees, int total)? progressionPhotos,
  }) async {
    final pro = AuthService.currentProUser;
    if (pro == null) {
      throw StateError('Aucun professionnel connecté.');
    }

    final publication = Publication(
      id: '',
      auteurId: pro.uid,
      auteurNom: '${pro.prenom} ${pro.nom}',
      typePublication: type,
      usagersConcernesIds: usagersConcernesIds,
      uniteId: uniteId,
      etablissementId: pro.etablissementId,
      cibles: Publication.calculerCibles(
        type: type,
        usagersConcernesIds: usagersConcernesIds,
        uniteId: uniteId,
        etablissementId: pro.etablissementId,
      ),
      texte: texte,
      dateCreation: DateTime.now(),
    );

    final doc = await _publications.add(publication.toFirestoreCreation());

    if (photos.isNotEmpty) {
      try {
        final urls = await _photoService.envoyerPourPublication(
          publicationId: doc.id,
          photos: photos,
          progression: progressionPhotos,
        );
        // Seule écriture autorisée sur `photos`, et une seule fois : la
        // troisième branche du `allow update` exige que la liste soit encore
        // vide. Écrire ce seul champ n'est pas un choix de style — la règle
        // impose `hasOnly(['photos'])`, toucher un champ de plus ferait échouer
        // l'écriture entière.
        await doc.update({'photos': urls});
      } catch (e, pile) {
        // Trace de développement, en plus du message affiché. Sans elle, un
        // refus de règle Storage est indiscernable d'une panne réseau une fois
        // l'application refermée : le 2026-08-19, il a fallu fouiller le
        // logcat Android brut pour retrouver le `403 / -13021` qui expliquait
        // tout.
        log(
          'Envoi des photos échoué pour la publication ${doc.id}',
          name: 'relio.publications',
          error: e,
          stackTrace: pile,
        );
        // La publication existe : on ne laisse pas l'appelant croire à un échec
        // total, sans quoi il réessaierait et créerait un doublon.
        throw PhotosNonEnvoyeesException(doc.id, e);
      }
    }

    return doc.id;
  }

  /// Modifie le texte d'une publication. **Réservé à l'auteur** — la règle le
  /// vérifie, ce n'est pas qu'une affaire d'interface.
  ///
  /// N'écrit que les trois champs autorisés : la règle impose
  /// `hasOnly(['texte', 'modifiee', 'dateModification'])`, donc toucher un
  /// champ de plus ferait échouer l'écriture entière.
  Future<void> modifierTexte({
    required String publicationId,
    required String texte,
  }) {
    return _publications.doc(publicationId).update({
      'texte': texte,
      'modifiee': true,
      'dateModification': FieldValue.serverTimestamp(),
    });
  }

  /// Masque une publication — **soft delete, jamais un `delete()`**.
  ///
  /// Ouvert à l'auteur et aux comptes `peutModerer`. Trace *qui* a masqué et
  /// pourquoi : l'auteur doit pouvoir constater que sa publication a été
  /// retirée, et par qui. Une disparition silencieuse serait inacceptable sur
  /// une plateforme qui diffuse des images d'enfants.
  ///
  /// N'écrit que les quatre champs autorisés par la règle.
  Future<void> masquer({
    required String publicationId,
    String? motif,
  }) {
    final uid = AuthService.currentProUser?.uid;
    if (uid == null) {
      throw StateError('Aucun professionnel connecté.');
    }

    return _publications.doc(publicationId).update({
      'masquee': true,
      'dateMasquage': FieldValue.serverTimestamp(),
      'masqueePar': uid,
      'motifMasquage': motif,
    });
  }
}
