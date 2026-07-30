# Brief R1 — Référentiel Firestore : `etablissements`, `unites`, `usagers`

**Chantier :** Référentiel (prérequis bloquant du chantier Publications)
**Étape :** R1 — Schéma + peuplement
**Cible Firebase :** `relio-dev` **exclusivement**
**Statut :** validé par Séb, prêt pour implémentation

---

## 0. Pourquoi ce chantier existe

Aujourd'hui, seules `users/{uid}` et `codes_invitation` sont branchées sur Firestore.
Les usagers et les unités ne vivent que dans `mock_data.dart`.

Sans ces collections, aucune règle de sécurité ne peut vérifier :
- qu'un pro a le droit de publier sur un usager (nécessite `usager.uniteId`) ;
- qu'une famille doit recevoir une publication (nécessite l'unité de son usager).

La règle serait obligée de faire confiance au client. Le chantier Publications est donc bloqué
jusqu'à la clôture de R2.

**Périmètre de R1 :** créer les collections et les peupler. Rien d'autre.
Les modèles Dart, le service de lecture et les règles de sécurité sont en R2.
Le débranchement de `mockUsagersCatalogue` est en R3.

---

## 1. Données strictement fictives

Le seed ne doit contenir **aucune identité réelle**. Les prénoms et noms sont inventés.
Seule la *structure* est calquée sur l'effectif réel de l'IME.

Le fichier JSON du seed est versionné dans Git : c'est la raison de cette règle, et elle est
non négociable. Aucun fichier contenant des identités réelles ne doit entrer dans le dépôt,
même temporairement, même ignoré par `.gitignore` — l'historique Git est irréversible.

---

## 2. Schéma Firestore

### `etablissements/{etablissementId}`

```
etab_001
  nom: string              // "IME Robert Seguy"
  dateCreation: timestamp
```

Un seul document au MVP.

### `unites/{uniteId}`

```
unite_001
  nom: string              // libellé affiché, éditable
  etablissementId: string  // "etab_001"
  ordre: int               // ordre d'affichage dans les listes
  dateCreation: timestamp
```

Trois documents :

| id | `nom` | `ordre` |
|---|---|---|
| `unite_001` | Proximité | 1 |
| `unite_002` | Polyvalence | 2 |
| `unite_003` | Orientation | 3 |

**Point d'attention :** `unite_003` s'appelait « Formation ». Le champ `nom` est la seule
source du libellé affiché — aucun écran, aucune règle, aucune requête ne doit dépendre du nom.

### `usagers/{usagerId}`

```
usager_001
  prenom: string
  nom: string
  uniteId: string           // "unite_001" | "unite_002" | "unite_003"
  etablissementId: string   // "etab_001"
  anneeNaissance: int
  photoUrl: string?         // null au seed
  actif: bool               // true
  dateCreation: timestamp
  consentImage: {
    individuelle: bool      // false
    groupe: bool            // false
    etablissement: bool     // false
    dateConsentement: timestamp?   // null
    versionTexte: string?          // null
    saisiPar: string?              // null
  }
```

**Champs volontairement absents :** `modaliteAccueil`, `hebergement`, `presenceJournee`,
`nuitsInternat`. Décision actée : la présence d'un usager sur une activité est choisie par le
pro au moment de publier. Ces champs seront introduits au chantier Cahier de liaison, s'ils
s'avèrent nécessaires. Ne pas les ajouter « au cas où ».

**`consentImage` est présent dès le seed** avec les trois booléens à `false` : les toggles de
consentement écrivent aujourd'hui dans `mockUsagersCatalogue`, donc nulle part. Créer les
champs maintenant évite d'avoir à les rétro-remplir.

---

## 3. Extension du catalogue : 35 → 55 usagers

`mockUsagersCatalogue` contient aujourd'hui 35 usagers, ids `usager_001` à `usager_035`.

### Contraintes impératives

1. **Les ids `usager_001` à `usager_035` ne changent pas**, et leurs `prenom` / `nom`
   existants ne changent pas. Tout a déjà été validé visuellement sur Pixel 9a.
2. **La paire d'homonymes `usager_017` / `usager_032` (« Emma Bernard ») est conservée
   telle quelle.** C'est un cas de test anti-régression qui a coûté une session entière.
   L'effectif réel ne fournit pas d'homonyme, donc celui-ci doit rester artificiel.
3. **Ajouter 20 usagers**, ids `usager_036` à `usager_055`, prénoms et noms fictifs.
4. **Réaffecter les `uniteId`** pour atteindre la répartition cible.

### Répartition cible

| Unité | Effectif |
|---|---|
| `unite_001` (Proximité) | 14 |
| `unite_002` (Polyvalence) | 27 |
| `unite_003` (Orientation) | 14 |
| **Total** | **55** |

**55 = agrément de l'IME**, pas l'effectif du jour (53 à la rentrée 2025/2026). Choix
délibéré : semer à pleine charge évite de découvrir un problème de liste longue le jour où
l'établissement est complet.

