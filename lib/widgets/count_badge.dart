import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pastille numérique rose-violet à bordure turquoise, utilisée sur la
/// cloche de notifications et partout où un compteur doit attirer
/// l'attention (ex. tuiles du Cahier de liaison).
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      decoration: BoxDecoration(
        color: AppColors.roseViolet,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.turquoise, width: 2),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
