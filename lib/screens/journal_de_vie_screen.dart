import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/feed_bottom_nav.dart';
import '../widgets/simple_turquoise_header.dart';
import 'agenda_famille_screen.dart';
import 'agenda_pro_screen.dart';
import 'profil_screen.dart';

enum _Periode { tout, ceMois, cetteSemaine }

class _JournalEntry {
  const _JournalEntry({required this.caption, required this.date, required this.color});

  final String caption;
  final String date;
  final Color color;
}

final _mockJournal = <String, List<_JournalEntry>>{
  'JUIN 2025': [
    _JournalEntry(
      caption: 'Atelier peinture : des couleurs plein les mains et des sourires...',
      date: '12 juin 2025',
      color: AppColors.turquoise,
    ),
    _JournalEntry(
      caption: 'Sortie au parc : courir, rire et profiter du grand air !',
      date: '5 juin 2025',
      color: AppColors.roseViolet,
    ),
    _JournalEntry(
      caption: 'Jardinage au potager : semer, arroser et voir grandir nos plantations 🌱',
      date: '2 juin 2025',
      color: AppColors.marine,
    ),
  ],
  'MAI 2025': [
    _JournalEntry(
      caption: "Activité manuelle : création d'un tableau coloré pour maman 💕",
      date: '28 mai 2025',
      color: AppColors.roseViolet,
    ),
    _JournalEntry(
      caption: 'Pique-nique au soleil ☀️ Des bons moments ensemble !',
      date: '20 mai 2025',
      color: AppColors.turquoise,
    ),
  ],
};

class JournalDeVieScreen extends StatefulWidget {
  const JournalDeVieScreen({
    super.key,
    this.usagerName = 'Léo Martin',
    this.usagerId,
    this.usagerAge = 8,
    this.souvenirsCount = 47,
    this.isPro = false,
  });

  final String usagerName;

  /// Chantier 0 / Session C2a — id stable de l'usager, transmis en plus de
  /// [usagerName] (qui reste utilisé pour l'affichage). `null` si l'appelant
  /// n'a pas pu résoudre d'id (voir selection_usager_journal_screen.dart).
  /// Pas encore utilisé pour filtrer le journal dans cet écran.
  final String? usagerId;
  final int usagerAge;
  final int souvenirsCount;

  /// Affiche les actions éditer/supprimer sur chaque entrée (vue pro).
  final bool isPro;

  @override
  State<JournalDeVieScreen> createState() => _JournalDeVieScreenState();
}

class _JournalDeVieScreenState extends State<JournalDeVieScreen> {
  _Periode _periode = _Periode.tout;
  late final Map<String, List<_JournalEntry>> _journal = {
    for (final entry in _mockJournal.entries) entry.key: List.of(entry.value),
  };

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.toUpperCase();
  }

  void _handleEdit(_JournalEntry entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modifier la publication (à venir)')),
    );
  }

  Future<void> _handleDelete(String monthKey, _JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette publication ?'),
        content: Text(entry.caption),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _journal[monthKey]?.remove(entry);
        if (_journal[monthKey]?.isEmpty ?? false) {
          _journal.remove(monthKey);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(title: 'Journal de vie'),
            Expanded(
              child: AuthBackground(
                child: _journal.isEmpty
                    ? _buildEmptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        children: [
                          _buildUsagerCard(),
                          const SizedBox(height: 16),
                          _buildPeriodeChips(),
                          const SizedBox(height: 20),
                          for (final entry in _journal.entries) ...[
                            _buildMonthDivider(entry.key),
                            const SizedBox(height: 12),
                            ..._buildEntriesGrid(entry.key, entry.value),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
              ),
            ),
            FeedBottomNav(
              current: FeedNavTab.journalDeVie,
              onTabTap: (tab) {
                switch (tab) {
                  case FeedNavTab.accueil:
                    Navigator.of(context).pop();
                  case FeedNavTab.journalDeVie:
                    break;
                  case FeedNavTab.agenda:
                    Navigator.of(context).pushReplacement(
                      fadeRoute(widget.isPro ? const AgendaProScreen() : const AgendaFamilleScreen()),
                    );
                  case FeedNavTab.profil:
                    Navigator.of(context).pushReplacement(
                      fadeRoute(ProfilScreen(isPro: widget.isPro)),
                    );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsagerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.roseViolet, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.turquoise,
                child: Text(
                  _initials(widget.usagerName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.usagerName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.marine,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.usagerAge} ans',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.marine.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: AppColors.roseViolet, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.souvenirsCount} souvenirs partagés',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.marine.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Téléchargement du journal (à venir)')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.turquoise,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.turquoise, width: 1.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Télécharger le journal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodeChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPeriodeChip('Tout', _Periode.tout),
        const SizedBox(width: 14),
        _buildPeriodeChip('Ce mois', _Periode.ceMois),
        const SizedBox(width: 14),
        _buildPeriodeChip('Cette semaine', _Periode.cetteSemaine),
      ],
    );
  }

  Widget _buildPeriodeChip(String label, _Periode periode) {
    final isSelected = _periode == periode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _periode = periode),
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

  Widget _buildMonthDivider(String label) {
    final line = Expanded(
      child: Divider(color: AppColors.marine.withValues(alpha: 0.2)),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.marine.withValues(alpha: 0.5),
            ),
          ),
        ),
        line,
      ],
    );
  }

  List<Widget> _buildEntriesGrid(String monthKey, List<_JournalEntry> entries) {
    Widget tile(_JournalEntry entry, double height) {
      return _JournalEntryTile(
        entry: entry,
        height: height,
        showActions: widget.isPro,
        onEdit: () => _handleEdit(entry),
        onDelete: () => _handleDelete(monthKey, entry),
      );
    }

    final widgets = <Widget>[];
    var i = 0;
    while (i < entries.length) {
      final remaining = entries.length - i;
      if (remaining >= 3) {
        widgets.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tile(entries[i], 140)),
              const SizedBox(width: 12),
              Expanded(child: tile(entries[i + 1], 140)),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 16));
        widgets.add(tile(entries[i + 2], 200));
        widgets.add(const SizedBox(height: 16));
        i += 3;
      } else if (remaining == 2) {
        widgets.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tile(entries[i], 140)),
              const SizedBox(width: 12),
              Expanded(child: tile(entries[i + 1], 140)),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 16));
        i += 2;
      } else {
        widgets.add(tile(entries[i], 200));
        widgets.add(const SizedBox(height: 16));
        i += 1;
      }
    }
    return widgets;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: AppColors.turquoise.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun souvenir partagé pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.marine,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les publications concernant cet usager apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.marine.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalEntryTile extends StatelessWidget {
  const _JournalEntryTile({
    required this.entry,
    required this.height,
    this.showActions = false,
    this.onEdit,
    this.onDelete,
  });

  final _JournalEntry entry;
  final double height;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Widget _actionButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(Icons.image_outlined, size: 40, color: Colors.white70),
              ),
            ),
            if (showActions)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    _actionButton(Icons.edit_outlined, onEdit),
                    const SizedBox(width: 6),
                    _actionButton(Icons.delete_outline, onDelete),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          entry.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.marine,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          entry.date,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.marine.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
