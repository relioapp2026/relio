import 'package:flutter/material.dart';

/// Badge informatif (jamais bloquant) affiché à côté d'un usager qui n'a pas
/// d'autorisation image pour le type de publication concerné — voir
/// CLAUDE.md, section « Consentement image (usagers) ».
class ConsentImageBadge extends StatelessWidget {
  const ConsentImageBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            "Pas d'autorisation image",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
