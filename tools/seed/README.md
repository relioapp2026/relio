# Seed du référentiel Relio

Peuple les collections Firestore `etablissements`, `unites` et `usagers` sur **`relio-dev`**.

Ce n'est pas un script à usage unique : c'est l'outil de synchronisation du référentiel
jusqu'à l'arrivée de Relio Admin (Phase 2). L'effectif de l'IME sera rééquilibré à chaque
rentrée — le script est fait pour être rejoué.

---

## ⚠️ Deux règles non négociables

**1. Aucune identité réelle dans `data/referentiel.json`.**
Ce fichier est versionné dans Git, et l'historique Git est irréversible. Les prénoms et noms
sont inventés ; seule la *structure* (effectifs, répartition par unité) est calquée sur le réel.

**2. La clé du SDK Admin contourne intégralement `firestore.rules`.**
Elle ignore toutes les règles de sécurité et peut écrire n'importe où. C'est la raison du
garde-fou décrit plus bas — et la raison pour laquelle elle ne doit jamais entrer dans le dépôt.

---

## Installation (une seule fois)

### 1. Dépendances Node

Depuis la racine du projet (`C:\dev\relio`) :

```powershell
npm install
```

### 2. Générer la clé de compte de service

Dans la [console Firebase](https://console.firebase.google.com/) :

1. sélectionner le projet **`relio-dev`** (surtout pas `relio-618ca`, qui est la production) ;
2. ⚙️ **Paramètres du projet** → onglet **Comptes de service** ;
3. bouton **« Générer une nouvelle clé privée »** → **Générer la clé** ;
4. un fichier `.json` se télécharge.

### 3. Ranger la clé au bon endroit

Créer le dossier et y déposer le fichier téléchargé, renommé **`relio-dev-sa.json`** :

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.relio"
```

Chemin final attendu :

```
C:\Users\<vous>\.relio\relio-dev-sa.json
```

Le script trouve la clé tout seul à cet emplacement — aucune variable d'environnement à
définir, aucune commande à retaper à chaque ouverture de terminal.

> **Ne jamais déplacer cette clé dans le dépôt.** `.gitignore` couvre déjà les noms usuels
> (`*firebase-adminsdk*.json`, `*-sa.json`, `serviceAccountKey.json`, `tools/seed/*.json`),
> mais la seule garantie réelle est de la laisser hors de `C:\dev\relio`.

---

## Exécution

Depuis la racine du projet :

```powershell
npm run seed
```

Le script affiche : la clé utilisée, le projet ciblé, le bilan par collection
(créés / modifiés / inchangés), puis le contrôle de cohérence des effectifs.

**Vérification d'idempotence** — relancer immédiatement `npm run seed` doit afficher
`0 créé(s)   0 modifié(s)` sur les trois collections. Si ce n'est pas le cas, c'est un bug.

---

## Ce que fait le script

| Comportement | Détail |
|---|---|
| **Idempotent** | `set()` avec `{ merge: true }` sur un id explicite, jamais `add()`. Un document déjà conforme n'est pas réécrit. |
| **`dateCreation` préservée** | Écrite uniquement à la création. Un rejeu n'y touche jamais. |
| **Ne supprime jamais** | Un document présent en base mais absent du JSON est signalé comme orphelin, pas effacé. |
| **Aucune donnée en dur** | Tout vient de `data/referentiel.json`, y compris les valeurs par défaut et la répartition attendue. |
| **Validation avant écriture** | Ids uniques, `uniteId`/`etablissementId` existants, répartition conforme. Échec ⇒ rien n'est écrit. |
| **Contrôle après écriture** | Relit les effectifs réels en base et les compare à `repartitionAttendue`. |

### Garde-fou anti-production

Avant toute connexion, le script lit le `project_id` **dans la clé elle-même** et s'arrête
s'il ne vaut pas exactement `relio-dev`.

**Aucun flag ni variable d'environnement ne permet de le contourner** : cibler un autre projet
exige de modifier la constante `PROJET_AUTORISE` dans le script, sciemment. Le projet de
production `relio-618ca` ne doit jamais pouvoir être atteint par accident.

### Résolution du chemin de la clé

1. `GOOGLE_APPLICATION_CREDENTIALS` si la variable est définie (permet de pointer
   ponctuellement vers une autre clé sans toucher au script) ;
2. sinon `<répertoire personnel>/.relio/relio-dev-sa.json` ;
3. sinon échec, avec la procédure de génération rappelée dans le message.

---

## Modifier le référentiel

Tout se passe dans **`data/referentiel.json`** — jamais dans le `.js`.

- **Changer la répartition par unité** : bloc `repartitionAttendue`, puis ajuster les `uniteId`
  des usagers en conséquence. Le script refuse de tourner si les deux divergent.
- **Ajouter un usager** : nouvelle entrée dans `usagers` avec un id `usager_0XX` libre, et
  incrémenter le compte de son unité dans `repartitionAttendue`.
- **Renommer une unité** : champ `nom`. Aucun écran, aucune règle, aucune requête ne dépend du
  nom d'une unité — uniquement de son id.

---

## Correction à faire en console après le premier seed

Le référentiel utilise `etab_001` comme identifiant d'établissement. Les comptes de test créés
avant ce chantier portent encore l'ancienne valeur `ime_robert_seguy`, qui était un nom
d'affichage utilisé comme identifiant.

Tant que la correction n'est pas faite, ces comptes pointent vers un établissement inexistant,
et toute règle croisant `usagers.etablissementId` avec `users.etablissementId` échouera.

Dans la console Firestore de **`relio-dev`**, remplacer `ime_robert_seguy` par `etab_001` :

| Collection | Documents | Champ |
|---|---|---|
| `users` | le compte pro de test (Esteban) | `etablissementId` |
| `users` | le compte famille de test (KSOS Mama) | `etablissementId` |
| `codes_invitation` | **tous** les documents | `etablissementId` |

> Les trois doivent être corrigés **ensemble**. La règle `create` sur `users/{userId}` vérifie
> que le `etablissementId` du compte est identique à celui du code d'invitation
> (`firestore.rules`) : si l'un est corrigé et pas l'autre, toute nouvelle inscription famille
> sera refusée.

Après correction, revalider une connexion pro et une connexion famille sur le Pixel 9a.

---

## Attribution manuelle des permissions

Deux booléens sur `users/{uid}` ne sont **pas** gérés par ce script — ils se positionnent à la
main dans la console Firestore, faute d'interface d'attribution au MVP (première brique de
Relio Admin, Phase 2) :

- **`peutDiffuserEtablissement`** — autorise l'envoi de documents/messages en portée
  « établissement ».
- **`peutModerer`** — autorise le masquage d'une publication ou d'un commentaire dont on n'est
  pas l'auteur.

Ces deux permissions sont **indépendantes** : ne pas les coupler.

`peutModerer` doit être positionné sur **tous les comptes pro de coordination existants**, et
sur au moins deux comptes dès qu'un second existera : un unique modérateur en congé laisserait
l'établissement sans recours pour retirer une photo publiée par erreur.

Critère de choix : quelqu'un qui ouvre Relio de toute façon dans son travail quotidien. Un
compte de direction dormant produirait une modération théorique.

---

## Comptes de test à créer en console (chantier Référentiel, R2)

Ces deux comptes ne sont **pas** créés par le script : ils vivent dans `users`, pas dans le
référentiel. À créer à la main sur **`relio-dev`**.

Pour chacun : d'abord **Authentication → Ajouter un utilisateur** (email + mot de passe), puis
un document **`users/{uid}`** avec l'uid généré, contenant les champs ci-dessous.

> ⚠️ **`dateCreation` est obligatoire, de type `timestamp`.**
> `ProUser.fromFirestore` et `FamilleUser.fromFirestore` font un cast strict
> (`data['dateCreation'] as Timestamp`) : un compte sans ce champ fait **échouer la connexion**
> avec une erreur peu parlante. Même chose pour `nom`, `prenom`, `email`, `etablissementId`, et
> `unitesAcces` (pro) / `usagersIds` (famille) — aucun n'a de valeur de repli.
> Seuls `codeInvitationUtilise`, `peutDiffuserEtablissement` et `peutModerer` tolèrent l'absence.

### 1. Compte famille « fratrie » — deux usagers sur deux unités

```json
{
  "role": "famille",
  "nom": "Petit",
  "prenom": "Parent",
  "email": "<l'email saisi dans Authentication>",
  "etablissementId": "etab_001",
  "usagersIds": ["usager_015", "usager_033"],
  "dateCreation": "<timestamp — mettre la date du jour>"
}
```

`usager_015` (Léa Petit, `unite_002`) et `usager_033` (Nathan Petit, `unite_003`) : la fratrie
Petit, répartie sur deux unités.

C'est le **seul moyen de vérifier qu'une famille agrège deux unités**. Il servira ensuite à
valider la requête `cibles array-contains-any` du feed au chantier Publications.

### 2. Compte pro restreint à une seule unité

```json
{
  "role": "pro",
  "nom": "Restreint",
  "prenom": "Pro",
  "email": "<l'email saisi dans Authentication>",
  "etablissementId": "etab_001",
  "unitesAcces": ["unite_001"],
  "peutDiffuserEtablissement": false,
  "peutModerer": false,
  "dateCreation": "<timestamp — mettre la date du jour>"
}
```

Sans lui, **aucun test négatif n'est possible** : le compte de Séb possède les trois unités,
donc aucun usager n'est hors de son périmètre, donc rien ne prouve que les règles restreignent
quoi que ce soit.

Ce compte garde de la valeur au-delà de R2 : il vérifiera aussi la puce grisée
« Établissement » sur les écrans d'envoi de document/message.

Ce n'est **pas** le compte de la collègue en formation à la coordination, qui recevra les mêmes
droits que Séb quand il sera créé.

### Ce qu'on attend de chaque compte sur l'écran de diagnostic

| Compte | Unités | Usagers | Test d'écriture |
|---|---|---|---|
| Pro de Séb (3 unités) | 3 | 14 / 27 / 14, total **55** | refusé |
| **Pro restreint** | **1** | **14**, pas 55 | refusé |
| Famille fratrie | 2 | exactement **2** (`usager_015`, `usager_033`) | refusé |

Le deuxième est celui qui compte : c'est le seul qui prouve que les règles *restreignent* au
lieu de simplement autoriser.

---

## Référence

Brief complet : [`docs/briefs/brief-R1-referentiel-firestore.md`](../../docs/briefs/brief-R1-referentiel-firestore.md)
