import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_logo_header.dart';
import '../widgets/auth_background.dart';
import '../widgets/relio_footer.dart';

class MotDePasseOublieScreen extends StatefulWidget {
  const MotDePasseOublieScreen({super.key});

  @override
  State<MotDePasseOublieScreen> createState() => _MotDePasseOublieScreenState();
}

class _MotDePasseOublieScreenState extends State<MotDePasseOublieScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleEnvoyerLien() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lien de réinitialisation envoyé (à brancher sur Firebase Auth)'),
      ),
    );
  }

  void _handleRetourConnexion() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.marine, width: 1.4),
    );

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        const AppLogoHeader(),
                        const SizedBox(height: 28),
                        Text(
                          'Mot de passe oublié ?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.marine,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Entrez votre e-mail pour recevoir un lien de réinitialisation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.marine.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            hintText: 'Votre adresse e-mail',
                            hintStyle: TextStyle(
                              color: AppColors.marine.withValues(alpha: 0.35),
                            ),
                            prefixIcon: const Icon(
                              Icons.mail_outline,
                              color: AppColors.turquoise,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: border,
                            enabledBorder: border,
                            focusedBorder: border.copyWith(
                              borderSide: const BorderSide(
                                color: AppColors.turquoise,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Merci de renseigner votre email';
                            }
                            if (!value.contains('@')) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _handleEnvoyerLien,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.turquoise,
                          ),
                          child: const Text('Envoyer le lien'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.turquoise,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Vous recevrez un e-mail avec les instructions pour réinitialiser votre mot de passe.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.marine.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: TextButton(
                            onPressed: _handleRetourConnexion,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.turquoise,
                              minimumSize: const Size(48, 48),
                            ),
                            child: const Text(
                              'Retour à la connexion',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
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
