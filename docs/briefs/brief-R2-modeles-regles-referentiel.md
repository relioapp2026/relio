# Brief R2 — Modèles Dart, service de lecture et règles de sécurité du référentiel

**Chantier :** Référentiel
**Étape :** R2 — Lecture depuis Firestore
**Prérequis :** R1 close (commit `52e9c8d`), `etablissementId` corrigé à `etab_001` sur les
comptes de test et les codes d'invitation, trois flux validés sur Pixel 9a
**Cible Firebase :** `relio-dev` exclusivement

---

## 0. Objectif et état de départ

Les collections `etablissements`, `unites` et `usagers` existent en base mais sont
**illisibles depuis l'app** : aucune règle ne les couvre, donc refus par défaut. R2 lève ce
refus de façon contrôlée et fournit la couche Dart qui les lit.

**R2 ne débranche aucun écran.** `mockUsagersCatalogue` reste la source de tous les écrans
existants jusqu'à R3. Aucun écran validé visuellement ne doit être modifié.

Conséquence à traiter explicitement : sans écran qui consomme le service, rien ne prouve que
les règles et le service fonctionnent. D'où l'écran de diagnostic temporaire de la section 4,
qui est le livrable de validation de cette étape.

---

## 1. Modèles Dart

Trois modèles dans `lib/models/`, en lecture seule (aucun `toFirestore`, la collection n'est
pas écrite par le client).

```dart
class Etablissement {
  final String id;
  final String nom;
}

class Unite {
  final String id;
  final String nom;              // libellé affiché, source unique
  final String etablissementId;
  final int ordre;
}

class Usager {
  final String id;
  final String prenom;
  final String nom;
  final String uniteId;
  final String etablissementId;
  final int anneeNaissance;
  final String? photoUrl;
  final bool actif;
  final ConsentImage consentImage;
}

class ConsentImage {
  final bool individuelle;
  final bool groupe;
  final bool etablissement;
  final DateTime? dateConsentement;
  final String? versionTexte;
  final String? saisiPar;
}
```

### Exigences

- `fromFirestore(DocumentSnapshot)` sur chaque modèle. L'`id` vient **toujours** de
  `snapshot.id`, jamais d'un champ du document.
- **Aucun champ `age`.** L'âge se calcule à l'affichage. Le champ `age` de `MockUsager` reste
  en place jusqu'à R3 et n'est pas touché.
- **Tolérance aux champs absents.** Un document dont `consentImage` ou `photoUrl` manque doit
  produire un objet valide (valeurs par défaut : booléens à `false`, `actif` à `true`), pas une
  exception. Un crash de l'app parce qu'un document de référentiel est incomplet serait un
  défaut de robustesse inacceptable en production.
- **Ne pas concaténer de préfixe.** Le libellé affiché d'une unité est `unite.nom`, rien
  d'autre. Décision actée en R1.

---

## 2. Service de lecture

`lib/services/referentiel_service.dart`.

```dart
Future<Etablissement?> getEtablissement(String id);
Future<List<Unite>> getUnites(List<String> uniteIds);        // triées par `ordre`
Future<List<Usager>> getUsagersParUnite(String uniteId);     // triés par nom, prenom
Future<List<Usager>> getUsagersPourPro(List<String> unitesAcces);
Future<List<Usager>> getUsagersPourFamille(List<String> usagersIds);
Future<Usager?> getUsager(String usagerId);
```

### Exigences

- `Future`, pas de `Stream`. Le référentiel ne change pas pendant une session : un flux temps
  réel coûterait des lectures pour rien. Les flux temps réel seront pour `publications`.
- `getUsagersPourPro` : `where('uniteId', whereIn: unitesAcces)`. Documenter dans le code que
  `whereIn` plafonne à 30 valeurs — sans conséquence à 3 unités, mais à connaître avant le
  multi-établissement.
- `getUsagersPourFamille` : `whereIn` sur `FieldPath.documentId`, même plafond.
- **Filtrer `actif == false` côté client, pas dans la requête.** Un `where` supplémentaire
  imposerait un index composite dont on n'a pas besoin à cette volumétrie.
- **Ne pas mettre en cache dans cette étape.** Le cache est une optimisation qui masquerait les
  refus de règles pendant la validation. À reconsidérer une fois R3 close, si la mesure de
  consommation le justifie.
- Les erreurs `permission-denied` doivent être **distinguables** des autres échecs et remontées
  telles quelles, pas avalées dans un `catch` générique. C'est ce qui permettra de savoir si un
  problème vient des règles ou du code.

