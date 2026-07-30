import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/unite.dart';
import '../models/usager_affichage.dart';
import '../services/referentiel_service.dart';
import '../theme/app_colors.dart';
import '../utils/avatar_color.dart';
import '../utils/chargement_referentiel.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/count_badge.dart';
import '../widgets/feed_bottom_nav.dart';
import '../widgets/simple_turquoise_header.dart';
import 'agenda_famille_screen.dart';
import 'agenda_pro_screen.dart';
import 'documents_famille_screen.dart';
import 'documents_pro_screen.dart';
import 'feed_famille_screen.dart';
import 'feed_pro_screen.dart';
import 'journal_de_vie_screen.dart';
import 'messagerie_famille_screen.dart';
import 'messages_pro_screen.dart';
import 'profil_screen.dart';
import 'selection_usager_journal_screen.dart';

const _mois = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String _formatDate(DateTime date) => '${date.day} ${_mois[date.month - 1]}';

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
  return letters.toUpperCase();
}

/// Page d'accueil par usager : Messagerie / Agenda / Documents en un coup
/// d'œil. Accessible directement depuis le footer côté famille (un seul
/// usager) ; côté pro, après sélection d'un usager
/// (SelectionUsagerJournalScreen). Reprend la mise en page de
/// JournalDeVieScreen (carte usager + footer de navigation complet).
class CahierDeLiaisonScreen extends StatefulWidget {
  const CahierDeLiaisonScreen({
    super.key,
    required this.usagerId,
    required this.usagerName,
    this.isPro = false,
  });

  final String usagerId;
  final String usagerName;
  final bool isPro;

  @override
  State<CahierDeLiaisonScreen> createState() => _CahierDeLiaisonScreenState();
}

/// L'identité de l'usager affichée dans l'en-tête : l'usager lui-même et
/// l'unité dont il relève.
class _EnteteUsager {
  const _EnteteUsager({this.usager, this.unite});

  final UsagerAffichage? usager;
  final Unite? unite;
}

class _CahierDeLiaisonScreenState extends State<CahierDeLiaisonScreen> {
  final _service = ReferentielService();

  bool _chargement = true;
  ChargementReferentiel<_EnteteUsager>? _entete;

  String get usagerId => widget.usagerId;
  String get usagerName => widget.usagerName;
  bool get isPro => widget.isPro;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  /// Charge l'usager puis son unité — deux lectures, la seconde dépendant de
  /// la première (`uniteId` n'est connu qu'après avoir lu l'usager).
  Future<void> _charger() async {
    setState(() => _chargement = true);

    final resultat = await chargerReferentiel<_EnteteUsager>(() async {
      final usager = await _service.getUsagerAffichage(usagerId);
      if (usager == null) return const _EnteteUsager();

      final unites = await _service.getUnites([usager.uniteId]);
      return _EnteteUsager(
        usager: usager,
        unite: unites.isEmpty ? null : unites.first,
      );
    });

    if (!mounted) return;
    setState(() {
      _entete = resultat;
      _chargement = false;
    });
  }

  void _handleTabTap(BuildContext context, FeedNavTab tab) {
    switch (tab) {
      case FeedNavTab.accueil:
        Navigator.of(context).pushAndRemoveUntil(
          fadeRoute(isPro ? const FeedProScreen() : const FeedFamilleScreen()),
          (route) => false,
        );
      case FeedNavTab.journalDeVie:
        Navigator.of(context).pushReplacement(
          fadeRoute(
            isPro
                ? const SelectionUsagerJournalScreen()
                : const JournalDeVieScreen(),
          ),
        );
      case FeedNavTab.cahierDeLiaison:
        break;
      case FeedNavTab.profil:
        Navigator.of(context).pushReplacement(
          fadeRoute(ProfilScreen(isPro: isPro)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = messagesPourUsager(usagerId)
      ..sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi));
    final documents = documentsPourUsager(usagerId)
      ..sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi));
    final maintenant = DateTime.now();
    final evenementsAVenir = evenementsPourUsager(usagerId)
        .where((e) => e.dateDebut.isAfter(maintenant))
        .toList()
      ..sort((a, b) => a.dateDebut.compareTo(b.dateDebut));

    final dernierMessage = messages.isNotEmpty ? messages.first : null;
    final dernierDocument = documents.isNotEmpty ? documents.first : null;
    final prochainEvenement = evenementsAVenir.isNotEmpty ? evenementsAVenir.first : null;

