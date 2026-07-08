import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/simple_turquoise_header.dart';

String _initials(String prenom, String nom) {
  final letters = [prenom, nom].where((p) => p.isNotEmpty).map((p) => p[0]).join();
  return letters.toUpperCase();
}

/// Détail d'une unité (lecture seule) : liste des usagers qui la composent.
class UniteDetailScreen extends StatelessWidget {
  const UniteDetailScreen({super.key, required this.unite});

  final UniteAvecUsagers unite;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            SimpleTurquoiseHeader(title: unite.nom),
            Expanded(
              child: AuthBackground(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    Text(
                      '${unite.usagers.length} usagers',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.marine.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildUsagersCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsagersCard() {
    return Container(
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
        children: [
          for (var i = 0; i < unite.usagers.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 68, color: AppColors.marine.withValues(alpha: 0.08)),
            _buildUsagerRow(unite.usagers[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildUsagerRow(UsagerUnite usager) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: usager.avatarColor,
            child: Text(
              _initials(usager.prenom, usager.nom),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '${usager.prenom} ${usager.nom}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.marine),
            ),
          ),
          Text(
            '${usager.age} ans',
            style: TextStyle(fontSize: 13, color: AppColors.marine.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}
