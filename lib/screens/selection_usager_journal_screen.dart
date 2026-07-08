import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/simple_turquoise_header.dart';
import 'journal_de_vie_screen.dart';

class _UsagerJournal {
  const _UsagerJournal({
    required this.id,
    required this.name,
    required this.age,
    required this.souvenirsCount,
    required this.avatarColor,
  });

  /// Chantier 0 / Session C2a — id stable (`mockUsagersCatalogue`), `null`
  /// si non résolvable (voir commentaires ci-dessous).
  final String? id;
  final String name;
  final int age;
  final int souvenirsCount;
  final Color avatarColor;
}

// Donnée factice : en production, cette liste sera filtrée côté Firestore
// par les `unites_acces` du professionnel connecté.
const _mockUsagersJournal = [
  // TEST DATA À NETTOYER — "Léo Martin" ne correspond à aucun usager du
  // catalogue fusionné (même incohérence que evt1 dans mock_data.dart,
  // antérieure à ce chantier). Id laissé à `null` plutôt qu'inventé.
  _UsagerJournal(id: null, name: 'Léo Martin', age: 8, souvenirsCount: 47, avatarColor: AppColors.turquoise),
  // Homonyme ambigu par nom (voir usager_017/usager_032, "Emma Bernard").
  // usager_017 choisi ici (rattachée à une famille, fam_bernard) plutôt que
  // usager_032 (monde Agenda, sans famille) — choix arbitraire à confirmer
  // avec Séb, la résolution par nom seul ne permettant pas de trancher.
  _UsagerJournal(id: 'usager_017', name: 'Emma Bernard', age: 7, souvenirsCount: 32, avatarColor: AppColors.roseViolet),
  _UsagerJournal(id: 'usager_033', name: 'Nathan Petit', age: 9, souvenirsCount: 19, avatarColor: AppColors.marine),
  _UsagerJournal(id: 'usager_034', name: 'Chloé Rousseau', age: 6, souvenirsCount: 28, avatarColor: AppColors.turquoise),
  _UsagerJournal(id: 'usager_031', name: 'Lucas Martin', age: 10, souvenirsCount: 41, avatarColor: AppColors.roseViolet),
];

class SelectionUsagerJournalScreen extends StatelessWidget {
  const SelectionUsagerJournalScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(title: 'Sélectionner un usager'),
            Expanded(
              child: AuthBackground(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _mockUsagersJournal.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 72,
                    color: AppColors.marine.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, index) {
                    final usager = _mockUsagersJournal[index];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          fadeRoute(
                            JournalDeVieScreen(
                              usagerName: usager.name,
                              usagerId: usager.id,
                              usagerAge: usager.age,
                              souvenirsCount: usager.souvenirsCount,
                              isPro: true,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: usager.avatarColor,
                              child: Text(
                                _initials(usager.name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                usager.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.marine,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.marine.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