---

## 3. Règles de sécurité

Ajouter à `firestore.rules`, sans toucher aux règles existantes sur `users` et
`codes_invitation`.

### Principes

- **Écriture client interdite partout** sur les trois collections : `allow write: if false`.
  Le référentiel se peuple par seed, plus tard par Relio Admin.
- Lecture scopée par le document `users/{uid}` du demandeur.
- Un pro accède aux usagers des unités présentes dans son `unitesAcces`.
- Une famille accède aux usagers dont l'id figure dans son `usagersIds`.

### Structure attendue

```
function userDoc() {
  return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
}

match /etablissements/{etablissementId} {
  allow read: if request.auth != null
              && userDoc().etablissementId == etablissementId;
  allow write: if false;
}

match /unites/{uniteId} {
  allow read: if request.auth != null
              && uniteId in userDoc().unitesAcces;
  allow write: if false;
}

match /usagers/{usagerId} {
  allow read: if request.auth != null
              && (
                resource.data.uniteId in userDoc().unitesAcces
                || usagerId in userDoc().usagersIds
              );
  allow write: if false;
}
```

À adapter à la forme réelle des documents `users` : un compte `famille` n'a pas
nécessairement de champ `unitesAcces`, et un compte `pro` n'a pas de `usagersIds`. **Un champ
absent ne doit pas provoquer une erreur d'évaluation de la règle** — utiliser
`userDoc().get('unitesAcces', [])` ou une vérification `'unitesAcces' in userDoc()` selon ce
que la syntaxe des règles permet. À vérifier, c'est un piège classique.

### Accès famille aux unités

Une famille doit-elle pouvoir lire le document `unites` de l'unité de son enfant ? Le libellé
« Polyvalence » sera affiché dans son app, donc oui. Mais `unitesAcces` n'existe pas sur un
compte famille.

**Décision : autoriser la lecture d'une unité à toute famille du même établissement.** Le nom
d'une unité n'est pas une donnée sensible, et la solution alternative — dériver l'unité depuis
les usagers de la famille — imposerait un `get()` par usager dans la règle. Simplicité contre
un risque nul.

### Attention au piège des requêtes de liste

Pour un `list`, les règles sont évaluées **par document retourné**. Une requête qui ramène un
seul document hors périmètre échoue **en entier**. Conséquence : le service doit toujours
contraindre sa requête au périmètre du demandeur — il ne peut pas requêter large en comptant
sur les règles pour filtrer. C'est déjà le cas dans la section 2, mais ça doit être commenté
dans le code, parce que c'est le contresens n°1 sur Firestore.

---

## 4. Écran de diagnostic temporaire

`lib/screens/diagnostic_referentiel_screen.dart`, accessible depuis Profil > Paramètres, avec
un libellé explicite du type « Diagnostic référentiel (temporaire) ».

**C'est le livrable de validation de R2.** Il permet de vérifier sur le Pixel 9a que les
règles et le service fonctionnent, sans toucher un seul écran déjà validé.

### Contenu affiché

1. **Compte connecté** : uid, `role`, `etablissementId`, `unitesAcces`, `usagersIds`,
   `peutModerer`, `peutDiffuserEtablissement`
2. **Établissement** : nom lu depuis Firestore, ou l'erreur
3. **Unités** : liste lue depuis Firestore, avec `id` et `nom`
4. **Usagers par unité** : effectif de chaque unité, et le total
5. **Un usager en détail** : tous les champs, `consentImage` compris
6. **Test d'écriture** : bouton qui tente d'écrire dans `usagers`. Doit afficher
   « refusé (comportement attendu) ». S'il réussit, c'est un défaut grave à corriger
   immédiatement.

### Exigences d'affichage

- Chaque bloc affiche soit son résultat, soit l'erreur **en texte lisible**, en distinguant
  `permission-denied` de toute autre erreur. Un bloc en échec ne doit pas empêcher les autres
  de s'afficher.
- Aucune donnée en dur : tout vient de Firestore via le service.
- L'écran est marqué `// TEMPORAIRE — à supprimer en R3` en tête de fichier, et référencé
  comme tel dans CLAUDE.md.

---

## 5. Comptes de test à créer

À faire par Séb en console, pas par le script. À documenter dans `tools/seed/README.md`.

### Compte famille à deux usagers

