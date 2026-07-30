import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/message.dart';
import '../models/visibilite_type.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/chargement_perimetre_pro.dart';
import '../widgets/section_label.dart';
import '../widgets/simple_turquoise_header.dart';
import '../widgets/visibilite_selector.dart';

/// Résout les comptes famille destinataires d'une sélection.
///
/// **Reste sur `mockFamilles` — second pont temporaire de R3a.** La règle
/// `users/{uid}` de `firestore.rules` n'autorise chacun à lire que son propre
/// document : aucune requête cliente ne peut retrouver les comptes famille
/// rattachés à un usager. Seul l'affichage du sélecteur a été migré vers
/// Firestore ; la résolution des destinataires attend le chantier Messagerie.
List<String> _resolveDestinataires(VisibiliteSelection selection) {
  switch (selection.type) {
    case VisibiliteType.individuelle:
      final usagerId = selection.usagerConcerneId;
      if (usagerId == null) return const [];
      final uid = familleUidPourUsagerId(usagerId);
      return uid == null ? const [] : [uid];
    case VisibiliteType.groupe:
      return selection.usagersPresentsConcernesIds.map(familleUidPourUsagerId).whereType<String>().toList();
    case VisibiliteType.etablissement:
      return mockFamilles.keys.toList();
  }
}

/// Formulaire d'envoi d'un message (pro) : portée + texte libre. Alimente
/// `mockMessages`.
class EnvoyerMessageScreen extends StatefulWidget {
  const EnvoyerMessageScreen({super.key});

  @override
  State<EnvoyerMessageScreen> createState() => _EnvoyerMessageScreenState();
}

class _EnvoyerMessageScreenState extends State<EnvoyerMessageScreen> {
  VisibiliteSelection _visibilite = const VisibiliteSelection(type: VisibiliteType.individuelle);
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleEnvoyer() {
    if (_visibilite.type == VisibiliteType.individuelle && _visibilite.usagerConcerneId == null) {
      _showError('Merci de sélectionner un usager');
      return;
    }
    if (_visibilite.type == VisibiliteType.groupe && _visibilite.uniteConcerneeId == null) {
      _showError('Merci de sélectionner une unité');
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      _showError('Merci de rédiger un message');
      return;
    }

    final destinataires = _resolveDestinataires(_visibilite);
    if (destinataires.isEmpty) {
      _showError('Aucune famille concernée par cette sélection');
      return;
    }

    final pro = AuthService.currentProUser;
    if (pro == null) {
      _showError('Aucun compte professionnel connecté. Reconnectez-vous puis réessayez.');
      return;
    }

    mockMessages.insert(
      0,
      Message(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        contenu: _messageController.text.trim(),
        portee: _visibilite.type,
        usagersConcernesIds:
            _visibilite.type == VisibiliteType.individuelle && _visibilite.usagerConcerneId != null
                ? [_visibilite.usagerConcerneId!]
                : const [],
        uniteConcerneeId: _visibilite.type == VisibiliteType.groupe ? _visibilite.uniteConcerneeId : null,
        expediteurId: pro.uid,
        expediteurNom: '${pro.prenom} ${pro.nom}',
        dateEnvoi: DateTime.now(),
        destinatairesUids: destinataires,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message envoyé (à brancher sur Firestore)')),
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
              const SimpleTurquoiseHeader(title: 'Envoyer un message'),
              Expanded(
                child: AuthBackground(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ChargementPerimetrePro(
                          // Un message s'adresse à une famille : seuls les
                          // usagers qui en ont une rattachée sont proposés.
                          filtreUsagers: (usager) =>
                              mockUsagerIdsAvecFamilles.contains(usager.id),
                          builder: (context, perimetre) => VisibiliteSelector(
                            typeLabel: 'Portée du message',
                            usagers: perimetre.usagers,
                            unites: perimetre.unites,
                            onChanged: (value) => setState(() => _visibilite = value),
                            restrictionEtablissementActive: true,
                            messageAucunUsager:
                                'Aucun usager avec une famille rattachée dans vos unités.',
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Message'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _messageController,
                          maxLines: 6,
                          maxLength: 1000,
                          style: TextStyle(color: AppColors.marine),
                          decoration: InputDecoration(
                            hintText: 'Écrivez votre message...',
                            hintStyle: TextStyle(color: AppColors.marine.withValues(alpha: 0.4)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _handleEnvoyer,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseViolet),
                          child: const Text('Envoyer'),
                        ),
                      ],
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
}
