import 'package:flutter/material.dart';

/// Fond décoratif (vagues et cercles) utilisé sur les écrans d'authentification
/// (connexion, inscription, mot de passe oublié...). Image issue de la charte
/// graphique Relio.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/fond/fond_auth.png',
            fit: BoxFit.cover,
          ),
        ),
        child,
      ],
    );
  }
}
