import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/app_logo_header.dart';
import '../widgets/auth_background.dart';
import '../widgets/relio_footer.dart';
import 'inscription_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _handlePremiereConnexion(BuildContext context) {
    Navigator.of(context).push(
      fadeRoute(const InscriptionScreen()),
    );
  }

  void _handleJaiDejaUnCompte(BuildContext context) {
    Navigator.of(context).push(
      fadeRoute(const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      const AppLogoHeader(),
                      const SizedBox(height: 36),
                      Text(
                        'Bienvenue sur Relio',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.marine,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rejoignez votre espace dès maintenant',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.marine.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 36),
                      ElevatedButton(
                        onPressed: () => _handlePremiereConnexion(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.turquoise,
                        ),
                        child: const Text('Première connexion'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => _handleJaiDejaUnCompte(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.marine,
                          backgroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: AppColors.marine, width: 1.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text("J'ai déjà un compte"),
                      ),
                    ],
                  ),
                ),
              ),
              const RelioFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
