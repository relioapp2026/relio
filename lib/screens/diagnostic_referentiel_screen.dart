// TEMPORAIRE — à supprimer en R3.
//
// Écran de diagnostic du chantier Référentiel (R2). C'est le livrable de
// validation de cette étape : il permet de vérifier sur le Pixel 9a que les
// règles de sécurité et `ReferentielService` fonctionnent, sans toucher un
// seul écran déjà validé visuellement.
//
// À supprimer en R3, en même temps que sa tuile d'accès dans
// `profil_screen.dart` (elle aussi marquée TEMPORAIRE).
//
// Aucune donnée en dur : tout vient de Firestore. Le bloc « compte connecté »
// lit délibérément le document `users/{uid}` BRUT plutôt que les modèles
// `ProUser`/`FamilleUser` : un modèle appliquerait ses valeurs par défaut
// (`peutModerer` absent s'afficherait `false`), ce qui masquerait l'état réel
// de la base. Un outil de diagnostic doit distinguer « absent » de « false ».

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/etablissement.dart';
import '../models/unite.dart';
import '../models/usager.dart';
import '../services/referentiel_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/simple_turquoise_header.dart';

/// Résultat d'un bloc de diagnostic : une valeur, ou une erreur classée.
/// Permet qu'un bloc en échec n'empêche pas les autres de s'afficher.
class _Resultat<T> {
  const _Resultat.succes(this.valeur)
      : erreur = null,
        refusDePermission = false;
  const _Resultat.echec(this.erreur, {required this.refusDePermission}) : valeur = null;

  final T? valeur;
  final String? erreur;
  final bool refusDePermission;

  bool get enEchec => erreur != null;
}

/// Exécute [action) en classant l'échec éventuel, sans jamais le propager.
Future<_Resultat<T>> _tenter<T>(Future<T> Function() action) async {
  try {
    return _Resultat.succes(await action());
  } catch (e) {
    return _Resultat.echec(
      e.toString(),
      refusDePermission: ReferentielService.estRefusDePermission(e),
    );
  }
}

class DiagnosticReferentielScreen extends StatefulWidget {
  const DiagnosticReferentielScreen({super.key});

  @override
  State<DiagnosticReferentielScreen> createState() => _DiagnosticReferentielScreenState();
}

class _DiagnosticReferentielScreenState extends State<DiagnosticReferentielScreen> {
  final _service = ReferentielService();

  bool _chargement = true;

