import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ce que l'utilisateur a choisi dans le menu « ⋮ » d'une publication.
enum PublicationAction { modifier, masquer }

/// Menu « ⋮ » d'une publication.
///
/// Chantier Publications / étape 1. Visible uniquement pour l'auteur ou un
/// compte `peutModerer` — c'est l'appelant qui décide de l'afficher, via
/// [Publication.menuVisiblePour].
///
/// *Modifier* n'apparaît que pour l'auteur : un modérateur retire, il ne
/// réécrit pas les mots de quelqu'un d'autre.
class PublicationMenu extends StatelessWidget {
  const PublicationMenu({
    super.key,
    required this.peutModifier,
    required this.onAction,
  });

  /// Faux pour un modérateur qui n'est pas l'auteur : seul *Masquer* s'affiche.
  final bool peutModifier;
  final ValueChanged<PublicationAction> onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PublicationAction>(
      onSelected: onAction,
      tooltip: 'Options de la publication',
      icon: Icon(
        Icons.more_horiz,
        color: AppColors.marine.withValues(alpha: 0.5),
      ),
      itemBuilder: (context) => [
        if (peutModifier)
          const PopupMenuItem(
            value: PublicationAction.modifier,
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 20, color: AppColors.marine),
                SizedBox(width: 12),
                Text('Modifier'),
              ],
            ),
          ),
        PopupMenuItem(
          value: PublicationAction.masquer,
          child: Row(
            children: [
              Icon(Icons.visibility_off_outlined, size: 20, color: Colors.orange.shade800),
              const SizedBox(width: 12),
              const Text('Masquer'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Confirmation avant masquage, avec saisie facultative du motif.
///
/// Retourne le motif saisi (chaîne éventuellement vide) si l'utilisateur
/// confirme, `null` s'il annule.
///
/// Le motif est **facultatif** : exiger une justification découragerait de
/// retirer une photo publiée par erreur, alors que c'est exactement le geste
/// qu'on veut rendre facile. Mais il est tracé quand il est fourni, parce que
/// l'auteur a le droit de savoir pourquoi sa publication a été retirée.
Future<String?> confirmerMasquage(
  BuildContext context, {
  required bool estAuteur,
}) {
  final motifController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Masquer la publication ?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            estAuteur
                ? "Elle n'apparaîtra plus dans le fil des familles ni de vos "
                    'collègues. Vous continuerez à la voir, signalée comme masquée.'
                : "Elle n'apparaîtra plus dans le fil, sauf pour son auteur, qui "
                    'verra qu\'elle a été masquée et par qui.',
            style: TextStyle(fontSize: 14, color: AppColors.marine.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: motifController,
            maxLength: 200,
            style: TextStyle(color: AppColors.marine),
            decoration: const InputDecoration(
              labelText: 'Motif (facultatif)',
              hintText: 'Ex. photo publiée par erreur',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(motifController.text.trim()),
          style: TextButton.styleFrom(foregroundColor: Colors.orange.shade800),
          child: const Text('Masquer'),
        ),
      ],
    ),
  );
}

/// Bandeau affiché en tête d'une publication masquée, pour son auteur ou un
/// modérateur.
///
/// La publication ne disparaît jamais du feed de son auteur : il doit
/// constater qu'elle a été retirée, et par qui. Une disparition silencieuse
/// serait inacceptable.
class PublicationMasqueeBandeau extends StatelessWidget {
  const PublicationMasqueeBandeau({
    super.key,
    required this.parVous,
    this.motif,
  });

  final bool parVous;
  final String? motif;

  @override
  Widget build(BuildContext context) {
    final couleur = Colors.orange.shade800;
    final motifRenseigne = motif != null && motif!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: couleur.withValues(alpha: 0.12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_off_outlined, size: 16, color: couleur),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parVous
                      ? 'Masquée par vous — visible de vous seul'
                      : 'Masquée par un modérateur — visible de vous seul',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: couleur,
                  ),
                ),
                if (motifRenseigne) ...[
                  const SizedBox(height: 2),
                  Text(
                    motif!,
                    style: TextStyle(fontSize: 12, color: couleur),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
