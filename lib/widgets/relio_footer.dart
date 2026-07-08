import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Mention discrète en bas des écrans d'authentification.
class RelioFooter extends StatelessWidget {
  const RelioFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Relio • créé pour vous avec ❤️',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.marine.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
