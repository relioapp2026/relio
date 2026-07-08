import 'package:flutter/material.dart';

/// Les 3 états de lecture d'un document ou d'un message par une famille.
enum StatutLecture { nonConsulte, consulte, confirme }

Color statutLectureColor(StatutLecture statut) => switch (statut) {
      StatutLecture.nonConsulte => Colors.grey.shade600,
      StatutLecture.consulte => Colors.orange.shade700,
      StatutLecture.confirme => Colors.green.shade600,
    };

/// Pastille colorée affichant l'état de lecture (gris/orange/vert).
class StatutLecturePill extends StatelessWidget {
  const StatutLecturePill({super.key, required this.statut, required this.label});

  final StatutLecture statut;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = statutLectureColor(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