    final limite7Jours = maintenant.add(const Duration(days: 7));
    final badgeAgenda = evenementsAVenir.where((e) => e.dateDebut.isBefore(limite7Jours)).length;

    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(title: 'Cahier de liaison'),
            Expanded(
              child: AuthBackground(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    _buildUsagerCard(),
                    const SizedBox(height: 20),
                    _CahierTile(
                      icon: Icons.chat_bubble_outline,
                      color: AppColors.roseViolet,
                      title: 'Messagerie',
                      apercu: dernierMessage != null
                          ? '${dernierMessage.expediteurNom} : ${dernierMessage.contenu}'
                          : 'Aucun message récent',
                      badgeCount: messagesNonConfirmesPourUsager(usagerId),
                      onTap: () => Navigator.of(context).push(
                        fadeRoute(
                          isPro
                              ? MessagesProScreen(usagerId: usagerId, usagerNom: usagerName)
                              : const MessagerieFamilleScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CahierTile(
                      icon: Icons.event_outlined,
                      color: AppColors.turquoise,
                      title: 'Agenda',
                      apercu: prochainEvenement != null
                          ? '${prochainEvenement.titre} · ${_formatDate(prochainEvenement.dateDebut)}'
                          : 'Aucun événement à venir',
                      badgeCount: badgeAgenda,
                      onTap: () => Navigator.of(context).push(
                        fadeRoute(
                          isPro
                              ? AgendaProScreen(usagerId: usagerId, usagerName: usagerName)
                              : const AgendaFamilleScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CahierTile(
                      icon: Icons.folder_outlined,
                      color: AppColors.marine,
                      title: 'Documents',
                      apercu: dernierDocument != null
                          ? '${dernierDocument.titre} · envoyé le ${_formatDate(dernierDocument.dateEnvoi)}'
                          : 'Aucun document récent',
                      badgeCount: documentsNonConfirmesPourUsager(usagerId),
                      onTap: () => Navigator.of(context).push(
                        fadeRoute(
                          isPro
                              ? DocumentsProScreen(usagerId: usagerId, usagerNom: usagerName)
                              : const DocumentsFamilleScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            FeedBottomNav(
              current: FeedNavTab.cahierDeLiaison,
              onTabTap: (tab) => _handleTabTap(context, tab),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte d'identité de l'usager.
  ///
  /// Le nom vient toujours du paramètre de navigation, jamais de Firestore :
  /// l'écran doit rester lisible pendant le chargement et même si la lecture
  /// échoue. Seuls l'âge, l'unité et la couleur d'avatar attendent la réponse.
  Widget _buildUsagerCard() {
    final entete = _entete?.valeur;
    final usager = entete?.usager;
    final uniteNom = entete?.unite?.nom;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.roseViolet, width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            // Dérivée de l'id, connu dès l'ouverture : la couleur est donc
            // correcte immédiatement, sans attendre Firestore ni clignoter.
            backgroundColor: avatarColorPourUsager(usagerId),
            child: Text(
              _initials(usagerName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usagerName,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.marine,
                  ),
                ),
                const SizedBox(height: 2),
                _buildSousTitre(usager, uniteNom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ligne « âge · unité » sous le nom.
  ///
  /// Trois états explicites plutôt qu'une ligne qui apparaît sans prévenir :
  /// chargement, échec de lecture, puis la valeur. Le reste de l'écran (les
  /// trois tuiles) n'en dépend pas et reste utilisable dans tous les cas.
  Widget _buildSousTitre(UsagerAffichage? usager, String? uniteNom) {
    final style = TextStyle(
      fontSize: 13,
      color: AppColors.marine.withValues(alpha: 0.6),
    );

    if (_chargement) return Text('Chargement…', style: style);

    final resultat = _entete;
    if (resultat != null && resultat.enEchec) {
      return Text(
        resultat.refusDePermission
            ? 'Fiche non accessible'
            : 'Fiche indisponible hors connexion',
        style: style,
      );
    }

    if (usager == null) return Text('Fiche introuvable', style: style);

    return Text(
      '${usager.age} ans${uniteNom != null ? ' · $uniteNom' : ''}',
      style: style,
    );
  }
}

class _CahierTile extends StatelessWidget {
  const _CahierTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.apercu,
    required this.badgeCount,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String apercu;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: CountBadge(count: badgeCount),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.marine),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        apercu,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: AppColors.marine.withValues(alpha: 0.6), height: 1.3),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(Icons.chevron_right, color: AppColors.marine.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
