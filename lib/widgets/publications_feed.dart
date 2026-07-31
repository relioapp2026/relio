import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/publication.dart';
import '../screens/create_publication_screen.dart';
import '../services/auth_service.dart';
import '../services/publication_service.dart';
import '../theme/app_colors.dart';
import '../utils/chargement_referentiel.dart';
import '../utils/fade_route.dart';
import 'etat_referentiel.dart';
import 'notification_style.dart';
import 'publication_card.dart';
import 'publication_menu.dart';

/// Le fil de publications, partagé par le feed pro et le feed famille.
///
/// Chantier Publications / étape 1. **Une seule implémentation de la
/// pagination** : la dupliquer dans les deux écrans garantirait qu'elles
/// divergent à la première correction.
///
/// La requête est identique pour les deux rôles — c'est tout l'intérêt du
/// champ `cibles` : seul le périmètre passé à `array-contains-any` change
/// (unités pour un pro, usagers pour une famille), pas la forme de la requête
/// ni l'index.
///
/// Réutilise [chargerReferentiel] pour classer les échecs. Son nom vient du
/// chantier Référentiel, mais le tri qu'il fait — refus de règle / panne
/// réseau / délai dépassé — n'a rien de spécifique au référentiel. Le
/// renommer toucherait les dix écrans migrés en R3a, hors périmètre ici.
class PublicationsFeed extends StatefulWidget {
  const PublicationsFeed({super.key});

  @override
  State<PublicationsFeed> createState() => PublicationsFeedState();
}

class PublicationsFeedState extends State<PublicationsFeed> {
  final _service = PublicationService();

  final List<Publication> _publications = [];
  DocumentSnapshot<Map<String, dynamic>>? _curseur;
  bool _finAtteinte = false;

  bool _chargementInitial = true;
  bool _chargementSuivant = false;
  ChargementReferentiel<PagePublications>? _echec;

  /// Uid du compte connecté, quel que soit son rôle.
  String? get _uid =>
      AuthService.currentProUser?.uid ?? AuthService.currentFamilleUser?.uid;

  /// Seul un pro peut être modérateur. Une famille ne l'est jamais.
  bool get _peutModerer => AuthService.currentProUser?.peutModerer ?? false;

  @override
  void initState() {
    super.initState();
    _chargerPremierePage();
  }

  Future<void> _chargerPremierePage() async {
    setState(() {
      _chargementInitial = true;
      _echec = null;
    });

    final resultat = await chargerReferentiel(() => _service.chargerPage());

    if (!mounted) return;
    setState(() {
      _chargementInitial = false;
      if (resultat.enEchec) {
        _echec = resultat;
      } else {
        final page = resultat.valeur!;
        _publications
          ..clear()
          ..addAll(page.publications);
        _curseur = page.dernierDocument;
        _finAtteinte = page.finAtteinte;
      }
    });
  }

  Future<void> _chargerPageSuivante() async {
    if (_chargementSuivant || _finAtteinte || _curseur == null) return;

    setState(() => _chargementSuivant = true);

    final resultat = await chargerReferentiel(
      () => _service.chargerPage(apres: _curseur),
    );

    if (!mounted) return;
    setState(() {
      _chargementSuivant = false;
      if (resultat.enEchec) {
        // Échec d'une page suivante : on garde ce qui est déjà affiché plutôt
        // que de vider le fil. L'utilisateur voit un message, pas une perte.
        _echec = resultat;
        return;
      }
      final page = resultat.valeur!;
      _publications.addAll(page.publications);
      _curseur = page.dernierDocument;
      _finAtteinte = page.finAtteinte;
    });
  }

  /// Rechargement complet — utilisé par le tirer-pour-actualiser et au retour
  /// d'une création ou d'une modification.
  Future<void> rafraichir() => _chargerPremierePage();

  /// Publications réellement affichées à ce lecteur.
  ///
  /// `masquee` est filtré **côté client**, pas dans la requête : l'ajouter au
  /// `where` imposerait un index composite de plus pour une volumétrie
  /// modeste. Conséquence assumée : une page de 15 peut en afficher 13.
  List<Publication> get _visibles => _publications
      .where((p) => p.visiblePour(uid: _uid, peutModerer: _peutModerer))
      .toList();

  Future<void> _modifier(Publication publication) async {
    await Navigator.of(context).push(
      fadeRoute(CreatePublicationScreen(publicationAModifier: publication)),
    );
    await rafraichir();
  }

  Future<void> _masquer(Publication publication) async {
    final motif = await confirmerMasquage(
      context,
      estAuteur: publication.auteurId == _uid,
    );
    if (motif == null) return;

    try {
      await _service.masquer(
        publicationId: publication.id,
        motif: motif.isEmpty ? null : motif,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            PublicationService.estRefusDePermission(e)
                ? "Vos droits ne permettent pas de masquer cette publication."
                : 'Le masquage a échoué. Vérifiez votre connexion.',
          ),
        ),
      );
      return;
    }

    await rafraichir();
  }

  @override
  Widget build(BuildContext context) {
    if (_chargementInitial) return const ReferentielEnChargement();

    if (_echec != null && _publications.isEmpty) {
      return ReferentielEnErreur(
        resultat: _echec!,
        onReessayer: _chargerPremierePage,
      );
    }

    final visibles = _visibles;

    if (visibles.isEmpty) {
      return RefreshIndicator(
        color: AppColors.turquoise,
        onRefresh: rafraichir,
        // Le ListView est nécessaire même vide : sans zone défilable, le
        // tirer-pour-actualiser n'a pas de prise.
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 60),
            ReferentielVide(
              message: 'Aucune publication pour le moment.',
              icone: Icons.photo_library_outlined,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.turquoise,
      onRefresh: rafraichir,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: visibles.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == visibles.length) return _buildPied();

          final publication = visibles[index];
          final menuVisible = publication.menuVisiblePour(
            uid: _uid,
            peutModerer: _peutModerer,
          );

          return PublicationCard(
            publication: publication,
            timeAgo: notificationTimeAgo(publication.dateCreation),
            masqueeParVous: publication.masqueePar == _uid,
            menu: menuVisible
                ? PublicationMenu(
                    peutModifier: publication.modifiablePar(_uid),
                    onAction: (action) => switch (action) {
                      PublicationAction.modifier => _modifier(publication),
                      PublicationAction.masquer => _masquer(publication),
                    },
                  )
                : null,
          );
        },
      ),
    );
  }

  /// Bouton « Charger plus », indicateur, ou fin de liste.
  Widget _buildPied() {
    if (_chargementSuivant) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.turquoise),
          ),
        ),
      );
    }

    if (_finAtteinte) return const SizedBox(height: 8);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton(
        onPressed: _chargerPageSuivante,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.turquoise,
          side: const BorderSide(color: AppColors.turquoise, width: 1.4),
        ),
        child: const Text('Charger plus'),
      ),
    );
  }
}
