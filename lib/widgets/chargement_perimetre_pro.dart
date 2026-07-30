import 'package:flutter/material.dart';

import '../models/unite.dart';
import '../models/usager_affichage.dart';
import '../services/auth_service.dart';
import '../services/referentiel_service.dart';
import '../utils/chargement_referentiel.dart';
import 'etat_referentiel.dart' show ReferentielEnChargement, ReferentielEnErreur;

/// Le périmètre du pro connecté : ses unités et leurs usagers.
class PerimetrePro {
  const PerimetrePro({required this.unites, required this.usagers});

  final List<Unite> unites;
  final List<UsagerAffichage> usagers;
}

/// Charge le périmètre du pro connecté, puis construit [builder] avec.
///
/// Chantier Référentiel / R3a. Les quatre formulaires de création/envoi
/// (publication, événement, document, message) ont exactement le même besoin :
/// les unités auxquelles le pro a accès, et les usagers de ces unités. Ce
/// widget centralise ce chargement plutôt que de le répéter quatre fois.
///
/// **Deux lectures groupées, jamais une par usager.** `getUnites` et
/// `getUsagersAffichagePourPro` sont bornées à `unitesAcces` : elles ne
/// peuvent donc pas ramener un document hors périmètre, ce qui ferait échouer
/// la requête entière (voir la note de classe de [ReferentielService]).
class ChargementPerimetrePro extends StatefulWidget {
  const ChargementPerimetrePro({
    super.key,
    required this.builder,
    this.filtreUsagers,
  });

  final Widget Function(BuildContext context, PerimetrePro perimetre) builder;

  /// Filtre optionnel appliqué aux usagers après chargement (ex. ne garder que
  /// ceux ayant une famille rattachée, pour les envois de document/message).
  final bool Function(UsagerAffichage usager)? filtreUsagers;

  @override
  State<ChargementPerimetrePro> createState() => _ChargementPerimetreProState();
}

class _ChargementPerimetreProState extends State<ChargementPerimetrePro> {
  final _service = ReferentielService();

  bool _chargement = true;
  ChargementReferentiel<PerimetrePro>? _resultat;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);

    final resultat = await chargerReferentiel<PerimetrePro>(() async {
      final unitesAcces = AuthService.currentProUser?.unitesAcces ?? const <String>[];
      if (unitesAcces.isEmpty) {
        return const PerimetrePro(unites: [], usagers: []);
      }

      final unites = await _service.getUnites(unitesAcces);
      final usagers = await _service.getUsagersAffichagePourPro(unitesAcces);
      final filtre = widget.filtreUsagers;

      return PerimetrePro(
        unites: unites,
        usagers: filtre == null ? usagers : usagers.where(filtre).toList(),
      );
    });

    if (!mounted) return;
    setState(() {
      _resultat = resultat;
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) return const ReferentielEnChargement();

    final resultat = _resultat!;
    if (resultat.enEchec) {
      return ReferentielEnErreur(resultat: resultat, onReessayer: _charger);
    }

    // Un périmètre sans usager n'est PAS un état bloquant : une diffusion en
    // portée établissement ne demande aucune sélection d'usager. Bloquer ici
    // rendrait le chip « Établissement » inatteignable pour un pro dont les
    // unités ne contiennent aucun usager éligible — le cas se produit
    // réellement avec le compte de test restreint à `unite_001`, dont aucun
    // usager n'a de famille rattachée. C'est au sélecteur d'afficher l'état
    // vide, dans le seul sous-bloc concerné.
    return widget.builder(context, resultat.valeur!);
  }
}
