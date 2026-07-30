import 'package:flutter/material.dart';

import '../models/unite.dart';
import '../models/usager_affichage.dart';
import '../models/visibilite_type.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'consent_image_badge.dart';
import 'section_label.dart';

/// Sélection courante : type de visibilité + usager (individuelle) ou
/// unité + présences (groupe). `etablissement` ne porte aucune sélection.
///
/// Chantier Référentiel / R3a — **ne porte plus que des ids**. Les anciens
/// champs `usagerId`/`uniteId`/`usagersPresentsIds`, qui contenaient en
/// réalité les libellés affichés dans l'UI, ont été supprimés avec la
/// résolution nom → id : deux usagers peuvent porter le même nom (voir
/// `usager_017`/`usager_032`, « Emma Bernard »), un libellé ne désigne donc
/// personne de façon fiable.
class VisibiliteSelection {
  const VisibiliteSelection({
    required this.type,
    this.usagerConcerneId,
    this.uniteConcerneeId,
    this.usagersPresentsConcernesIds = const [],
  });

  final VisibiliteType type;

  /// Id de l'usager concerné (portée individuelle uniquement).
  final String? usagerConcerneId;

  /// Id de l'unité concernée (portée groupe uniquement).
  final String? uniteConcerneeId;

  /// Ids des usagers cochés comme présents (portée groupe uniquement).
  final List<String> usagersPresentsConcernesIds;
}

/// Bloc réutilisable (chips Individuelle/Unité/Établissement + le sous-bloc
/// correspondant) utilisé par les écrans de création de publication et
/// d'événement d'agenda — même modèle de visibilité pour les deux.
///
/// Ne lit rien lui-même : l'écran appelant charge le référentiel et lui passe
/// le périmètre déjà borné aux droits du pro connecté.
class VisibiliteSelector extends StatefulWidget {
  const VisibiliteSelector({
    super.key,
    this.typeLabel = 'Type',
    required this.usagers,
    required this.unites,
    required this.onChanged,
    this.showConsentBadge = false,
    this.restrictionEtablissementActive = false,
    this.messageAucunUsager = 'Aucun usager accessible avec votre compte.',
  });

  final String typeLabel;

  /// Usagers sélectionnables, déjà filtrés par l'écran appelant.
  final List<UsagerAffichage> usagers;

  /// Unités sélectionnables, déjà filtrées par l'écran appelant.
  final List<Unite> unites;

  final ValueChanged<VisibiliteSelection> onChanged;

  /// Affiche le badge d'alerte consentement image (voir CLAUDE.md, section
  /// « Consentement image (usagers) ») à côté de chaque usager sans
  /// autorisation — pertinent uniquement pour une publication (photos), pas
  /// pour un événement d'agenda.
  final bool showConsentBadge;

  /// Si `true`, grise le chip "Établissement" (désactivé au tap) quand le
  /// pro connecté n'a pas `peutDiffuserEtablissement` — voir CLAUDE.md,
  /// section « Permission diffusion établissement ». Pertinent uniquement
  /// pour Document/Message : l'agenda et le fil d'actu (publications)
  /// restent ouverts à tous les pros, donc ce paramètre y reste à `false`.
  final bool restrictionEtablissementActive;

  /// Message affiché dans le sous-bloc « Usager concerné » quand [usagers] est
  /// vide. Les portées Unité et Établissement restent accessibles : l'absence
  /// d'usager sélectionnable ne doit jamais désactiver tout le sélecteur.
  final String messageAucunUsager;

  @override
  State<VisibiliteSelector> createState() => _VisibiliteSelectorState();
}

class _VisibiliteSelectorState extends State<VisibiliteSelector> {
  VisibiliteType _type = VisibiliteType.individuelle;

  final _usagerSearchController = TextEditingController();
  UsagerAffichage? _selectedUsager;
  Unite? _selectedUnite;

  /// Présences de la portée groupe, par id d'usager. Reconstruite à chaque
  /// changement d'unité — voir [_usagersDeLUniteSelectionnee].
  final Map<String, bool> _groupePresence = {};

  @override
  void dispose() {
    _usagerSearchController.dispose();
    super.dispose();
  }

  /// Usagers de l'unité sélectionnée.
  ///
  /// Une publication de groupe concerne **une** unité : proposer les usagers
  /// des autres unités reviendrait à laisser cocher comme « présent » un
  /// enfant qui n'y est pas inscrit. L'ancien sélecteur affichait la même
  /// liste de cinq usagers quelle que soit l'unité choisie — un défaut que le
  /// catalogue factice rendait invisible.
  List<UsagerAffichage> get _usagersDeLUniteSelectionnee {
    final unite = _selectedUnite;
    if (unite == null) return const [];
    return widget.usagers.where((u) => u.uniteId == unite.id).toList();
  }

  void _reinitialiserPresences() {
    _groupePresence
      ..clear()
      ..addEntries(
        // Tous pré-cochés : le pro décoche les absents (CLAUDE.md, « les 3
        // types de publication »).
        _usagersDeLUniteSelectionnee.map((u) => MapEntry(u.id, true)),
      );
  }

