import 'package:flutter/material.dart';

import '../models/usager_affichage.dart';
import '../models/visibilite_type.dart';
import '../services/auth_service.dart';
import '../services/referentiel_service.dart';
import '../theme/app_colors.dart';
import '../utils/chargement_referentiel.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/consent_image_badge.dart';
import '../widgets/etat_referentiel.dart';
import '../widgets/simple_turquoise_header.dart';
import 'cahier_de_liaison_screen.dart';
import 'journal_de_vie_screen.dart';

/// Sous-page vers laquelle mène la sélection d'un usager.
enum SelectionUsagerDestination { journalDeVie, cahierDeLiaison }

/// Liste des usagers accessibles au pro connecté, pour ouvrir leur Journal de
/// vie ou leur Cahier de liaison.
///
/// Chantier Référentiel / R3a — la liste vient de Firestore, bornée aux
/// `unitesAcces` du pro. Elle portait auparavant cinq usagers écrits en dur,
/// dont une entrée de test sans id (« Léo Martin ») et un compteur de
/// souvenirs factice : le premier ne pouvait mener nulle part, le second
/// n'avait aucune contrepartie en base. Le compteur réel réapparaîtra à
/// l'étape 5 du chantier Publications, quand le Journal de vie sera alimenté
/// par de vraies publications.
class SelectionUsagerJournalScreen extends StatefulWidget {
  const SelectionUsagerJournalScreen({
    super.key,
    this.destination = SelectionUsagerDestination.journalDeVie,
  });

  final SelectionUsagerDestination destination;

  @override
  State<SelectionUsagerJournalScreen> createState() =>
      _SelectionUsagerJournalScreenState();
}

class _SelectionUsagerJournalScreenState extends State<SelectionUsagerJournalScreen> {
  final _service = ReferentielService();

  bool _chargement = true;
  ChargementReferentiel<List<UsagerAffichage>>? _resultat;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);

    final resultat = await chargerReferentiel<List<UsagerAffichage>>(() async {
      final unitesAcces = AuthService.currentProUser?.unitesAcces ?? const <String>[];
      if (unitesAcces.isEmpty) return const <UsagerAffichage>[];
      // Une seule requête groupée, bornée aux unités du pro — jamais un appel
      // par usager, qui multiplierait les lectures facturées.
      return _service.getUsagersAffichagePourPro(unitesAcces);
    });

    if (!mounted) return;
    setState(() {
      _resultat = resultat;
      _chargement = false;
    });
  }

  void _ouvrir(UsagerAffichage usager) {
    Navigator.of(context).push(
      fadeRoute(
        widget.destination == SelectionUsagerDestination.journalDeVie
            ? JournalDeVieScreen(
                usagerName: usager.nomComplet,
                usagerId: usager.id,
                usagerAge: usager.age,
                isPro: true,
              )
            : CahierDeLiaisonScreen(
                usagerId: usager.id,
                usagerName: usager.nomComplet,
                isPro: true,
              ),
      ),
    );
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
              child: AuthBackground(child: _buildContenu()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenu() {
    if (_chargement) return const ReferentielEnChargement();

    final resultat = _resultat!;
    if (resultat.enEchec) {
      return ReferentielEnErreur(resultat: resultat, onReessayer: _charger);
    }

    final usagers = resultat.valeur!;
    if (usagers.isEmpty) {
      return const ReferentielVide(
        message: 'Aucun usager accessible avec votre compte.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: usagers.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: 72,
        color: AppColors.marine.withValues(alpha: 0.08),
      ),
      itemBuilder: (context, index) => _buildLigne(usagers[index]),
    );
  }

  Widget _buildLigne(UsagerAffichage usager) {
    final sansConsentement =
        usager.sansAutorisationImage(VisibiliteType.individuelle) ||
            usager.sansAutorisationImage(VisibiliteType.groupe);

    return InkWell(
      onTap: () => _ouvrir(usager),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: usager.avatarColor,
              child: Text(
                usager.initiales,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usager.nomComplet,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.marine,
                    ),
                  ),
                  if (sansConsentement) ...[
                    const SizedBox(height: 4),
                    const ConsentImageBadge(),
                  ],
                ],
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
  }
}
