import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/relio_footer.dart';
import '../widgets/section_label.dart';
import '../widgets/visibilite_selector.dart';

class CreateEvenementScreen extends StatefulWidget {
  const CreateEvenementScreen({super.key});

  @override
  State<CreateEvenementScreen> createState() => _CreateEvenementScreenState();
}

class _CreateEvenementScreenState extends State<CreateEvenementScreen> {
  VisibiliteSelection _visibilite = const VisibiliteSelection(type: VisibiliteType.individuelle);

  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _touteLaJournee = true;
  DateTime _date = DateTime.now();
  TimeOfDay _heureDebut = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _heureFin = const TimeOfDay(hour: 10, minute: 0);

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.turquoise.withValues(alpha: 0.6), width: 1.4),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.marine.withValues(alpha: 0.4)),
      filled: true,
      fillColor: AppColors.champText,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.turquoise, width: 2),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickHeureDebut() async {
    final picked = await showTimePicker(context: context, initialTime: _heureDebut);
    if (picked != null) setState(() => _heureDebut = picked);
  }

  Future<void> _pickHeureFin() async {
    final picked = await showTimePicker(context: context, initialTime: _heureFin);
    if (picked != null) setState(() => _heureFin = picked);
  }

  String _formatDate(DateTime date) {
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  String _formatHeure(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '${h}h$m';
  }

  // Chantier 0 / Session C2a — cet écran ne construit pas encore d'objet
  // Evenement réel (juste une validation + un SnackBar "à brancher sur
  // Firestore"). La validation ci-dessous reste volontairement basée sur les
  // champs noms de VisibiliteSelection (usagerId/uniteId/usagersPresentsIds)
  // pour ne rien changer au comportement actuel — y compris pour un nom
  // ambigu comme "Emma Bernard" (monde Agenda), qui reste sélectionnable ici
  // même si sa résolution en id échoue. Quand cet écran sera réellement
  // câblé (Firestore ou mockEvenements.insert), utiliser les champs id de
  // VisibiliteSelection (usagerConcerneId / uniteConcerneeId /
  // usagersPresentsConcernesIds) pour construire l'Evenement, pas les noms.
  void _handleCreer() {
    if (_visibilite.type == VisibiliteType.individuelle && _visibilite.usagerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de sélectionner un usager')),
      );
      return;
    }
    if (_visibilite.type == VisibiliteType.groupe && _visibilite.uniteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de sélectionner une unité')),
      );
      return;
    }
    if (_visibilite.type == VisibiliteType.groupe && _visibilite.usagersPresentsIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de sélectionner au moins un usager présent')),
      );
      return;
    }
    if (_titreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merci de donner un titre à l'événement")),
      );
      return;
    }
    if (!_touteLaJournee &&
        (_heureFin.hour * 60 + _heureFin.minute) <= (_heureDebut.hour * 60 + _heureDebut.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'heure de fin doit être après l'heure de début")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Événement créé (à brancher sur Firestore)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: AuthBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Material(
                        color: AppColors.turquoise,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Nouvel événement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.marine,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VisibiliteSelector(
                          typeLabel: "Type d'événement",
                          mockUsagers: mockUsagers,
                          mockUnites: mockUnites,
                          onChanged: (value) => setState(() => _visibilite = value),
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Titre'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titreController,
                          style: TextStyle(color: AppColors.marine),
                          decoration: _fieldDecoration("Titre de l'événement"),
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Description'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          style: TextStyle(color: AppColors.marine),
                          decoration: _fieldDecoration("Décrivez l'événement..."),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.4)),
                          ),
                          child: SwitchListTile(
                            value: _touteLaJournee,
                            onChanged: (value) => setState(() => _touteLaJournee = value),
                            activeThumbColor: AppColors.turquoise,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Toute la journée',
                              style: TextStyle(
                                color: AppColors.marine,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Date'),
                        const SizedBox(height: 8),
                        _PickerField(
                          icon: Icons.calendar_today_outlined,
                          label: _formatDate(_date),
                          onTap: _pickDate,
                        ),
                        if (!_touteLaJournee) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SectionLabel('Heure de début'),
                                    const SizedBox(height: 8),
                                    _PickerField(
                                      icon: Icons.access_time,
                                      label: _formatHeure(_heureDebut),
                                      onTap: _pickHeureDebut,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SectionLabel('Heure de fin'),
                                    const SizedBox(height: 8),
                                    _PickerField(
                                      icon: Icons.access_time_filled,
                                      label: _formatHeure(_heureFin),
                                      onTap: _pickHeureFin,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _handleCreer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.turquoise,
                          ),
                          child: const Text("Créer l'événement"),
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
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.champText,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.6), width: 1.4),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.turquoise, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: AppColors.marine, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