Le déséquilibre est intentionnel : il reproduit la structure réelle et fait apparaître les
problèmes de listes longues et de pagination qu'une répartition égale masquerait.

L'usager supplémentaire par rapport à l'effectif réel est affecté à `unite_002`, la plus
grande. Répartition modifiable en une ligne dans `referentiel.json` si Séb préfère autrement.

### Cas de test à introduire : une fratrie sur deux unités

Deux usagers doivent partager le même `nom` de famille tout en étant dans **deux unités
différentes** — par exemple un dans `unite_002` et un dans `unite_003`.

C'est le cas qui valide :
- `usagersIds` en array sur le compte famille ;
- la requête `cibles array-contains-any` du feed famille, qui doit agréger deux unités.

Ce n'est pas un doublon de la paire « Emma Bernard » : celle-ci teste l'homonymie complète
(même prénom + même nom), celle-ci teste la fratrie (nom partagé, unités distinctes).
Les deux cas coexistent.

### Années de naissance

Répartir sur une amplitude réaliste pour un IME (adolescents et jeunes adultes), avec une
progression cohérente entre les unités : Proximité plus jeune en moyenne, Orientation plus âgée.
Pas de valeur identique pour tout le monde — l'objectif est que les tris et filtres futurs
aient de la matière.

---

## 4. Ajout au schéma `users` : `peutModerer`

Décision actée : un compte de modération est nécessaire dès le MVP.

Motif : aujourd'hui, seul l'auteur peut masquer sa publication. Si l'auteur est absent, parti
de l'établissement, ou s'il est lui-même le problème, il n'existe **aucun recours** pour
retirer une photo publiée par erreur. Inacceptable sur une plateforme diffusant des images
d'enfants en situation de handicap, et bloquant pour l'autorisation du pilote.

### Forme retenue

**Pas un troisième rôle.** Un booléen de permission sur un compte pro existant, sur le modèle
exact de `peutDiffuserEtablissement`.

```
users/{uid}
  ...champs existants inchangés...
  peutModerer: bool        // défaut false
```

Un rôle `admin` distinct obligerait chaque règle, chaque requête et chaque écran à gérer un
troisième cas. Un booléen ajoute une clause `OR`.

### Portée

**Aucun nouveau chemin de lecture n'est nécessaire.** Le compte de Séb possède déjà les trois
unités dans `unitesAcces` : la requête `cibles array-contains-any [unite_001, unite_002,
unite_003, etab_001]` couvre donc déjà l'intégralité de l'établissement. `peutModerer`
n'affecte que :
- les règles d'**écriture** (autoriser `masquee: true` sur un document dont on n'est pas l'auteur) ;
- l'affichage du menu « ⋮ » sur les publications des autres.

La portée de modération est donc l'union de `unitesAcces`. Ce comportement se généralise
proprement au multi-établissement plus tard.

### Ce que R1 fait, et ne fait pas

R1 se limite à **créer le champ** et à le positionner sur les comptes concernés.

Positionner `peutModerer: true` sur **deux comptes** (Séb + la collègue en formation à la
coordination), pas un seul : un unique modérateur en congé laisse l'établissement sans recours.

Critère de choix du second modérateur : quelqu'un qui ouvre Relio de toute façon dans son
travail quotidien. Un compte de direction dormant produirait une modération théorique.

`peutModerer` et `peutDiffuserEtablissement` sont deux permissions **indépendantes** : ne pas
les coupler, ni dans le seed, ni dans les règles.

Aucune interface d'attribution au MVP : ces booléens se positionnent à la main dans la console
Firestore. Acceptable à deux modérateurs sur un établissement, ingérable au deuxième — c'est
la première brique de Relio Admin (Phase 2).

La mécanique de modération elle-même appartient au chantier Publications :
- modération des commentaires → étape 4
- modération des publications → étape 6, en élargissant la condition du menu « ⋮ » de
  « utilisateur == auteur » à « utilisateur == auteur OU `peutModerer` »

### Soft deletion, y compris pour un modérateur

Masquer la publication d'un collègue est un acte de management. S'il ne laisse aucune trace,
il génère du conflit d'équipe et interdit tout recours si la modération était elle-même une
erreur.

Champs à prévoir sur `publications` et `commentaires` (implémentation en chantier Publications,
pas ici) :

```
masquee: bool
dateMasquage: timestamp?
masqueePar: string?      // uid du modérateur ou de l'auteur
motifMasquage: string?
```

L'auteur doit **voir** que sa publication a été masquée et par qui — elle ne disparaît pas
silencieusement.

Aucune suppression définitive. Le droit à l'effacement RGPD concerne le dossier d'un usager
qui quitte l'établissement : sujet distinct, déjà ouvert, hors modération.

---

## 5. Script de seed

### Emplacement et forme

```
tools/seed/
  seed-referentiel.js      // script Node.js, firebase-admin
  data/referentiel.json    // données fictives, versionné
  README.md                // comment l'exécuter
```

`referentiel.json` contient les trois blocs : `etablissements`, `unites`, `usagers`.
Le script ne contient aucune donnée en dur.

### Comportement exigé

