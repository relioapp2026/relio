import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/app_logo_header.dart';
import '../widgets/auth_background.dart';
import '../widgets/relio_footer.dart';
import 'login_screen.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleCreerCompte() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Création de compte (à brancher sur Firebase Auth + code d\'invitation)',
        ),
      ),
    );
  }

  void _handleSeConnecter() {
    Navigator.of(context).push(
      fadeRoute(const LoginScreen()),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.marine, width: 1.4),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.marine.withValues(alpha: 0.35)),
      prefixIcon: Icon(icon, color: AppColors.turquoise),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.turquoise, width: 2),
      ),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        const AppLogoHeader(
                          logoSize: 52,
                          titleFontSize: 22,
                          subtitleFontSize: 11,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Créer mon compte',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.marine,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rejoignez votre espace Relio en quelques instants',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.marine.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _prenomController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _fieldDecoration(
                            hint: 'Prénom',
                            icon: Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Merci de renseigner votre prénom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _nomController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _fieldDecoration(
                            hint: 'Nom',
                            icon: Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Merci de renseigner votre nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: _fieldDecoration(
                            hint: 'Votre adresse e-mail',
                            icon: Icons.mail_outline,
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
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: _fieldDecoration(
                            hint: 'Votre mot de passe',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.marine.withValues(alpha: 0.6),
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Merci de renseigner un mot de passe';
                            }
                            if (value.length < 6) {
                              return '6 caractères minimum';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: _fieldDecoration(
                            hint: 'Confirmer le mot de passe',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.marine.withValues(alpha: 0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Merci de confirmer le mot de passe';
                            }
                            if (value != _passwordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: _fieldDecoration(
                            hint: "Code d'invitation",
                            icon: Icons.vpn_key_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Merci de renseigner votre code d'invitation";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.turquoise,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Le code d'invitation vous a été transmis par votre établissement.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.marine.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: _handleCreerCompte,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.turquoise,
                          ),
                          child: const Text('Créer mon compte'),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Déjà inscrit ?',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.marine.withValues(alpha: 0.6),
                              ),
                            ),
                            TextButton(
                              onPressed: _handleSeConnecter,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.turquoise,
                                minimumSize: const Size(48, 48),
                              ),
                              child: const Text(
                                'Se connecter',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
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