  _Resultat<Map<String, dynamic>>? _compte;
  _Resultat<Etablissement?>? _etablissement;
  _Resultat<List<Unite>>? _unites;
  final Map<String, _Resultat<List<Usager>>> _usagersParUnite = {};
  _Resultat<Usager?>? _usagerDetail;
  _Resultat<String>? _testEcriture;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _usagersParUnite.clear();
      _testEcriture = null;
    });

    // 1. Compte connecté — document users/{uid} brut.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final compte = await _tenter<Map<String, dynamic>>(() async {
      if (uid == null) throw StateError('Aucun utilisateur connecté.');
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists) throw StateError('Document users/$uid inexistant.');
      return doc.data()!;
    });

    final donneesCompte = compte.valeur ?? const <String, dynamic>{};
    final etablissementId = donneesCompte['etablissementId'] as String?;
    final unitesAcces = List<String>.from(donneesCompte['unitesAcces'] as List? ?? const []);
    final usagersIds = List<String>.from(donneesCompte['usagersIds'] as List? ?? const []);

    // 2. Établissement.
    final etablissement = etablissementId == null
        ? const _Resultat<Etablissement?>.echec(
            'etablissementId absent du compte — lecture impossible.',
            refusDePermission: false,
          )
        : await _tenter(() => _service.getEtablissement(etablissementId));

    // 3. Unités. Un pro lit celles de son unitesAcces ; une famille, celles
    //    de ses usagers — qu'il faut donc résoudre d'abord.
    _Resultat<List<Unite>> unites;
    _Resultat<Usager?> usagerDetail;

    if (unitesAcces.isNotEmpty) {
      unites = await _tenter(() => _service.getUnites(unitesAcces));
      usagerDetail = await _tenter(() async {
        final usagers = await _service.getUsagersPourPro(unitesAcces);
        return usagers.isEmpty ? null : usagers.first;
      });
    } else {
      final usagersFamille = await _tenter(() => _service.getUsagersPourFamille(usagersIds));
      final idsUnites = (usagersFamille.valeur ?? const <Usager>[])
          .map((u) => u.uniteId)
          .toSet()
          .toList();
      unites = usagersFamille.enEchec
          ? _Resultat<List<Unite>>.echec(
              usagersFamille.erreur!,
              refusDePermission: usagersFamille.refusDePermission,
            )
          : await _tenter(() => _service.getUnites(idsUnites));
      usagerDetail = _Resultat.succes(
        (usagersFamille.valeur ?? const <Usager>[]).isEmpty
            ? null
            : usagersFamille.valeur!.first,
      );
    }

    // 4. Effectifs par unité.
    final effectifs = <String, _Resultat<List<Usager>>>{};
    if (unitesAcces.isNotEmpty) {
      for (final unite in unites.valeur ?? const <Unite>[]) {
        effectifs[unite.id] = await _tenter(() => _service.getUsagersParUnite(unite.id));
      }
    } else {
      effectifs['(usagers de la famille)'] =
          await _tenter(() => _service.getUsagersPourFamille(usagersIds));
    }

    if (!mounted) return;
    setState(() {
      _compte = compte;
      _etablissement = etablissement;
      _unites = unites;
      _usagersParUnite.addAll(effectifs);
      _usagerDetail = usagerDetail;
      _chargement = false;
    });
  }

  /// Tente une écriture qui DOIT être refusée par les règles.
  ///
  /// Vise un id bidon, jamais un usager réel : si la règle était cassée,
  /// écrire sur `usager_001` corromprait une vraie donnée, alors qu'un
  /// document bidon se repère et se supprime.
  ///
  /// L'id ne doit PAS être de la forme `__xxx__` : Firestore réserve ce
  /// motif et rejette l'écriture côté validation, **avant** d'évaluer les
  /// règles — le test passerait alors à côté de son objectif. Le préfixe
  /// `zzz_` le fait ressortir en fin de liste dans la console.
  Future<void> _testerEcriture() async {
    setState(() => _testEcriture = null);

    final resultat = await _tenter<String>(() async {
      await FirebaseFirestore.instance
          .collection('usagers')
          .doc('zzz_diagnostic_ecriture')
          .set({'test': true});
      return 'ÉCRITURE ACCEPTÉE';
    });

    if (!mounted) return;
    setState(() => _testEcriture = resultat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.turquoise,
      body: SafeArea(
        child: Column(
          children: [
            const SimpleTurquoiseHeader(
              title: 'Diagnostic référentiel',
              subtitle: 'Temporaire — chantier R2',
            ),
            Expanded(
              child: AuthBackground(
                child: _chargement
                    ? const Center(child: CircularProgressIndicator(color: AppColors.turquoise))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _blocCompte(),
                          const SizedBox(height: 16),
                          _blocEtablissement(),
                          const SizedBox(height: 16),
                          _blocUnites(),
                          const SizedBox(height: 16),
                          _blocEffectifs(),
                          const SizedBox(height: 16),
                          _blocUsagerDetail(),
                          const SizedBox(height: 16),
                          _blocTestEcriture(),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _charger,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Relancer le diagnostic'),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Blocs ---------------------------------------------------------------

  Widget _blocCompte() {
    const attendus = [
      'role',
      'etablissementId',
      'unitesAcces',
      'usagersIds',
      'peutModerer',
      'peutDiffuserEtablissement',
    ];

    return _Carte(
      titre: '1. Compte connecté',
      sousTitre: 'document users/{uid} brut, sans passer par les modèles',
      child: _compte!.enEchec
          ? _Erreur(resultat: _compte!)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Ligne('uid', FirebaseAuth.instance.currentUser?.uid ?? '—'),
                for (final cle in attendus)
                  _Ligne(
                    cle,
                    _compte!.valeur!.containsKey(cle)
                        ? _format(_compte!.valeur![cle])
                        : 'absent',
                    absent: !_compte!.valeur!.containsKey(cle),
                  ),
              ],
            ),
    );
  }

  Widget _blocEtablissement() {
    return _Carte(
      titre: '2. Établissement',
      child: _etablissement!.enEchec
          ? _Erreur(resultat: _etablissement!)
          : _etablissement!.valeur == null
              ? const Text('Aucun document trouvé.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Ligne('id', _etablissement!.valeur!.id),
                    _Ligne('nom', _etablissement!.valeur!.nom),
                  ],
                ),
    );
  }

  Widget _blocUnites() {
    return _Carte(
      titre: '3. Unités',
      sousTitre: 'lues depuis Firestore, triées par ordre',
      child: _unites!.enEchec
          ? _Erreur(resultat: _unites!)
          : _unites!.valeur!.isEmpty
              ? const Text('Aucune unité accessible.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final unite in _unites!.valeur!)
                      _Ligne(unite.id, '${unite.nom}  (ordre ${unite.ordre})'),
                  ],
                ),
    );
  }

  Widget _blocEffectifs() {
    var total = 0;
    for (final resultat in _usagersParUnite.values) {
      total += resultat.valeur?.length ?? 0;
    }

    return _Carte(
      titre: '4. Usagers par unité',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entree in _usagersParUnite.entries)
            entree.value.enEchec
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _Erreur(resultat: entree.value, prefixe: entree.key),
                  )
                : _Ligne(entree.key, '${entree.value.valeur!.length} usager(s)'),
          const Divider(height: 20),
          _Ligne('TOTAL', '$total usager(s)'),
        ],
      ),
    );
  }

  Widget _blocUsagerDetail() {
    return _Carte(
      titre: '5. Un usager en détail',
      child: _usagerDetail!.enEchec
          ? _Erreur(resultat: _usagerDetail!)
          : _usagerDetail!.valeur == null
              ? const Text('Aucun usager accessible.')
              : Builder(
                  builder: (context) {
                    final u = _usagerDetail!.valeur!;
                    final c = u.consentImage;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Ligne('id', u.id),
                        _Ligne('prenom', u.prenom),
                        _Ligne('nom', u.nom),
                        _Ligne('uniteId', u.uniteId),
                        _Ligne('etablissementId', u.etablissementId),
                        _Ligne('anneeNaissance', '${u.anneeNaissance}'),
                        _Ligne('âge (calculé)', '${u.ageApproximatif()} ans'),
                        _Ligne('photoUrl', u.photoUrl ?? 'null'),
                        _Ligne('actif', '${u.actif}'),
                        const Divider(height: 20),
                        _Ligne('consentImage.individuelle', '${c.individuelle}'),
                        _Ligne('consentImage.groupe', '${c.groupe}'),
                        _Ligne('consentImage.etablissement', '${c.etablissement}'),
                        _Ligne('  dateConsentement', '${c.dateConsentement}'),
                        _Ligne('  versionTexte', c.versionTexte ?? 'null'),
                        _Ligne('  saisiPar', c.saisiPar ?? 'null'),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _blocTestEcriture() {
    final resultat = _testEcriture;

    return _Carte(
      titre: "6. Test d'écriture",
      sousTitre: 'usagers/zzz_diagnostic_ecriture — doit être refusé',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resultat == null)
            const Text('Non lancé.')
          else if (resultat.refusDePermission)
            const _Verdict(
              texte: 'Refusé (comportement attendu)',
              couleur: Color(0xFF1B7F4F),
              icone: Icons.check_circle_outline,
            )
          else if (resultat.enEchec)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Verdict(
                  texte: 'Échec, mais PAS un refus de règle',
                  couleur: Color(0xFFB26A00),
                  icone: Icons.warning_amber_outlined,
                ),
                const SizedBox(height: 6),
                _Erreur(resultat: resultat),
              ],
            )
          else
            const _Verdict(
              texte: 'ÉCRITURE ACCEPTÉE — défaut grave, à corriger '
                  'immédiatement (la règle allow write: if false ne '
                  's’applique pas)',
              couleur: Color(0xFFC62828),
              icone: Icons.error_outline,
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _testerEcriture,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.roseViolet),
            child: const Text("Tenter l'écriture"),
          ),
        ],
      ),
    );
  }

  static String _format(Object? valeur) {
    if (valeur == null) return 'null';
    if (valeur is List) return valeur.isEmpty ? '[] (vide)' : valeur.join(', ');
    return '$valeur';
  }
}