Un compte `role: "famille"` avec `usagersIds: ["usager_015", "usager_033"]` — la fratrie Petit,
répartie sur `unite_002` et `unite_003`.

Ce compte est le seul moyen de vérifier qu'une famille agrège deux unités. Il servira ensuite
à valider la requête `cibles array-contains-any` du feed au chantier Publications.

### Compte pro restreint à une unité

Un compte `role: "pro"` avec `unitesAcces: ["unite_001"]`, `peutModerer: false`,
`peutDiffuserEtablissement: false`.

Sans lui, **aucun test négatif n'est possible** : le compte de Séb possède les trois unités,
donc aucun usager n'est hors de son périmètre, donc rien ne prouve que les règles restreignent
quoi que ce soit.

Ce compte a une valeur durable au-delà de R2 : il vérifiera aussi la puce grisée
« Réservé à la coordination/direction » sur les options de diffusion établissement.

Ce n'est **pas** le compte de la collègue en formation à la coordination, qui recevra les mêmes
droits que Séb quand il sera créé.

---

## 6. Validation sur Pixel 9a

Dans cet ordre, sur l'écran de diagnostic.

**Compte pro de Séb (3 unités)**
- 3 unités affichées
- effectifs 14 / 27 / 14, total 55
- détail d'un usager complet
- test d'écriture : refusé

**Compte pro restreint (`unite_001`)**
- **1 seule unité** affichée
- **14 usagers**, pas 55
- une tentative de lecture d'un usager de `unite_002` doit être refusée
- test d'écriture : refusé

**Compte famille (fratrie Petit)**
- exactement **2 usagers**, `usager_015` et `usager_033`
- les deux unités correspondantes lisibles pour leur libellé
- aucun autre usager accessible
- test d'écriture : refusé

Le test qui compte vraiment est le deuxième : c'est le seul qui prouve que les règles
restreignent au lieu de simplement autoriser.

---

## 7. Mesure du coût des `get()`

Sujet ouvert depuis juillet, à instruire ici.

Chaque évaluation de règle appelle `get()` sur `users/{uid}`, ce qui est facturé comme une
lecture. La question : une liste de 27 usagers coûte-t-elle 1 lecture supplémentaire ou 27 ?

En principe Firestore mutualise les `get()` identiques au sein d'une même requête, donc 1.
**À vérifier plutôt qu'à supposer.**

### Protocole

1. Relever le compteur de lectures dans la console Firebase, onglet Utilisation
2. Ouvrir l'écran de diagnostic un nombre connu de fois avec le compte à 3 unités
3. Relever à nouveau

La console Firebase a une latence de plusieurs heures sur ces compteurs : la mesure se lit le
lendemain, pas dans la session. Ne pas bloquer R2 pour l'attendre.

### Si le coût s'avère linéaire

La sortie propre est de placer `unitesAcces` et `usagersIds` dans des **custom claims** du
token d'authentification, ce qui supprime le `get()` entièrement. Coût : une Cloud Function à
la création de compte, et une gestion de la péremption des tokens.

**Amélioration future**, déclenchée sur mesure réelle, jamais par anticipation.

---

## 8. Définition de « terminé »

- [ ] `flutter analyze` sans erreur
- [ ] Modèles `Etablissement`, `Unite`, `Usager`, `ConsentImage` créés, lecture seule
- [ ] `ReferentielService` créé, `permission-denied` distinguable des autres erreurs
- [ ] Règles déployées sur `relio-dev`, `allow write: if false` sur les trois collections
- [ ] Règles existantes sur `users` et `codes_invitation` inchangées
- [ ] Écran de diagnostic accessible et fonctionnel
- [ ] Aucun écran existant modifié, `mockUsagersCatalogue` intact
- [ ] Les trois scénarios de la section 6 validés sur Pixel 9a
- [ ] Test d'écriture refusé sur les trois comptes
- [ ] CLAUDE.md à jour : R2 close, écran de diagnostic signalé comme temporaire, protocole de
      mesure des `get()` consigné avec sa date de relevé
- [ ] Commit unique et descriptif

---

## 9. Hors périmètre de R2

- Débranchement de `mockUsagersCatalogue` dans les écrans → **R3**, après comptage des références
- Suppression de l'écran de diagnostic → **R3**
- Cache de lecture du référentiel → après R3, si la mesure le justifie
- Custom claims → amélioration future, conditionnée à la mesure de la section 7
- Écriture du référentiel, Relio Admin → Phase 2
- Collection `publications` et tout ce qui la concerne → chantier suivant
