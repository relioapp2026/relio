# Brief — Publications, Étape 1 : texte seul

**Chantier :** Publications (1 de 3 itérations)
**Étape :** 1 — câblage Firestore, création, feed, modifier/masquer
**Prérequis :** Référentiel R1/R2/R3a clos, uniformisation des écrans de création close (commit `59f4fa7`)
**Cible Firebase :** `relio-dev` exclusivement

> **⚠️ Ce point a changé deux fois — lire l'état final ci-dessous, pas le §2 seul.**
>
> **État actuel (2026-08-16) : la création d'une publication de type `etablissement` EXIGE
> `peutDiffuserEtablissement` sur le compte pro auteur.** La permission gate désormais trois
> surfaces — documents, messages, et le fil d'actu. Le §2 de ce brief avait donc raison sur
> le *principe* du gating ; il a été à tort déclaré erroné le 31/07, et la clause rétablie le
> 16/08. Voir CLAUDE.md, « Permission diffusion établissement », sous-section « portée
> étendue ».
>
> **La forme finale de la règle diffère quand même du §2**, sur deux points :
> - elle intègre aussi la **décision (b)** (vérification de `uniteId in unitesAcces` pour les
>   portées individuelle et groupe), absente de la proposition d'origine ;
> - elle est extraite dans une fonction `peutCreer(data)` avec un `let`, pour garantir **un
>   seul `get()`** — même raisonnement que `accesLecture()`. Les deux portées se vérifient
>   par un ternaire, pas par un `||` : la branche établissement n'est plus un laissez-passer,
>   elle porte maintenant sa propre condition.
>
> **Conséquences sur le reste du brief :**
> - §7 scénario 2 — « `pro.test` publie pour l'établissement » → **refusée**. Ce scénario a
>   été validé en « réussit » le 31/07 ; il s'inverse. Changement de comportement voulu, pas
>   une régression.
> - §8 — la ligne « gating `peutDiffuserEtablissement` fonctionnel » **s'applique** de
>   nouveau.
> - Le chip « Établissement » est **grisé** dans le fil d'actu quand la permission manque,
>   comme pour les documents et les messages (`restrictionEtablissementActive` du
>   `VisibiliteSelector`, aucun composant nouveau).
>
> **Pourquoi le revirement :** le motif d'origine — le fil d'actu est du contenu de
> valorisation institutionnelle, moins sensible qu'un document — n'a pas résisté à
> l'ouverture des photos (étape 2). Une photo diffusée à toutes les familles de
> l'établissement est au moins aussi sensible qu'un document. Attention : cette restriction
> contrôle *qui* publie, pas *ce que la photo montre* — le point bloquant de l'étape 2 sur le
> consentement image des publications d'établissement **reste ouvert**.

---

## 0. Pourquoi cette étape compte plus que sa taille ne le suggère

Deux choses se produisent ici pour la première fois dans tout le projet :

1. **Le premier chemin d'écriture client d'une vraie collection de contenu.** Jusqu'ici, seules
   les collections d'authentification (`users`, `codes_invitation`) acceptent une écriture
   client, et le référentiel est verrouillé en lecture seule par conception. `publications` est
   la première collection où un pro écrit du contenu qui sera lu par des familles.
2. **Les patterns que Messages, Documents et Agenda réutiliseront tels quels** : la structure de
   `cibles` pour interroger un feed unique famille/pro, le coût des règles de lecture, la
   pagination, et le mécanisme de modération. Une erreur de conception ici se retrouvera
   multipliée par quatre collections.

D'où l'exigence : **valider le plan avant d'écrire une ligne**, comme pour R1/R2/R3a — mais avec
une attention particulière portée aux règles de sécurité, qui sont ici bien plus risquées que
tout ce qu'on a écrit jusqu'à présent.

**Périmètre de cette étape :** texte seul. Les photos sont l'étape 2, les likes et commentaires
l'étape 3. Le Journal de vie (étape 5) réutilisera cette même collection avec un simple filtre —
zéro travail supplémentaire de schéma à anticiper ici.

---

## 1. Schéma Firestore : `publications/{publicationId}`

