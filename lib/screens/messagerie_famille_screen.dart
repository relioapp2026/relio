import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/consultation.dart';
import '../models/message.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/simple_turquoise_header.dart';

const _mois = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String _formatDateHeure(DateTime date) =>
    '${date.day} ${_mois[date.month - 1]} à ${date.hour.toString().padLeft(2, '0')}h'
    '${date.minute.toString().padLeft(2, '0')}';

/// Liste des messages concernant la famille connectée (individuel, groupe
/// ou établissement). Une consultation est enregistrée automatiquement à
/// l'ouverture de la page pour chaque message affiché.
class MessagerieFamilleScreen extends StatefulWidget {
  const MessagerieFamilleScreen({super.key});

  @override
  State<MessagerieFamilleScreen> createState() => _MessagerieFamilleScreenState();
}

class _MessagerieFamilleScreenState extends State<MessagerieFamilleScreen> {
  late List<Message> _messages;

  @override
  void initState() {
    super.initState();
    _messages = mockMessages
        .where((message) => message.destinatairesUids.contains(mockFamilleConnecteeUid))
        .toList()
      ..sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi));

    for (final message in _messages) {
      _enregistrerConsultation(message);
    }
  }

  void _enregistrerConsultation(Message message) {
    final dejaConsulte = message.consultations.any((c) => c.uid == mockFamilleConnecteeUid);
    if (dejaConsulte) return;
    _remplacerMessage(
      message.copyWith(
        consultations: [
          ...message.consultations,
          Consultation(uid: mockFamilleConnecteeUid, dateConsultation: DateTime.now()),
        ],
      ),
    );
  }

  void _handleConfirmation(Message message) {
    final dejaConfirme = message.confirmationsLecture.any((c) => c.uid == mockFamilleConnecteeUid);
    if (dejaConfirme) return;
    setState(() {
      _remplacerMessage(
        message.copyWith(
          confirmationsLecture: [
            ...message.confirmationsLecture,
            ConfirmationLecture(uid: mockFamilleConnecteeUid, dateConfirmation: DateTime.now()),
          ],
        ),
      );
    });
  }

  void _remplacerMessage(Message updated) {
    final indexGlobal = mockMessages.indexWhere((m) => m.id == updated.id);
    if (indexGlobal != -1) mockMessages[indexGlobal] = updated;
    final indexLocal = _messages.indexWhere((m) => m.id == updated.id);
    if (indexLocal != -1) _messages[indexLocal] = updated;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(title: 'Messagerie'),
            Expanded(
              child: AuthBackground(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: _messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildMessageCard(_messages[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.turquoise.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              "Vous n'avez reçu aucun message",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.marine),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(Message message) {
    final confirmation = message.confirmationsLecture
        .where((c) => c.uid == mockFamilleConnecteeUid)
        .toList();
    final confirme = confirmation.isNotEmpty;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.roseViolet, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.marine.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.turquoise,
                      child: Text(
                        _initials(message.expediteurNom),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message.expediteurNom,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.marine),
                      ),
                    ),
                    Text(
                      _formatDateHeure(message.dateEnvoi),
                      style: TextStyle(fontSize: 11, color: AppColors.marine.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  message.contenu,
                  style: TextStyle(fontSize: 14, color: AppColors.marine.withValues(alpha: 0.85), height: 1.4),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.roseViolet.withValues(alpha: 0.14),
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: confirme,
                  activeColor: AppColors.roseViolet,
                  onChanged: confirme ? null : (value) => _handleConfirmation(message),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "J'ai bien lu et pris connaissance de ce message",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.marine),
                        ),
                        if (confirme) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Confirmé le ${_formatDateHeure(confirmation.first.dateConfirmation)}',
                            style: TextStyle(fontSize: 11, color: AppColors.marine.withValues(alpha: 0.6)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.toUpperCase();
  }
}