// --- Petits composants d'affichage -----------------------------------------

class _Carte extends StatelessWidget {
  const _Carte({required this.titre, required this.child, this.sousTitre});

  final String titre;
  final String? sousTitre;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.roseViolet.withValues(alpha: 0.5), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.marine,
            ),
          ),
          if (sousTitre != null) ...[
            const SizedBox(height: 2),
            Text(
              sousTitre!,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.marine.withValues(alpha: 0.55),
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne(this.cle, this.valeur, {this.absent = false});

  final String cle;
  final String valeur;
  final bool absent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              cle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.marine.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              valeur,
              style: TextStyle(
                fontSize: 12,
                fontWeight: absent ? FontWeight.w400 : FontWeight.w700,
                fontStyle: absent ? FontStyle.italic : FontStyle.normal,
                color: absent ? Colors.grey.shade600 : AppColors.marine,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Erreur extends StatelessWidget {
  const _Erreur({required this.resultat, this.prefixe});

  final _Resultat resultat;
  final String? prefixe;

  @override
  Widget build(BuildContext context) {
    final refus = resultat.refusDePermission;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (refus ? const Color(0xFFB26A00) : const Color(0xFFC62828)).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            refus
                ? '${prefixe == null ? '' : '$prefixe — '}REFUS DE PERMISSION (règle Firestore)'
                : '${prefixe == null ? '' : '$prefixe — '}ERREUR (autre qu\'un refus de règle)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: refus ? const Color(0xFFB26A00) : const Color(0xFFC62828),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            resultat.erreur ?? '',
            style: TextStyle(fontSize: 11, color: AppColors.marine.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.texte, required this.couleur, required this.icone});

  final String texte;
  final Color couleur;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, color: couleur, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texte,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: couleur),
          ),
        ),
      ],
    );
  }
}