```
publications/{publicationId}
  auteurId: string              // uid du pro, jamais falsifiable côté règle
  auteurNom: string             // dénormalisé à la création : "Prénom Nom"
  typePublication: string       // "individuelle" | "groupe" | "etablissement"
  usagersConcernes: array<string>   // ids usagers concernés — champ sémantique,
                                     // alimente le Journal de vie. Vide pour "etablissement".
  uniteId: string?              // unité choisie pour "groupe" ou "individuelle". Null pour
                                 // "etablissement".
  etablissementId: string       // "etab_001", toujours renseigné
  cibles: array<string>         // champ technique de requêtage, voir §2
  texte: string
  dateCreation: timestamp
  modifiee: bool                // false à la création
  dateModification: timestamp?  // null jusqu'à la première édition
  masquee: bool                 // false à la création
  dateMasquage: timestamp?
  masqueePar: string?           // uid de qui a masqué (auteur ou modérateur)
  motifMasquage: string?
```

**Champs volontairement absents de cette étape :** aucun champ photo, aucun compteur de likes
ou de commentaires. Ils s'ajouteront de façon additive aux étapes 2 et 3, sans migration : un
document sans ces champs doit rester lisible (cf. tolérance aux champs absents déjà appliquée
en R2 sur `Usager`).

### Le champ `cibles`

Décision actée avant l'ouverture du chantier Référentiel, à appliquer maintenant :

| Type | `cibles` |
|---|---|
| Individuelle | `[usagerId, uniteId]` |
| Groupe | `[usagerId_1, usagerId_2, ..., uniteId]` |
| Établissement | `[etablissementId]` |

Le feed pro interroge `cibles array-contains-any [...unitesAcces, etablissementId]`. Le feed
famille interroge `cibles array-contains-any [...usagersIds, etablissementId]`. Une seule
requête, un seul index composite, pour les deux rôles.

`cibles` est dérivable de `usagersConcernes` + `uniteId` + `typePublication` — c'est de la
dénormalisation assumée, pas une seconde source de vérité. Elle se calcule côté client à la
création et ne change jamais après (les champs qui la déterminent sont immuables, §3).

### `auteurNom` dénormalisé

Le Feed doit afficher l'auteur sans lecture supplémentaire par publication — sinon chaque
publication affichée coûte un `get()` sur `users/{auteurId}`. Le nom est figé au moment de la
publication ; s'il change ensuite (mariage, correction), les publications passées gardent
l'ancien nom. C'est un compromis d'affichage assumé, pas une exigence d'exactitude rétroactive.

---

## 2. Règles de sécurité — le point le plus sensible du brief

### Création (`allow create`)

```
allow create: if request.auth != null
  && request.resource.data.auteurId == request.auth.uid
  && userDoc().role == 'pro'
  && (
    request.resource.data.typePublication != 'etablissement'
    || userDoc().get('peutDiffuserEtablissement', false) == true
  );
```

`auteurId` ne peut jamais être autre chose que l'uid de l'appelant — sinon n'importe quel pro
pourrait publier au nom d'un collègue.

### Le point que je ne peux pas trancher seul : la vérification de `cibles`/`usagersConcernes`

La règle peut vérifier facilement que l'auteur est un pro, et que la diffusion établissement est
autorisée. Ce qu'elle **ne peut pas vérifier efficacement**, c'est que chaque usager listé dans
`usagersConcernes` appartient bien à une unité de `unitesAcces` du pro — cela demanderait un
`get()` par usager de la liste à l'intérieur de la règle, ce qui est coûteux et plafonné.

Deux options :

- **(a) Faire confiance à l'app pour construire `usagersConcernes` correctement**, parce que
  l'interface ne propose déjà que les usagers filtrés par `unitesAcces` (c'est le comportement
  validé de `CreatePublicationPage`). Résidu de risque : un client modifié pourrait forcer
  l'écriture d'un id hors périmètre. Mais je te rappelle qu'on s'est refusé cette hypothèse
  ailleurs (« la règle ne doit jamais croire le téléphone sur parole »).
- **(b) Vérifier au moins `uniteId`** (un seul champ, un seul `get()`) : `uniteId in
  userDoc().get('unitesAcces', [])` quand le type est « groupe » ou « individuelle ». Ça borne
  la publication à une unité autorisée, même si un usager précis dans la liste pourrait en
  théorie appartenir à une autre unité du même établissement.

