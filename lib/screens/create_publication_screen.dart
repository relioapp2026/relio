import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/dashed_border_painter.dart';
import '../widgets/relio_footer.dart';
import '../widgets/section_label.dart';
import '../widgets/visibilite_selector.dart';

const _maxPhotos = 3;

class CreatePublicationScreen extends StatefulWidget {
  const CreatePublicationScreen({super.key});

  @override
  State<CreatePublicationScreen> createState() => _CreatePublicationScreenState();
}

class _CreatePublicationScreenState extends State<CreatePublicationScreen> {
  VisibiliteSelection _visibilite = const VisibiliteSelection(type: VisibiliteType.individuelle);

  final List<Color> _photos = [];
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _addMockPhoto() {
    if (_photos.length >= _maxPhotos) return;
    const palette = [
      AppColors.turquoise,
      AppColors.marine,
      AppColors.roseViolet,
    ];
    setState(() => _photos.add(palette[_photos.length % palette.length]));
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  // Chantier 0 / Session C2a — cet écran ne construit pas encore de
  // Publication réelle (pas de modèle branché ici, voir Session C2b). La
  // validation reste sur les champs noms de VisibiliteSelection pour ne rien
  // changer au comportement actuel. Quand cet écran sera câblé, utiliser les
  // champs id (usagerConcerneId / uniteConcerneeId /
  // usagersPresentsConcernesIds) pour construire la Publication.
  void _handlePublish() {
    if (_visibilite.type == VisibiliteType.individuelle && _visibilite.usagerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de sélectionner un usager')),
      );
      return;
    }
    if (_visibilite.type == VisibiliteType.groupe && _visibilite.uniteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de sélectionner une unité')),
      );
      return;
    }
    if (_visibilite.type == VisibiliteType.groupe && _visibilite.usagersPresentsIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de sélectionner au moins un usager présent')),
      );
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de décrire le moment partagé')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publication créée (à brancher sur Firestore)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: AuthBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Material(
                        color: AppColors.turquoise,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Nouvelle publication',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.marine,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VisibiliteSelector(
                          typeLabel: 'Type de publication',
                          mockUsagers: mockUsagers,
                          mockUnites: mockUnites,
                          onChanged: (value) => setState(() => _visibilite = value),
                          showConsentBadge: true,
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Photos'),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 1 + _photos.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _DashedAddTile(
                                  enabled: _photos.length < _maxPhotos,
                                  onTap: _addMockPhoto,
                                );
                              }
                              final photoIndex = index - 1;
                              return _PhotoTile(
                                color: _photos[photoIndex],
                                onRemove: () => _removePhoto(photoIndex),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Message'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _messageController,
                          maxLines: 5,
                          maxLength: 1000,
                          style: TextStyle(color: AppColors.marine),
                          decoration: InputDecoration(
                            hintText: 'Décrivez le moment partagé...',
                            hintStyle: TextStyle(color: AppColors.marine.withValues(alpha: 0.4)),
                            filled: true,
                            fillColor: AppColors.champText,
                            counterStyle: TextStyle(
                              color: AppColors.marine.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.turquoise.withValues(alpha: 0.6),
                                width: 1.4,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.turquoise.withValues(alpha: 0.6),
                                width: 1.4,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.turquoise, width: 2),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _handlePublish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.turquoise,
                          ),
                          child: const Text('Publier'),
                        ),
                      ],
                    ),
                  ),
                ),
                const RelioFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedAddTile extends StatelessWidget {
  const _DashedAddTile({required this.onTap, this.enabled = true});

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: CustomPaint(
          painter: DashedBorderPainter(color: AppColors.turquoise),
          child: SizedBox(
            width: 80,
            height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: AppColors.turquoise),
                const SizedBox(height: 2),
                Text(
                  'Ajouter',
                  style: TextStyle(
                    color: AppColors.turquoise,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.color, required this.onRemove});

  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.image_outlined, color: Colors.white70),
            ),
          ),
          Positioned(
            top: -12,
            right: -12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.marine,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
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
