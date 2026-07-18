import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum FeedNavTab { accueil, journalDeVie, cahierDeLiaison, profil }

/// Pied de page turquoise à 4 icônes, commun aux écrans principaux
/// (Accueil / Journal de vie / Cahier de liaison / Profil).
class FeedBottomNav extends StatelessWidget {
  const FeedBottomNav({super.key, required this.current, this.onTabTap});

  final FeedNavTab current;
  final ValueChanged<FeedNavTab>? onTabTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.turquoise,
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            tab: FeedNavTab.accueil,
            current: current,
            filledIcon: Icons.home,
            outlinedIcon: Icons.home_outlined,
            label: 'Accueil',
            onTap: onTabTap,
          ),
          _NavItem(
            tab: FeedNavTab.journalDeVie,
            current: current,
            filledIcon: Icons.menu_book,
            outlinedIcon: Icons.menu_book_outlined,
            label: 'Journal de vie',
            onTap: onTabTap,
          ),
          _NavItem(
            tab: FeedNavTab.cahierDeLiaison,
            current: current,
            filledIcon: Icons.contact_page,
            outlinedIcon: Icons.contact_page_outlined,
            label: 'Cahier de liaison',
            onTap: onTabTap,
          ),
          _NavItem(
            tab: FeedNavTab.profil,
            current: current,
            filledIcon: Icons.person,
            outlinedIcon: Icons.person_outline,
            label: 'Profil',
            onTap: onTabTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.current,
    required this.filledIcon,
    required this.outlinedIcon,
    required this.label,
    this.onTap,
  });

  final FeedNavTab tab;
  final FeedNavTab current;
  final IconData filledIcon;
  final IconData outlinedIcon;
  final String label;
  final ValueChanged<FeedNavTab>? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = tab == current;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap == null ? null : () => onTap!(tab),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? filledIcon : outlinedIcon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
