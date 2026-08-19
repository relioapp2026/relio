import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compression et envoi des photos vers Cloud Storage.
///
/// Chantier Publications / étape 2. **Premier service Storage du projet** —
/// écrit pour être réutilisé tel quel par Documents et Messages plus tard, d'où
/// la séparation d'avec [PublicationService] : compresser une image et
/// l'envoyer n'a rien de spécifique aux publications.
///
/// ---
/// ### Tout se passe en mémoire, jamais sur des fichiers
///
/// Sur le Web — cible MVP, un collègue pro sur iPhone publie depuis la web app
/// — `flutter_image_compress` ne sait travailler que sur des octets
/// (`compressWithList`) : les méthodes qui prennent un chemin de fichier
/// n'existent pas. Ce service ne manipule donc que des [Uint8List], du choix de
/// la photo jusqu'à l'envoi. Un seul code pour Android et Web, et compatible
/// iOS natif le jour où l'app y sera compilée.
class PhotoService {
  PhotoService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Plus grand côté de la photo après compression, en pixels.
  ///
  /// 1920 : largement au-delà de ce qu'un écran de téléphone affiche, assez
  /// pour un recadrage ou une impression familiale, et huit à quinze fois plus
  /// léger qu'une photo brute de Pixel 9a (3 à 8 Mo).
  static const int coteMax = 1920;

  /// Qualité JPEG. 80 est le palier où l'œil ne distingue plus la compression
  /// sur une photo d'activité, alors que le poids s'effondre.
  static const int qualiteJpeg = 80;

  /// Nombre maximum de photos par publication.
  ///
  /// **Cette valeur est aussi gravée dans les règles** — `storage.rules`
  /// contraint le nom de fichier à `0.jpg`…`4.jpg`, et `firestore.rules` limite
  /// `photos` à 5 entrées. La changer ici seul ne suffirait pas.
  static const int maxPhotos = 5;

  /// Poids attendu après compression : 200 à 600 Ko. Le plafond des règles est
  /// à 2 Mo — une marge, pas une cible.
  static const int _octetsMaxIndicatifs = 2 * 1024 * 1024;

  /// Compresse une photo : JPEG, qualité 80, 1920 px sur le plus grand côté.
  ///
  /// **Le piège de `minWidth`/`minHeight`, à ne pas réintroduire** : malgré
  /// leur nom, ces paramètres garantissent que le résultat reste *au moins*
  /// aussi grand que la boîte donnée. La documentation du package l'illustre :
  /// une image 4000×2000 avec `minWidth: 1920, minHeight: 1080` sort en
  /// **2160×1080**. Leur passer naïvement `1920, 1920` ferait donc sortir une
  /// photo 4032×3024 de Pixel en 2560×1920 — le grand côté à 2560, pas 1920.
  ///
  /// D'où la mesure préalable : on calcule la cible exacte à partir des
  /// dimensions réelles et on la passe telle quelle. Les deux paramètres valant
  /// alors exactement le rapport d'échelle voulu, le résultat est le même quelle
  /// que soit la convention interne du package.
  static Future<Uint8List> compresser(Uint8List source) async {
    final (largeur, hauteur) = await _dimensions(source);
    final (cibleLargeur, cibleHauteur) = cibleRedimensionnement(largeur, hauteur);

    return FlutterImageCompress.compressWithList(
      source,
      minWidth: cibleLargeur,
      minHeight: cibleHauteur,
      quality: qualiteJpeg,
      format: CompressFormat.jpeg,
      // Les métadonnées EXIF sont supprimées. Ce n'est pas un détail
      // technique : une photo prise avec un téléphone embarque les
      // **coordonnées GPS** du lieu de prise de vue, ici un établissement
      // accueillant des enfants en situation de handicap. Elles seraient
      // lisibles par toutes les familles destinataires. C'est le comportement
      // par défaut du package, écrit explicitement pour qu'on ne l'inverse pas
      // par inadvertance.
      keepExif: false,
      // Corollaire obligatoire du point précédent : l'orientation d'une photo
      // de téléphone est portée par l'EXIF. La supprimer sans redresser
      // l'image afficherait toutes les photos verticales couchées.
      autoCorrectionAngle: true,
    );
  }

