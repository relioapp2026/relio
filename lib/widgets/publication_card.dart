import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/publication.dart';
import '../theme/app_colors.dart';
import 'publication_menu.dart';

/// Carte de publication du feed.
///
/// **Chantier Publications / étape 1 — texte seul.**
///
/// Les likes et les commentaires sont **affichés mais inertes** : compteurs à
/// zéro, aucun tap, aucune action réseau. Le schéma Firestore ne porte aucun
/// champ de comptage à cette étape, et simuler un comportement qui n'existe
/// pas donnerait une fausse idée de ce qui marche. Ils reviennent à l'étape 3,
/// câblés pour de vrai.
///
/// Le bloc photo ne s'affiche que s'il y a des photos — étape 2. Sans ce
/// garde-fou, chaque publication texte réserverait 200 px de vide.
///
/// L'interactivité précédente (like animé, bottom sheet des commentaires,
/// `_CommentsSheet`) a été retirée ici et sera reconstruite contre Firestore à
/// l'étape 3. Elle reste consultable dans l'historique Git, commit `9fde98c`.
class PublicationCard extends StatefulWidget {
  const PublicationCard({
    super.key,
    required this.publication,
    required this.timeAgo,
    this.menu,
    this.masqueeParVous = false,
  });

  final Publication publication;
  final String timeAgo;

  /// Menu « ⋮ ». `null` quand le lecteur n'est ni l'auteur ni modérateur —
  /// l'icône disparaît alors complètement, plutôt que d'être grisée.
  final Widget? menu;

  /// Change le libellé du bandeau de masquage (« par vous » / « par un
  /// modérateur »).
  final bool masqueeParVous;

  @override
  State<PublicationCard> createState() => _PublicationCardState();
}

class _PublicationCardState extends State<PublicationCard> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _textExpanded = false;

  Publication get _publication => widget.publication;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final photoCount = _publication.photos.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.roseViolet, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.marine.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_publication.masquee)
            PublicationMasqueeBandeau(
              parVous: widget.masqueeParVous,
              motif: _publication.motifMasquage,
            ),
          _buildEntete(),
          if (photoCount > 0) _buildPhotos(photoCount),
          _buildCompteursInertes(),
          _buildTexte(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEntete() {
    return Padding(
      // Padding droit réduit quand le menu est là : le PopupMenuButton porte
      // déjà sa propre zone tappable de 48 px, exigée par l'accessibilité.
      padding: EdgeInsets.fromLTRB(16, 16, widget.menu == null ? 16 : 4, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _publication.avatarColor,
            child: Text(
              _initials(_publication.auteurNom),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _publication.auteurNom,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.marine,
                  ),
                ),
                if (_publication.modifiee)
                  Text(
                    'Modifiée',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.marine.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            widget.timeAgo,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.marine.withValues(alpha: 0.5),
            ),
          ),
          if (widget.menu != null) widget.menu!,
        ],
      ),
    );
  }

  Widget _buildPhotos(int photoCount) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: photoCount,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final palette = [
                  AppColors.turquoise,
                  AppColors.marine,
                  AppColors.roseViolet,
                ];
                return Container(
                  color: palette[index % palette.length].withValues(alpha: 0.85),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Colors.white70,
                    ),
                  ),
                );
              },
            ),
          ),
          if (photoCount > 1) ...[
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPage + 1}/$photoCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photoCount, (index) {
                  final isActive = index == _currentPage;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 8 : 6,
                    height: isActive ? 8 : 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.turquoise
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Compteurs affichés, sans aucune interaction — voir la note de classe.
  ///
  /// Estompés (`alpha: 0.35`) plutôt que masqués : la maquette validée les
  /// prévoit, et les faire disparaître pour les faire réapparaître à l'étape 3
  /// serait plus déroutant que de les montrer inactifs.
  Widget _buildCompteursInertes() {
    final couleur = AppColors.marine.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Icon(Icons.favorite_border, color: couleur, size: 22),
          const SizedBox(width: 6),
          Text('0', style: TextStyle(color: couleur, fontWeight: FontWeight.w600)),
          const SizedBox(width: 20),
          Icon(Icons.mode_comment_outlined, color: couleur, size: 20),
          const SizedBox(width: 6),
          Text('0', style: TextStyle(color: couleur, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTexte() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RichText(
        maxLines: _textExpanded ? null : 3,
        overflow: _textExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(color: AppColors.marine, fontSize: 14, height: 1.35),
          children: [
            TextSpan(text: _publication.texte),
            if (!_textExpanded)
              TextSpan(
                text: '  ...voir plus',
                style: const TextStyle(
                  color: AppColors.turquoise,
                  fontWeight: FontWeight.w700,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => setState(() => _textExpanded = true),
              ),
          ],
        ),
      ),
    );
  }
}