**Idempotent.** Écriture par `set()` avec `{ merge: true }` sur un id explicite, jamais `add()`.
Rejouer le script deux fois de suite ne doit produire aucun doublon et aucun changement
au second passage.

Justification : l'effectif de l'IME sera rééquilibré à la rentrée. Le seed n'est pas un
script à usage unique, c'est l'outil de synchronisation du référentiel jusqu'à l'arrivée de
Relio Admin.

**`dateCreation` préservée.** Ne pas écraser une `dateCreation` existante lors d'un rejeu.
Si le document existe déjà, conserver la valeur en base.

**Garde-fou anti-production — obligatoire.** Avant toute écriture, le script lit le
`projectId` effectif des credentials et **abandonne immédiatement** s'il ne vaut pas
exactement `relio-dev`. Message d'erreur explicite. Aucun flag, aucune variable
d'environnement ne doit permettre de contourner ce contrôle : pour cibler un autre projet,
il faudra modifier le script sciemment.

Le projet de production `relio-618ca` ne doit jamais pouvoir être atteint par accident.

**Sortie lisible.** Le script affiche un récapitulatif final : nombre de documents créés,
nombre mis à jour, nombre inchangés, par collection. Puis un contrôle de cohérence :
effectif réel par unité comparé à la répartition attendue (14 / 27 / 14), avec un échec
explicite en cas d'écart.

### Authentification

Compte de service `relio-dev`, clé JSON **hors du dépôt**.

**Le script résout le chemin de la clé lui-même**, dans cet ordre :

1. variable d'environnement `GOOGLE_APPLICATION_CREDENTIALS`, si définie ;
2. sinon, chemin par défaut `<répertoire personnel>/.relio/relio-dev-sa.json`, construit avec
   `os.homedir()` et `path.join()` pour rester portable Windows / macOS / Linux ;
3. sinon, échec avec un message explicite indiquant les deux emplacements attendus et la
   procédure de génération de la clé.

Objectif : `node tools/seed/seed-referentiel.js` doit fonctionner sans aucune commande
préalable. L'environnement de travail est Windows / PowerShell, où une variable
d'environnement de session doit sinon être retapée à chaque ouverture de terminal — source
d'erreur récurrente et inutile.

La variable d'environnement reste prioritaire pour permettre de pointer ponctuellement vers
une autre clé sans modifier le script.

**Ne jamais coder le chemin en dur dans le script**, et ne jamais lire la clé depuis le dépôt.

Ajouter un script npm pour raccourcir l'invocation :

```json
"scripts": { "seed": "node tools/seed/seed-referentiel.js" }
```

Le README documente : génération de la clé depuis la console `relio-dev`, emplacement attendu,
commande d'exécution, et rappel que la clé du SDK Admin **contourne intégralement
`firestore.rules`** — d'où le garde-fou sur le `projectId`.

---

## 6. Écritures client

**Aucune, sur les trois collections.**

Le référentiel se peuple par seed, et plus tard par Relio Admin. Les règles de sécurité
correspondantes (`allow write: if false`) sont posées en R2 — R1 ne touche pas
`firestore.rules`.

Conséquence assumée : les toggles de consentement image resteront non fonctionnels jusqu'à
ce que le sujet soit traité explicitement. C'est un écart RGPD connu et documenté, sans
donnée réelle en jeu à ce stade.

---

## 7. Définition de « terminé »

- [ ] `flutter analyze` sans erreur
- [ ] `mockUsagersCatalogue` étendu à 55 usagers, ids 001–035 inchangés, homonymes préservés
- [ ] `referentiel.json` cohérent avec le catalogue Dart
- [ ] Seed exécuté sur `relio-dev`, 1 établissement + 3 unités + 55 usagers visibles en console
- [ ] Seed rejoué une seconde fois : 0 création, 0 modification
- [ ] Garde-fou anti-production testé (échec attendu confirmé sur un `projectId` différent)
- [ ] Contrôle de cohérence 14 / 27 / 14 vert
- [ ] CLAUDE.md mis à jour : chantier Référentiel, seed script désormais réel, champs d'accueil
      explicitement écartés du MVP avec la raison
- [ ] `peutModerer` ajouté au schéma `users`, positionné à `true` sur deux comptes
- [ ] Seed exécutable par `npm run seed` sans variable d'environnement préalable
- [ ] Commit unique et descriptif

---

## 8. Hors périmètre de R1

- Modèles Dart `Usager` / `Unite` et service de lecture → **R2**
- Règles de sécurité sur les trois collections → **R2**
- Débranchement de `mockUsagersCatalogue` dans les écrans → **R3**, après comptage des références
- Photos d'usagers dans Storage → chantier Publications, étape 3
- Écran de recueil du consentement image → chantier dédié
- Mécanique de modération (menu « ⋮ » élargi, champs `masqueePar` / `motifMasquage`) →
  chantier Publications, étapes 4 et 6
- Journal de modération consultable, notification de l'auteur, Relio Admin complet
  (gestion des utilisateurs, des unités, statistiques) → amélioration future / Phase 2