  void _notify() {
    final presents = _usagersDeLUniteSelectionnee
        .where((u) => _groupePresence[u.id] ?? false)
        .map((u) => u.id)
        .toList();

    widget.onChanged(
      VisibiliteSelection(
        type: _type,
        usagerConcerneId: _selectedUsager?.id,
        uniteConcerneeId: _selectedUnite?.id,
        usagersPresentsConcernesIds: presents,
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
    final etablissementDesactive =
        widget.restrictionEtablissementActive &&
        !(AuthService.currentProUser?.peutDiffuserEtablissement ?? false);

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
            _buildTypeChip('Etablissement', VisibiliteType.etablissement, enabled: !etablissementDesactive),
          ],
        ),
        if (_type != VisibiliteType.etablissement) ...[
          const SizedBox(height: 20),
          _buildUsagerSection(),
        ],
      ],
    );
  }

  Widget _buildTypeChip(String label, VisibiliteType type, {bool enabled = true}) {
    final isSelected = _type == type;
    final chipColor = enabled ? AppColors.turquoise : Colors.grey.shade400;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: enabled
          ? (_) => setState(() {
                _type = type;
                _notify();
              })
          : null,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      selectedColor: enabled ? AppColors.turquoise : Colors.grey.shade300,
      backgroundColor: enabled ? Colors.white : Colors.grey.shade200,
      shape: StadiumBorder(side: BorderSide(color: chipColor, width: 1.2)),
      labelStyle: TextStyle(
        color: enabled ? (isSelected ? Colors.white : AppColors.turquoise) : Colors.grey.shade600,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildUsagerSection() {
    if (_type == VisibiliteType.individuelle) {
      return _buildSelectionIndividuelle();
    }
    return _buildSelectionGroupe();
  }

  Widget _buildSelectionIndividuelle() {
    final selection = _selectedUsager;
    if (selection != null) {
      return _SelectedUsagerChip(
        // Même forme que dans la liste d'où il vient : basculer sur
        // « Prénom Nom » à la sélection ferait douter d'avoir choisi
        // la bonne personne.
        name: selection.nomListe,
        sansConsentement: widget.showConsentBadge &&
            selection.sansAutorisationImage(VisibiliteType.individuelle),
        onClear: () => setState(() {
          _selectedUsager = null;
          _notify();
        }),
      );
    }

    if (widget.usagers.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Usager concerné'),
          const SizedBox(height: 8),
          Text(
            widget.messageAucunUsager,
            style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.5)),
          ),
        ],
      );
    }

    final query = _usagerSearchController.text.trim().toLowerCase();
    // La recherche accepte les deux formes : on tape aussi bien « lucas » que
    // « dubois », que la liste affiche « Dubois Lucas ».
    final matches = query.isEmpty
        ? const <UsagerAffichage>[]
        : widget.usagers
            .where((u) =>
                u.nomListe.toLowerCase().contains(query) ||
                u.nomComplet.toLowerCase().contains(query))
            .toList();

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
          Padding(
            padding: const EdgeInsets.only(top: 8),
            // `Material` et non `Container` : un ListTile peint son fond et
            // ses ondes de contact sur le Material le plus proche. Enfermé
            // dans un conteneur décoré, il les peint *derrière* ce fond —
            // le tap n'a plus de retour visuel, et Flutter lève une
            // assertion en mode debug. Le Material porte donc lui-même la
            // couleur, la bordure et le rognage.
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.turquoise.withValues(alpha: 0.4)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: matches.map((usager) {
                  final sansConsentement = widget.showConsentBadge &&
                      usager.sansAutorisationImage(VisibiliteType.individuelle);
                  return ListTile(
                    title: Text(usager.nomListe, style: TextStyle(color: AppColors.marine)),
                    trailing: sansConsentement ? const ConsentImageBadge() : null,
                    onTap: () => setState(() {
                      _selectedUsager = usager;
                      _usagerSearchController.clear();
                      _notify();
                    }),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectionGroupe() {
    final usagersUnite = _usagersDeLUniteSelectionnee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Unité concernée'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedUnite?.id,
          decoration: _fieldDecoration('Sélectionner une unité'),
          style: TextStyle(color: AppColors.marine),
          icon: const Icon(Icons.expand_more, color: AppColors.turquoise),
          items: widget.unites
              .map((unite) => DropdownMenuItem(value: unite.id, child: Text(unite.nom)))
              .toList(),
          onChanged: (uniteId) => setState(() {
            _selectedUnite = uniteId == null
                ? null
                : widget.unites.firstWhere((u) => u.id == uniteId);
            _reinitialiserPresences();
            _notify();
          }),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Usagers présents'),
        const SizedBox(height: 8),
        if (_selectedUnite == null)
          Text(
            "Sélectionnez d'abord une unité.",
            style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.5)),
          )
        else if (usagersUnite.isEmpty)
          Text(
            'Aucun usager dans cette unité.',
            style: TextStyle(fontSize: 12, color: AppColors.marine.withValues(alpha: 0.5)),
          )
        else ...[
          // Material et non Container — voir la note sur la liste de
          // recherche ci-dessus : un CheckboxListTile peint lui aussi ses
          // ondes de contact sur le Material le plus proche.
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.turquoise.withValues(alpha: 0.4)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: usagersUnite.map((usager) {
                final sansConsentement = widget.showConsentBadge &&
                    usager.sansAutorisationImage(VisibiliteType.groupe);
                return CheckboxListTile(
                  value: _groupePresence[usager.id] ?? false,
                  onChanged: (value) => setState(() {
                    _groupePresence[usager.id] = value ?? false;
                    _notify();
                  }),
                  title: Text(usager.nomListe, style: TextStyle(color: AppColors.marine)),
                  subtitle: sansConsentement
                      ? const Align(alignment: Alignment.centerLeft, child: ConsentImageBadge())
                      : null,
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
      ],
    );
  }
}

class _SelectedUsagerChip extends StatelessWidget {
  const _SelectedUsagerChip({
    required this.name,
    required this.onClear,
    this.sansConsentement = false,
  });

  final String name;
  final VoidCallback onClear;
  final bool sansConsentement;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(color: AppColors.marine, fontWeight: FontWeight.w600),
                    ),
                    if (sansConsentement) ...[
                      const SizedBox(height: 4),
                      const ConsentImageBadge(),
                    ],
                  ],
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
