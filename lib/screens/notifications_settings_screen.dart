import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/simple_turquoise_header.dart';

class _NotificationOption {
  const _NotificationOption({required this.label, required this.description});

  final String label;
  final String description;
}

const _options = [
  _NotificationOption(
    label: 'Nouvelles publications',
    description: 'Recevoir une notification pour chaque nouvelle publication',
  ),
  _NotificationOption(
    label: 'Commentaires et likes',
    description: 'Être averti des commentaires et des likes sur vos publications',
  ),
  _NotificationOption(
    label: "Événements d'agenda",
    description: 'Recevoir un rappel pour les nouveaux événements',
  ),
  _NotificationOption(
    label: 'Nouveaux documents',
    description: "Être averti quand un nouveau document est envoyé",
  ),
];

/// Réglages des notifications, un switch par catégorie.
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  final _values = List<bool>.filled(_options.length, true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(title: 'Notifications'),
            Expanded(
              child: AuthBackground(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.marine.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < _options.length; i++) ...[
                            if (i > 0)
                              Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.marine.withValues(alpha: 0.08)),
                            _buildRow(i),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(int index) {
    final option = _options[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.marine),
                ),
                const SizedBox(height: 2),
                Text(
                  option.description,
                  style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: _values[index],
            activeThumbColor: AppColors.turquoise,
            onChanged: (value) => setState(() => _values[index] = value),
          ),
        ],
      ),
    );
  }
}
