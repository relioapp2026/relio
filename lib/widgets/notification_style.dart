import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../theme/app_colors.dart';

const _mois = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// Horodatage relatif d'une notification ("à l'instant", "il y a 2h"...).
String notificationTimeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
  return 'le ${date.day} ${_mois[date.month - 1]}';
}

IconData notificationIcon(TypeNotification type) => switch (type) {
      TypeNotification.nouvellePublication => Icons.article_outlined,
      TypeNotification.confirmationDocument => Icons.task_alt,
      TypeNotification.confirmationMessage => Icons.mark_chat_read_outlined,
      TypeNotification.nouvelEvenement => Icons.event_outlined,
      TypeNotification.nouveauDocument => Icons.description_outlined,
      TypeNotification.nouveauMessage => Icons.chat_bubble_outline,
    };

Color notificationColor(TypeNotification type) => switch (type) {
      TypeNotification.nouvellePublication => AppColors.marine,
      TypeNotification.confirmationDocument => AppColors.turquoise,
      TypeNotification.confirmationMessage => AppColors.roseViolet,
      TypeNotification.nouvelEvenement => AppColors.marine,
      TypeNotification.nouveauDocument => AppColors.turquoise,
      TypeNotification.nouveauMessage => AppColors.roseViolet,
    };
