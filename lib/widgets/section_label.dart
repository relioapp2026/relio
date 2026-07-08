import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Libellé de section (ex: "Type de publication", "Photos", "Message"),
/// utilisé sur les écrans de création (publication, événement...).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.marine,
      ),
    );
  }
}
