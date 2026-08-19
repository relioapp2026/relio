import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Visionneuse plein écran des photos d'une publication.
///
/// Ouverte au tap sur une photo du fil (`PublicationCard`), **côté pro comme
/// côté famille** — même composant, aucune distinction de rôle.
///
/// Complète le cadre du fil, elle ne le remplace pas : le fil recadre en 4:5
/// pour garder des cartes de hauteur régulière, ici l'image est montrée
/// **entière** (`BoxFit.contain`), quitte à laisser du vide autour. C'est la
/// raison d'être de cet écran — pouvoir vérifier ce qu'on a publié, ou
/// regarder son enfant sans qu'un bord soit coupé.
///
/// Fond noir, et non marine : c'est la couleur qui laisse le mieux juger des
/// couleurs réelles d'une photo. La charte s'applique au chrome de
/// l'application, pas au fond d'une visionneuse.
///
/// **Le tap a deux effets, selon l'état du zoom** — voir [_tapSurLaPhoto].
///
/// Aucun package ajouté — `InteractiveViewer` et `PageView` sont dans le SDK.
class PhotosPleinEcranScreen extends StatefulWidget {
  const PhotosPleinEcranScreen({
    super.key,
    required this.photos,
    this.indexInitial = 0,
  });

  /// URLs de téléchargement, dans le même ordre que dans la publication.
  final List<String> photos;

  /// Photo affichée à l'ouverture — celle sur laquelle l'utilisateur a tapé.
  final int indexInitial;

  @override
  State<PhotosPleinEcranScreen> createState() => _PhotosPleinEcranScreenState();
}

class _PhotosPleinEcranScreenState extends State<PhotosPleinEcranScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;

  /// Un contrôleur de zoom **par photo**, et non un seul partagé : `PageView`
  /// construit aussi les pages voisines, qui hériteraient sinon du zoom de la
  /// page courante.
  late final List<TransformationController> _zooms;

  /// Animation du retour à la taille d'origine.
  ///
  /// Un retour instantané serait brutal sur une photo qu'on vient d'agrandir :
  /// on perdrait le lien visuel entre le détail regardé et la vue d'ensemble.
  late final AnimationController _animationRetourZoom;
  Animation<Matrix4>? _trajetRetour;

  /// Le contrôleur effectivement animé, mémorisé au départ de l'animation.
  ///
  /// Sans lui, changer de photo pendant le retour ferait écrire l'animation
  /// dans le zoom de la **nouvelle** page.
  TransformationController? _zoomAnime;

  late int _index = widget.indexInitial;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.indexInitial);
    _zooms = List.generate(widget.photos.length, (_) => TransformationController());
    _animationRetourZoom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        final trajet = _trajetRetour;
        if (trajet != null) _zoomAnime?.value = trajet.value;
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationRetourZoom.dispose();
    for (final zoom in _zooms) {
      zoom.dispose();
    }
    super.dispose();
  }

  /// Ramène la photo courante à sa taille d'origine, en fondu.
  void _reinitialiserZoom() {
    final zoom = _zooms[_index];
    _zoomAnime = zoom;
    _trajetRetour = Matrix4Tween(
      begin: zoom.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(parent: _animationRetourZoom, curve: Curves.easeOut),
    );
    _animationRetourZoom.forward(from: 0);
  }

  /// Vrai quand la photo courante n'est pas zoomée.
  bool get _photoNonZoomee =>
      _zooms[_index].value.getMaxScaleOnAxis() <= 1.01;

  /// Le tap fait deux choses différentes selon l'état, et jamais les deux à la
  /// fois : **zoomé → retour à la taille d'origine ; non zoomé → fermeture.**
  ///
  /// Fermer directement depuis l'état zoomé ferait perdre d'un coup le cadrage
  /// qu'on venait d'ajuster. Mais ne rien faire du tout, comme dans la première
  /// version, laissait un geste mort : on tape sur la photo, il ne se passe
  /// rien, et le seul moyen de revenir à la vue d'ensemble est de pincer en
  /// sens inverse.
  void _tapSurLaPhoto() {
    if (_photoNonZoomee) {
      Navigator.of(context).pop();
    } else {
      _reinitialiserZoom();
    }
  }

  void _changerDePage(int nouvelIndex) {
    // Un retour en cours viserait la photo qu'on vient de quitter.
    _animationRetourZoom.stop();
    setState(() {
      // Le zoom de la page qu'on quitte est remis à zéro — sans animation, elle
      // n'est plus à l'écran. Y revenir plus tard dans un état zoomé, sans
      // l'avoir demandé, serait déroutant.
      _zooms[_index].value = Matrix4.identity();
      _index = nouvelIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final plusieurs = widget.photos.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              // `onTap` seul : un pincement ou un glissement n'est pas un tap,
              // le zoom et le défilement restent donc intacts.
              onTap: _tapSurLaPhoto,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.photos.length,
                onPageChanged: _changerDePage,
                itemBuilder: (context, index) => InteractiveViewer(
                  transformationController: _zooms[index],
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: _PhotoEntiere(url: widget.photos[index]),
                  ),
                ),
              ),
            ),
          ),

          // Bouton de fermeture, en plus du bouton retour Android et du tap :
          // sur le Web et sur iPhone, aucun des deux autres n'est disponible.
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                // 48 px de zone tappable, minimum d'accessibilité du projet.
                iconSize: 26,
                padding: const EdgeInsets.all(11),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Fermer',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          if (plusieurs)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14, right: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_index + 1}/${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// L'image, entière, jamais recadrée.
class _PhotoEntiere extends StatelessWidget {
  const _PhotoEntiere({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, enfant, progression) {
        if (progression == null) return enfant;
        return const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.turquoise,
            ),
          ),
        );
      },
      errorBuilder: (context, erreur, trace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: Colors.white38,
            ),
            const SizedBox(height: 8),
            const Text(
              'Photo indisponible',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
