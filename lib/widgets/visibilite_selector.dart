import 'package:flutter/material.dart';

import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';
import 'section_label.dart';

/// Sélection courante : type de visibilité + usager (individuelle) ou
/// unité + présences (groupe). `etablissement` ne porte aucune sélection.
class VisibiliteSelection {
  const VisibiliteSelection({
    required this.type,
    this.usagerId,
    this.uniteId,
    this.usagersPresentsIds = const [],
  });

  final VisibiliteType type;
  final String? usagerId;
  final String? uniteId;
  final List<String> usagersPresentsIds;
}

/// Bloc réutilisable (chips Individuelle/Unité/Établissement + le sous-bloc
/// correspondant) utilisé par les écrans de création de publication et
/// d'événement d'agenda — même modèle de visibilité pour les deux.
class VisibiliteSelector extends StatefulWidget {
  const VisibiliteSelector({
    super.key,
    this.typeLabel = 'Type',
    required this.mockUsagers,
    required this.mockUnites,
    required this.onChanged,
  });

  final String typeLabel;
  final List<String> mockUsagers;
  final List<String> mockUnites;
  final ValueChanged<VisibiliteSelection> onChanged;

  @override
  State<VisibiliteSelector> createState() => _VisibiliteSelectorState();
}

class _VisibiliteSelectorState extends State<VisibiliteSelector> {
  VisibiliteType _type = VisibiliteType.individuelle;

  final _usagerSearchController = TextEditingController();
  String? _selectedUsager;
  String? _selectedUnite;

  late final Map<String, bool> _groupePresence = {
    for (final usager in widget.mockUsagers) usager: true,
  };

  @override
  void dispose() {
    _usagerSearchController.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(
      VisibiliteSelection(
        type: _type,
        usagerId: _selectedUsager,
        uniteId: _selectedUnite,
        usagersPresentsIds: _groupePresence.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList(),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, {IconData? icon}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.turquoise.withValues(alpha: 0.6), width: 1.4),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.marine.withValues(alpha: 0.4)),
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.turquoise),
      filled: true,
      fillColor: AppColors.champText,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.turquoise, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(widget.typeLabel),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildTypeChip('Individuelle', VisibiliteType.individuelle),
            _buildTypeChip('Unité', VisibiliteType.groupe),
            _buildTypeChip('Etablissement', VisibiliteType.etablissement),
          ],
        ),
        if (_type != VisibiliteType.etablissement) ...[
          const SizedBox(height: 20),
          _buildUsagerSection(),
        ],
      ],
    );
  }

  Widget _buildTypeChip(String label, VisibiliteType type) {
    final isSelected = _type == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() {
        _type = type;
        _notify();
      }),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      selectedColor: AppColors.turquoise,
      backgroundColor: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: AppColors.turquoise, width: 1.2)),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.turquoise,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildUsagerSection() {
    if (_type == VisibiliteType.individuelle) {
      if (_selectedUsager != null) {
        return _SelectedUsagerChip(
          name: _selectedUsager!,
          onClear: () => setState(() {
            _selectedUsager = null;
            _notify();
          }),
        );
      }

      final query = _usagerSearchController.text.trim().toLowerCase();
      final matches = query.isEmpty
          ? const <String>[]
          : widget.mockUsagers.where((name) => name.toLowerCase().contains(query)).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Usager concerné'),
          const SizedBox(height: 8),
          TextField(
            controller: _usagerSearchController,
            style: TextStyle(color: AppColors.marine),
            decoration: _fieldDecoration('Rechercher un usager...', icon: Icons.search),
            onChanged: (_) => setState(() {}),
          ),
          if (matches.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: matches.map((name) {
                  return ListTile(
                    title: Text(name, style: TextStyle(color: AppColors.marine)),
                    onTap: () => setState(() {
                      _selectedUsager = name;
                      _usagerSearchController.clear();
                      _notify();
                    }),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Unité concernée'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedUnite,
          decoration: _fieldDecoration('Sélectionner une unité'),
          style: TextStyle(color: AppColors.marine),
          icon: const Icon(Icons.expand_more, color: AppColors.turquoise),
          items: widget.mockUnites
              .map((unite) => DropdownMenuItem(value: unite, child: Text(unite)))
              .toList(),
          onChanged: (value) => setState(() {
            _selectedUnite = value;
            _notify();
          }),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Usagers présents'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.mockUsagers.map((name) {
              return CheckboxListTile(
                value: _groupePresence[name],
                onChanged: (value) => setState(() {
                  _groupePresence[name] = value ?? false;
                  _notify();
                }),
                title: Text(name, style: TextStyle(color: AppColors.marine)),
                activeColor: AppColors.turquoise,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tous sélectionnés par défaut - décochez les absents.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.marine.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _SelectedUsagerChip extends StatelessWidget {
  const _SelectedUsagerChip({required this.name, required this.onClear});

  final String name;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Usager concerné'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.turquoise, width: 1.4),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.turquoise),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(color: AppColors.marine, fontWeight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, color: AppColors.marine.withValues(alpha: 0.5), size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
