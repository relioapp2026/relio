# Brief — Uniformiser le chrome des écrans de création

**Chantier :** Design / cohérence d'interface
**Déclencheur :** écart repéré par Séb pendant la validation R3a
**Prérequis :** validation R3a close (scénarios 3 à 6)
**Périmètre :** 2 fichiers, aucun changement de logique ni de données

---

## 1. Le constat

Quatre écrans portent le même formulaire (bloc `VisibiliteSelector` + champs + bouton
d'action), mais deux chromes différents.

| | `create_publication` / `create_evenement` | `envoyer_document` / `envoyer_message` |
|---|---|---|
| Fond du `Scaffold` | défaut (blanc) | `AppColors.turquoise` |
| En-tête | `Row` bricolée sur place : bouton retour turquoise en `Material`, titre marine centré, `SizedBox(width: 44)` de compensation | `SimpleTurquoiseHeader` (composant partagé) |
| Titre | marine sur fond clair | blanc sur bandeau turquoise |
| Marges horizontales | 20 px | 16 px |
| Bouton d'action | **turquoise** | **rose-violet** |
| Pied de page | `RelioFooter` (« Relio • créé pour vous avec ❤️ ») | aucun |

## 2. Ce ne sont pas deux conventions à départager

Les écrans de création sont **hors charte**, sur deux points documentés :

- **CLAUDE.md, identité visuelle** : le rose-violet est la couleur des CTA et boutons
  d'action. Le turquoise est la couleur principale, pas celle des actions.
- **CLAUDE.md, spécification de `CreatePublicationPage`** : « bouton "Publier" pleine
  largeur **rose-violet** ». L'écran ne respecte donc pas sa propre spec écrite.

`SimpleTurquoiseHeader` est par ailleurs le composant d'en-tête partagé des pages
secondaires (Journal de vie, Cahier de liaison, Documents, Messages, Sélection d'usager).
Les deux écrans de création sont les seuls à en avoir une copie manuelle.

C'est cohérent avec la préférence déjà exprimée : la cohérence du chrome à l'échelle de
l'app prime sur la fidélité littérale à la maquette.

---

## 3. Modifications

**Fichiers touchés : `create_publication_screen.dart`, `create_evenement_screen.dart`.**
Rien d'autre.

1. `Scaffold(backgroundColor: AppColors.turquoise)` — sans ça le bandeau ne rejoint pas
   le haut de l'écran sous la `SafeArea`.
2. Remplacer l'en-tête manuel par `SimpleTurquoiseHeader(title: …)` — la flèche retour
   est intégrée au composant, le `SizedBox(width: 44)` de compensation disparaît.
3. Structure `Column` → `SimpleTurquoiseHeader` puis `Expanded(child: AuthBackground(…))`,
   comme les écrans d'envoi.
4. Marges du formulaire : 20 → 16 px, alignées sur les écrans d'envoi.
5. Bouton d'action en `AppColors.roseViolet` (« Publier », « Créer l'événement »). Il est
   déjà pleine largeur via `CrossAxisAlignment.stretch`.

---

## 4. Trois décisions à trancher

**a) `RelioFooter` sur les écrans de création.**
Le composant est documenté comme « mention discrète en bas des écrans d'authentification ».
Il est présent sur les deux écrans de création, absent des deux écrans d'envoi, absent des
autres pages secondaires. L'uniformisation implique de le retirer.
→ *Recommandation : le retirer.* C'est un élément d'écran d'accueil, pas de formulaire.

**b) Position du bouton d'action.**
Sur les quatre écrans, le bouton est aujourd'hui le dernier élément du `ScrollView` : il
faut faire défiler pour l'atteindre. Il n'est **pas** épinglé en bas.
→ *Recommandation : ne rien changer maintenant.* Épingler le bouton est une amélioration
d'ergonomie réelle (et bénéficierait aux quatre écrans), mais c'est un autre sujet que
l'uniformisation — à traiter séparément pour ne pas mélanger deux intentions.

**c) `CreatePublicationScreen` est atteint depuis le bouton « + » du feed.**
Passer à `SimpleTurquoiseHeader` change la flèche retour de `Navigator.pop()` explicite à
`maybePop()`. Comportement identique ici, mais à vérifier au test.

---

## 5. Hors périmètre

- Aucune modification de logique, de validation de formulaire ou de lecture de données.
- `VisibiliteSelector` n'est pas touché — il vient d'être migré en R3a.
- Les écrans d'envoi ne bougent pas : ce sont eux la référence.
- L'épinglage du bouton en bas (voir 4b).

---

## 6. Validation

Sur Pixel 9a, les quatre écrans côte à côte :

1. Bandeau turquoise identique, titre blanc centré, flèche retour au même endroit.
2. Bouton d'action rose-violet, pleine largeur, sur les quatre.
3. Marges latérales identiques d'un écran à l'autre.
4. Le retour fonctionne depuis les quatre écrans, sans écran blanc intermédiaire.
5. Clavier ouvert : le formulaire reste défilable, le bandeau ne se déforme pas.

**Définition de terminé :** `flutter analyze` sans erreur, les 5 points ci-dessus validés
visuellement, commit unique.
