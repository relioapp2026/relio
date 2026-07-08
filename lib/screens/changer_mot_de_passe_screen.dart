import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/section_label.dart';
import '../widgets/simple_turquoise_header.dart';

/// Formulaire de changement de mot de passe.
class ChangerMotDePasseScreen extends StatefulWidget {
  const ChangerMotDePasseScreen({super.key});

  @override
  State<ChangerMotDePasseScreen> createState() => _ChangerMotDePasseScreenState();
}

class _ChangerMotDePasseScreenState extends State<ChangerMotDePasseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actuelController = TextEditingController();
  final _nouveauController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _obscureActuel = true;
  bool _obscureNouveau = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _actuelController.dispose();
    _nouveauController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe modifié (à brancher sur Firestore)')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.turquoise,
        body: SafeArea(
          child: Column(
            children: [
              const SimpleTurquoiseHeader(title: 'Mot de passe'),
              Expanded(
                child: AuthBackground(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionLabel('Mot de passe actuel'),
                          const SizedBox(height: 8),
                          _buildPasswordField(
                            controller: _actuelController,
                            obscure: _obscureActuel,
                            onToggle: () => setState(() => _obscureActuel = !_obscureActuel),
                            validator: (value) =>
                                (value == null || value.isEmpty) ? 'Merci de renseigner votre mot de passe actuel' : null,
                          ),
                          const SizedBox(height: 20),
                          const SectionLabel('Nouveau mot de passe'),
                          const SizedBox(height: 8),
                          _buildPasswordField(
                            controller: _nouveauController,
                            obscure: _obscureNouveau,
                            onToggle: () => setState(() => _obscureNouveau = !_obscureNouveau),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Merci de choisir un nouveau mot de passe';
                              }
                              if (value.length < 6) {
                                return 'Au moins 6 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          const SectionLabel('Confirmer le nouveau mot de passe'),
                          const SizedBox(height: 8),
                          _buildPasswordField(
                            controller: _confirmationController,
                            obscure: _obscureConfirmation,
                            onToggle: () => setState(() => _obscureConfirmation = !_obscureConfirmation),
                            validator: (value) {
                              if (value != _nouveauController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _handleSave,
                            child: const Text('Enregistrer les modifications'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: AppColors.marine),
      validator: validator,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.marine.withValues(alpha: 0.7),
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
