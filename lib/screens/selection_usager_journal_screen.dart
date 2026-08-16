import 'package:flutter/material.dart';

import '../models/consent_image.dart';
import '../models/unite.dart';
import '../models/usager_affichage.dart';
import '../models/visibilite_type.dart';
import '../theme/app_colors.dart';
import '../utils/fade_route.dart';
import '../widgets/auth_background.dart';
import '../widgets/chargement_perimetre_pro.dart';
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
/// l'étape 5 du chantier Publications.
///
/// **Groupée par unité**, dans l'ordre des unités (`Unite.ordre`), comme
/// Profil > Mes unités : une liste plate de 55 entrées toutes unités
/// confondues n'était pas navigable, et les deux écrans présentaient la même
/// donnée de deux façons différentes.
class SelectionUsagerJournalScreen extends StatelessWidget {
  const SelectionUsagerJournalScreen({
    super.key,
    this.destination = SelectionUsagerDestination.journalDeVie,
  });

  final SelectionUsagerDestination destination;

  void _ouvrir(BuildContext context, UsagerAffichage usager) {
    Navigator.of(context).push(
      fadeRoute(
        destination == SelectionUsagerDestination.journalDeVie
            ? JournalDeVieScreen(
                // Titre de page : « Prénom Nom », pas la forme de liste.
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
              child: AuthBackground(
                child: ChargementPerimetrePro(
                  builder: (context, perimetre) {
                    if (perimetre.usagers.isEmpty) {
                      return const ReferentielVide(
                        message: 'Aucun usager accessible avec votre compte.',
                      );
                    }
                    return _buildListe(context, perimetre);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListe(BuildContext context, PerimetrePro perimetre) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        for (final unite in perimetre.unites)
          ..._buildSectionUnite(context, unite, perimetre.usagersDe(unite)),
      ],
    );
  }

  List<Widget> _buildSectionUnite(
    BuildContext context,
    Unite unite,
    List<UsagerAffichage> usagers,
  ) {
    // Une unité sans usager accessible n'affiche pas de section vide.
    if (usagers.isEmpty) return const [];

    return [
      _EnteteUnite(nom: unite.nom, effectif: usagers.length),
      for (var i = 0; i < usagers.length; i++) ...[
        if (i > 0)
          Divider(
            height: 1,
            indent: 72,
            color: AppColors.marine.withValues(alpha: 0.08),
          ),
        _buildLigne(context, usagers[i]),
      ],
    ];
  }

  Widget _buildLigne(BuildContext context, UsagerAffichage usager) {
    // Cette liste ne cible aucun type de publication en particulier : elle
    // sert à ouvrir le journal d'un usager. Le badge y résume donc les deux
    // types, en affichant **le signal le plus fort** — un refus explicite
    // prime sur une absence de réponse, qui prime sur « tout est autorisé »
    // (aucun badge). Réduire les deux à un seul état perd du détail, mais
    // c'est le prix d'une ligne de liste lisible ; l'état complet reste
    // consultable via `ConsentImageEtat` (Cahier de liaison, Mes unités).
    final etats = [
      usager.etatConsentImage(VisibiliteType.individuelle),
      usager.etatConsentImage(VisibiliteType.groupe),
    ];
    final etatBadge = etats.contains(EtatConsentImage.refuse)
        ? EtatConsentImage.refuse
        : etats.contains(EtatConsentImage.nonRenseigne)
            ? EtatConsentImage.nonRenseigne
            : EtatConsentImage.autorise;
    final sansConsentement = etatBadge != EtatConsentImage.autorise;

    return InkWell(
      onTap: () => _ouvrir(context, usager),
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
                    // Forme de liste : la ligne commence par la clé de tri.
                    usager.nomListe,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.marine,
                    ),
                  ),
                  if (sansConsentement) ...[
                    const SizedBox(height: 4),
                    ConsentImageBadge(etat: etatBadge),
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

/// Intertitre de section : nom de l'unité + effectif accessible.
class _EnteteUnite extends StatelessWidget {
  const _EnteteUnite({required this.nom, required this.effectif});

  final String nom;
  final int effectif;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            nom.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.marine.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($effectif)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.marine.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