  /// Dimensions d'une image encodée, **sans la décoder entièrement**.
  ///
  /// `ImageDescriptor.encoded` ne lit que l'en-tête du fichier. Décoder une
  /// photo de Pixel pour connaître sa taille coûterait 4032 × 3024 × 4 octets,
  /// soit près de 50 Mo en mémoire — sur cinq photos, l'application y passe.
  static Future<(int, int)> _dimensions(Uint8List octets) async {
    final tampon = await ui.ImmutableBuffer.fromUint8List(octets);
    final descripteur = await ui.ImageDescriptor.encoded(tampon);
    final dimensions = (descripteur.width, descripteur.height);
    descripteur.dispose();
    tampon.dispose();
    return dimensions;
  }

  /// Dimensions cibles : le plus grand côté ramené à [coteMax], proportions
  /// conservées.
  ///
  /// Une image déjà plus petite est renvoyée inchangée — jamais d'agrandissement
  /// (le package ne le fait pas non plus, mais autant que le calcul le dise).
  ///
  /// Pure et sans dépendance, donc vérifiable à l'œil : c'est elle qui décide
  /// du poids réel de tout ce que l'établissement enverra.
  static (int, int) cibleRedimensionnement(int largeur, int hauteur) {
    final grandCote = largeur > hauteur ? largeur : hauteur;
    if (grandCote <= coteMax || grandCote == 0) return (largeur, hauteur);

    final facteur = coteMax / grandCote;
    return (
      (largeur * facteur).round().clamp(1, coteMax),
      (hauteur * facteur).round().clamp(1, coteMax),
    );
  }

  /// Envoie les photos d'une publication et retourne leurs URLs, dans l'ordre.
  ///
  /// Chemin : `publications/{publicationId}/{index}.jpg`, index de 0 à 4.
  /// **Aucune hiérarchie établissement / unité / usager dans Storage** : la
  /// publication reste la seule source de vérité sur la portée, et
  /// `storage.rules` la relit plutôt que de dupliquer cette logique.
  ///
  /// Le nom d'origine du fichier est délibérément abandonné : une photo peut
  /// arriver nommée `Emma_Bernard_sortie.jpg`, et ce nom se retrouverait dans
  /// un chemin Storage, dans l'URL publique et dans la console. Le prénom d'un
  /// enfant n'a rien à faire dans une URL, et l'ordre est déjà porté par
  /// l'index.
  ///
  /// **Envoi séquentiel, pas parallèle** : sur le wifi d'un établissement, cinq
  /// envois simultanés se gênent plus qu'ils ne s'entraident, et la progression
  /// rapportée à l'écran resterait honnête au prix d'une machinerie inutile.
  ///
  /// [progression] est appelé après chaque photo terminée, avec le nombre
  /// envoyé et le total.
  Future<List<String>> envoyerPourPublication({
    required String publicationId,
    required List<Uint8List> photos,
    void Function(int envoyees, int total)? progression,
  }) async {
    final urls = <String>[];

    for (var index = 0; index < photos.length; index++) {
      final reference = _storage.ref('publications/$publicationId/$index.jpg');

      await reference.putData(
        photos[index],
        // Indispensable, pas décoratif : sans métadonnées explicites, Storage
        // enregistre `application/octet-stream`, et la règle d'écriture — qui
        // exige `image/jpeg` — refuserait l'envoi.
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // L'URL de téléchargement est enregistrée dans le document publication
      // (option retenue le 2026-08-19). Le feed affiche les images directement
      // depuis cette URL : aucune évaluation de règle, aucune lecture Firestore
      // supplémentaire à chaque affichage.
      //
      // Contrepartie assumée et documentée dans CLAUDE.md : cette URL porte son
      // propre jeton et fonctionne ensuite sans authentification. Masquer une
      // publication ne la révoque pas. L'échappatoire en cas d'incident réel est
      // la régénération du jeton depuis la console Firebase.
      urls.add(await reference.getDownloadURL());

      progression?.call(index + 1, photos.length);
    }

    return urls;
  }

  /// Vrai si [octets] dépasse le plafond accepté par les règles Storage.
  ///
  /// Sert de garde-fou de développement : une photo compressée qui déclenche
  /// cette condition signale que la compression n'a pas fonctionné, pas qu'un
  /// utilisateur a mal agi.
  static bool depasseLePlafond(Uint8List octets) =>
      octets.lengthInBytes >= _octetsMaxIndicatifs;
}
