import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class PublicationComment {
  const PublicationComment({
    required this.authorName,
    required this.avatarColor,
    required this.text,
  });

  final String authorName;
  final Color avatarColor;
  final String text;
}

/// Carte de publication du feed : avatar + horodatage, photos en carrousel,
/// likes/commentaires, texte, aperçu des commentaires et accès au détail.
class PublicationCard extends StatefulWidget {
  const PublicationCard({
    super.key,
    required this.authorName,
    required this.avatarColor,
    required this.timeAgo,
    required this.photoCount,
    required this.text,
    required this.likeCount,
    required this.comments,
  });

  final String authorName;
  final Color avatarColor;
  final String timeAgo;
  final int photoCount;
  final String text;
  final int likeCount;
  final List<PublicationComment> comments;

  @override
  State<PublicationCard> createState() => _PublicationCardState();
}

class _PublicationCardState extends State<PublicationCard>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  late List<PublicationComment> _comments;
  late final AnimationController _likeAnimController;
  late final Animation<double> _likeScale;
  int _currentPage = 0;
  bool _textExpanded = false;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _comments = List.of(widget.comments);
    _likeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _likeScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_likeAnimController);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _likeAnimController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() => _liked = !_liked);
    _likeAnimController.forward(from: 0);
    if (_liked) {
      HapticFeedback.lightImpact();
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.toUpperCase();
  }

  void _openCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(
        comments: _comments,
        onAddComment: (comment) => setState(() => _comments.add(comment)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingComments = _comments.length - 2;
    final likeCount = widget.likeCount + (_liked ? 1 : 0);

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: widget.avatarColor,
                  child: Text(
                    _initials(widget.authorName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.authorName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.marine,
                    ),
                  ),
                ),
                Text(
                  widget.timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.marine.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.more_horiz,
                  color: AppColors.marine.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.photoCount,
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
                if (widget.photoCount > 1) ...[
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
                        '${_currentPage + 1}/${widget.photoCount}',
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
                      children: List.generate(widget.photoCount, (index) {
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                InkWell(
                  onTap: _toggleLike,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _likeScale,
                          child: Icon(
                            _liked ? Icons.favorite : Icons.favorite_border,
                            color: _liked
                                ? AppColors.roseViolet
                                : AppColors.marine.withValues(alpha: 0.6),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$likeCount',
                          style: TextStyle(
                            color: AppColors.marine,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: _openCommentsSheet,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mode_comment_outlined,
                          color: AppColors.marine.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_comments.length}',
                          style: TextStyle(
                            color: AppColors.marine,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              maxLines: _textExpanded ? null : 3,
              overflow: _textExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(color: AppColors.marine, fontSize: 14, height: 1.35),
                children: [
                  TextSpan(text: widget.text),
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
          ),
          const SizedBox(height: 12),
          if (_comments.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _comments.take(2).map((comment) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: AppColors.marine, fontSize: 13),
                        children: [
                          TextSpan(
                            text: '${comment.authorName}  ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: comment.text),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (remainingComments > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GestureDetector(
                  onTap: _openCommentsSheet,
                  child: Text(
                    remainingComments == 1
                        ? "Voir l'autre commentaire"
                        : 'Voir les $remainingComments autres commentaires',
                    style: const TextStyle(
                      color: AppColors.turquoise,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.comments, required this.onAddComment});

  final List<PublicationComment> comments;
  final ValueChanged<PublicationComment> onAddComment;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  late List<PublicationComment> _comments;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _comments = List.of(widget.comments);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final comment = PublicationComment(
      authorName: 'Vous',
      avatarColor: AppColors.turquoise,
      text: text,
    );
    setState(() => _comments.add(comment));
    widget.onAddComment(comment);
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.marine.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Commentaires',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.marine,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _comments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: comment.avatarColor,
                            child: Text(
                              comment.authorName.isNotEmpty ? comment.authorName[0] : '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(color: AppColors.marine, fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: '${comment.authorName}  ',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: comment.text),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.marine.withValues(alpha: 0.1)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.marine.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    14,
                    12,
                    14 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          minLines: 1,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Ajouter un commentaire...',
                            hintStyle: TextStyle(
                              color: AppColors.marine.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: AppColors.champText,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _submitComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColors.turquoise,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _submitComment,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
