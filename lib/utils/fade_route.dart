import 'package:flutter/material.dart';

/// Route en fondu enchaîné (fade), utilisée pour toute la navigation de
/// l'app à la place du glissement par défaut de `MaterialPageRoute`. Le
/// bouton retour / la flèche retour ne sont pas affectés : seule
/// l'animation d'entrée/sortie change.
Route<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}