**Décision validée par Séb : option (b).** Elle coûte un seul `get()` supplémentaire, borne
l'essentiel du risque, et laisse la vérification fine (l'usager précis) à l'app. Le résidu de
risque théorique (un client modifié pourrait forcer un id d'usager hors unité dans la liste) est
accepté en connaissance de cause pour le MVP — à reconsidérer si un incident réel le justifie.

### Modification (`allow update`)

Deux cas distincts, à ne pas confondre dans une seule règle :

**Édition du texte, par l'auteur uniquement :**
```
diff().affectedKeys().hasOnly(['texte', 'modifiee', 'dateModification'])
&& resource.data.auteurId == request.auth.uid
```

**Masquage, par l'auteur OU un modérateur :**
```
diff().affectedKeys().hasOnly(['masquee', 'dateMasquage', 'masqueePar', 'motifMasquage'])
&& (
  resource.data.auteurId == request.auth.uid
  || userDoc().get('peutModerer', false) == true
)
```

**Champs immuables, sur les deux cas :** `auteurId`, `auteurNom`, `dateCreation`,
`typePublication`, `usagersConcernes`, `uniteId`, `cibles`, `etablissementId`. Aucune combinaison
de champs modifiés ne doit pouvoir les toucher.

### Suppression

`allow delete: if false`, sans exception. Le masquage est la seule forme de retrait.

### Lecture

```
allow read: if request.auth != null
  && resource.data.cibles.hasAny(
       userDoc().get('unitesAcces', []).concat([userDoc().etablissementId])
     ) // ou l'équivalent côté usagersIds pour une famille
```

À adapter selon la syntaxe exacte disponible pour combiner `unitesAcces`/`usagersIds` et
`etablissementId` dans un seul `hasAny` — vérifier ce que le langage des règles permet
réellement, ne pas supposer.

**Note :** la règle de lecture ne filtre pas `masquee`. Une publication masquée reste lisible
par les comptes dans son périmètre — c'est la couche d'affichage (§5) qui décide qui voit quoi,
pas la règle. Une règle qui masquerait le document changerait le sens de « masquer » : l'auteur
ne pourrait plus jamais revoir sa propre publication masquée, ce qui contredit la décision déjà
prise (« l'auteur doit voir que sa publication a été masquée, pas la voir disparaître »).

---

## 3. Lecture du feed : `Future` paginé, pas de flux temps réel — pour cette étape

Publications est un contenu qui évolue (nouvelles publications, futurs likes/commentaires),
contrairement au référentiel où R2 avait choisi `Future` parce que rien n'y change en session.
Ici, un flux temps réel (`Stream`, `snapshots()`) serait le choix naturel à terme.

**Mais combiner flux temps réel et pagination par curseur est significativement plus complexe**
qu'un seul des deux. Ma recommandation pour cette étape : **requêtes `Future` paginées par
curseur (`startAfter` sur `dateCreation`), rafraîchies par tirer-pour-actualiser**, et reporter
le passage à un flux temps réel à l'étape 4 (likes/commentaires), où l'instantanéité apporte une
vraie valeur (un compteur qui bouge en direct) alors qu'ici elle n'en apporterait presque aucune
(une nouvelle publication qui met deux secondes à apparaître après un tirer-pour-actualiser
n'est pas gênant pour un cahier de liaison).

**Décision validée par Séb : `Future` paginé pour cette étape.** Choix d'architecture qui engage
Messages/Documents/Agenda derrière — le même pattern sera réutilisé tel quel jusqu'à ce que
l'étape 4 introduise le temps réel.

`masquee` est filtré côté client, pas dans la requête (même raisonnement qu'en R2 pour `actif` :
éviter un index composite supplémentaire sur une collection dont la volumétrie reste modeste).

---

## 4. Affichage : qui voit quoi sur une publication masquée

- **Une famille, ou un pro qui n'est ni l'auteur ni modérateur :** la publication masquée est
  filtrée côté client, elle n'apparaît pas dans le feed, comme si elle n'existait pas.
- **L'auteur, ou un compte avec `peutModerer: true` :** la publication masquée reste visible dans
  leur propre feed, mais rendue différemment — un encart clair indiquant qu'elle est masquée, par
  qui, et si possible le motif. Pas de disparition silencieuse.

Le menu « **⋮** » sur `PublicationCard` (déjà spécifié) est visible si `auteurId == uid courant
OU peutModerer == true`. Il propose *Modifier* (ouvre `CreatePublicationScreen` pré-remplie,
texte éditable, type et sélection d'usagers désactivés) et *Masquer* (confirmation simple, puis
écriture des 4 champs de masquage).

**Correction par rapport à une note plus ancienne du projet :** la modération n'est plus classée
« amélioration future » — c'est une décision revue depuis, `peutModerer` est MVP indispensable et
s'applique dès cette étape.

---

## 5. Compteurs de likes/commentaires : présents à l'écran, inertes pour l'instant

`PublicationCard` a déjà ces éléments dans sa maquette validée. Pour cette étape :

- Afficher `0` partout, sans lire ni écrire aucun champ de comptage (le schéma n'en a pas).
- Le tap sur l'icône like ou sur « voir les commentaires » ne déclenche aucune action réseau —
  soit désactivé visuellement, soit sans effet. Pas de simulation d'un comportement qui n'existe
  pas encore.

---

## 6. Le rôle IAM Firebase Rules Admin — le bon moment de le régler

Signalé en fin de R2 comme bloquant pour vérifier automatiquement les règles les plus risquées
de l'app. `publications` en introduit justement une nouvelle candidate directe — la règle de
création avec vérification `unitesAcces`, et la règle de modification à deux branches. Si ce
n'est pas encore fait, c'est le moment : les tests automatisés couvriront un vrai risque, pas un
exercice théorique.

---

## 7. Validation sur Pixel 9a

Utiliser les trois comptes déjà existants : ton compte (3 unités, `peutModerer: true`),
`pro.test` (1 unité, `peutModerer: false`), et le compte famille fratrie (`usager_015` +
`usager_033`, deux unités).

1. **Créer une publication individuelle, une de groupe, une d'établissement** avec ton compte —
   les trois doivent réussir, `cibles` correcte à chaque fois (vérifier en console).
2. **`pro.test` tente une publication établissement** → refusée par la règle
   (`peutDiffuserEtablissement: false`).
3. **`pro.test` tente une publication de groupe sur `unite_002`** (hors de son `unitesAcces`) →
   refusée, si l'option (b) du §2 est retenue.
4. **Le feed du compte famille fratrie** affiche les publications de `usager_015`, `usager_033`,
   et celles d'établissement — rien d'autre.
5. **Modifier sa propre publication** (auteur) → réussit, `modifiee` et `dateModification` se
   posent, les champs immuables ne bougent pas.
6. **Masquer la publication d'un autre pro avec ton compte modérateur** → réussit, l'auteur voit
   l'encart de masquage dans son propre feed, les autres ne la voient plus du tout.
7. **`pro.test` tente de masquer la publication de quelqu'un d'autre** → refusée.
8. **Test d'écriture sur un identifiant bidon valide** (pas de double underscore, cf. la leçon de
   R2) → `permission-denied` confirmé pour un compte hors périmètre.
9. **Pagination** : créer plus de publications que la taille d'une page, vérifier que
   « charger plus » fonctionne et ne duplique rien.
10. **Mode avion** sur le feed → message d'erreur avec bouton réessayer, pas de crash.

---

## 8. Définition de « terminé »

- [ ] `flutter analyze` sans erreur
- [ ] Collection `publications` câblée, modèle Dart tolérant aux champs absents
- [ ] `cibles` correctement calculée pour les 3 types de publication
- [ ] Règles de sécurité déployées : création, modification à deux branches, suppression
      interdite, lecture scopée — décision (a)/(b) du §2 tranchée et documentée
- [ ] `CreatePublicationScreen` écrit réellement dans Firestore, gating
      `peutDiffuserEtablissement` fonctionnel
- [ ] Feed pro et famille lisent Firestore via `cibles`, pagination par curseur fonctionnelle
- [ ] Menu « ⋮ » : modifier réservé à l'auteur, masquer ouvert à l'auteur et aux modérateurs
- [ ] Publication masquée : invisible pour les autres, visible-avec-mention pour
      auteur/modérateur
- [ ] Les 10 scénarios de la section 7 validés sur Pixel 9a
- [ ] Rôle IAM Firebase Rules Admin vérifié ou accordé
- [ ] CLAUDE.md à jour : étape 1 close, décision (a)/(b) du §2 consignée, choix
      Future-paginé-plutôt-que-Stream documenté comme pattern pour Messages/Documents/Agenda
- [ ] Commit unique et descriptif

---

## 9. Hors périmètre de cette étape

- Photos, Storage, compression → **étape 2**
- Likes, commentaires, sous-collection → **étape 3**
- Journal de vie (filtre sur cette même collection) → **étape 5**
- Notifications push à la publication → non cadré, futur chantier
- Passage à un flux temps réel → à reconsidérer à l'étape 4
- R3b (écriture du consentement image) → chantier séparé, prérequis du pilote
