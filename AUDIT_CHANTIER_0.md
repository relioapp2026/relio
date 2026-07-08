# Audit Chantier 0 — Noms utilisés comme identifiants

**Date :** 2026-07-08
**Périmètre :** intégralité de `lib/` (modèles, écrans, widgets, mock data)
**Méthode :** lecture complète des 53 fichiers `.dart` du projet + recherche croisée des motifs `usagerId`, `uniteId`, `usagersIds`, `Nom`, comparaisons `==`/`.contains()`.
**Rappel :** aucun fichier n'a été modifié. Ce document ne liste que des constats.

---

## Constat central

Le projet utilise aujourd'hui **deux mécanismes d'identification incompatibles** pour la même entité (usager / unité), selon l'écran :

- **Circuit Agenda / Publications** : usagers identifiés par leur **nom complet** (`"Léo Martin"`, `"Lucas Martin"`...), unités par leur **nom complet** (`"Unité Papillons"`).
- **Circuit Documents / Messages** : usagers identifiés par leur **prénom seul** (`"Lucas"`, `"Chloé"`...), unités par un **nom différent** (`"Unité Les Papillons"` vs `"Unité Papillons"` dans l'autre circuit).

Ces deux circuits ne se recoupent pas systématiquement (ex. "Lucas Martin" dans un circuit, "Lucas" dans l'autre), et aucun des deux ne protège contre les homonymes. C'est le problème de fond à corriger avant Firestore.

---

## A. Modèles de données sans champ ID stable

| Fichier | Élément | Constat |
|---|---|---|
| `lib/models/document.dart:35,38` | `Document.usagerNom` / `Document.uniteNom` | Champs qui portent la portée (individuelle/groupe) — aucun `usagerId`/`uniteId` en parallèle. |
| `lib/models/message.dart:29,32` | `Message.usagersIds` / `Message.uniteId` | Le nom du champ ("Ids") est trompeur : il contient en réalité des **noms** (`['Lucas']`, `'Unité Les Papillons'`). |
| `lib/models/evenement.dart:27,28` | `Evenement.usagersIds` / `Evenement.uniteId` | Même problème : noms stockés dans des champs nommés comme des IDs. |
| `lib/data/mock_data.dart:142-153` | Classe `UsagerUnite` | Pas de champ `id` — seulement `prenom`, `nom`, `age`, `avatarColor`. |
| `lib/data/mock_data.dart:156-161` | Classe `UniteAvecUsagers` | Pas de champ `id` — seulement `nom` et la liste d'usagers. |
| `lib/data/mock_data.dart:84-89` | Classe `FamilleInfo` | Pas d'id propre à l'usager rattaché ; `usagerNom` (String) sert de clé de correspondance. |
| — | Modèle `Publication` | **Inexistant.** Aucun fichier `lib/models/publication.dart`. Les publications du feed sont des littéraux inline dans `feed_famille_screen.dart` / `feed_pro_screen.dart`, sans id (ni pour la publication, ni pour son auteur). |

---

## B. Paramètres de composants utilisés comme identifiant/clé

| Fichier:ligne | Paramètre | Constat |
|---|---|---|
| `lib/screens/journal_de_vie_screen.dart:57` (`usagerName`) | `JournalDeVieScreen.usagerName` | Seul identifiant transmis pour savoir "de qui" est le journal — pas d'`usagerId` en parallèle. |
| `lib/widgets/visibilite_selector.dart:12-20` | `VisibiliteSelection.usagerId` / `.uniteId` / `.usagersPresentsIds` | Noms de champs trompeurs : contiennent les **noms** choisis dans des `List<String>` (`mockUsagers`/`mockUnites`), pas des ids. Alimente ensuite directement `Document`, `Message`, `Evenement`. |
| `lib/screens/unite_detail_screen.dart:15` | `UniteDetailScreen.unite` | Reçoit l'objet `UniteAvecUsagers` entier (sans id) ; le titre de l'écran affiche `unite.nom`, seule donnée d'identification disponible. |
| `lib/widgets/publication_card.dart:23,9` | `PublicationCard.authorName` / `PublicationComment.authorName` | Affichage pur aujourd'hui (pas de comparaison), mais aucun id auteur n'existe en parallèle — à traiter en même temps que la création du modèle `Publication`. |

---

## C. Navigation transportant un nom plutôt qu'un ID

| Fichier:ligne | Constat |
|---|---|
| `lib/screens/selection_usager_journal_screen.dart:66-71` | `Navigator.push(JournalDeVieScreen(usagerName: usager.name, ...))` : le nom complet est le seul identifiant transmis pour ouvrir le journal du bon usager. |
| `lib/screens/profil_screen.dart:325,43-46` | `_handleUniteDetail` pousse `UniteDetailScreen(unite: mockUnitesAvecUsagers[i])` : l'objet transporté n'a pas d'id, seulement `nom`. |

---

## D. Mock data / structures où le nom sert de clé

| Fichier:ligne | Constat |
|---|---|
| `lib/data/mock_data.dart:15-21` (`mockUsagers`) | `List<String>` de noms complets, traitée comme "liste d'identifiants" pour Agenda/Publications. |
| `lib/data/mock_data.dart:23-27` (`mockUnites`) | `List<String>` de noms d'unité, même logique. |
| `lib/data/mock_data.dart:45,56,66` (`mockEvenements`) | `usagersIds: ['Léo Martin']`, `uniteId: 'Unité Étoiles'`, `uniteId: 'Unité Papillons'` — noms complets en clé de portée. |
| `lib/data/mock_data.dart:132-136` (`mockUnitesAvecFamilles`) | Une **3ᵉ nomenclature** d'unités ("Unité Les Écureuils"...), différente de `mockUnites` et de `mockUnitesAvecUsagers`. |
| `lib/data/mock_data.dart:140` (`mockUsagersAvecFamilles`) | Liste de **prénoms seuls**, dérivée de `mockFamilles`, distincte de `mockUsagers` (noms complets) bien que représentant en partie les mêmes enfants. |
| `lib/data/mock_data.dart:94-103` (`mockFamilles`) | La Map est correctement clée par `uid` (bonne pratique), mais la correspondance famille↔usager repose sur `FamilleInfo.usagerNom` (un prénom). |
| `lib/data/mock_data.dart:114-119` (`familleUidPourUsager`) | Résout un uid de famille **en comparant des prénoms** (`entry.value.usagerNom == usagerNom`). |
| `lib/data/mock_data.dart:296` (doc4) | `Document(usagerNom: 'Lucas', ...)` : portée individuelle identifiée par prénom seul. |

---

## E. Logique de filtrage/comparaison sur des noms plutôt que des IDs

| Fichier:ligne | Constat | Gravité |
|---|---|---|
| `lib/screens/agenda_famille_screen.dart:17-18,44-52` | `_monUsager = 'Léo Martin'`, `_monUnite = 'Unité Papillons'` puis `evenement.usagersIds.contains(_monUsager)` / `evenement.uniteId == _monUnite`. | **Critique** — deux usagers homonymes dans des unités différentes verraient les événements l'un de l'autre. |
| `lib/data/mock_data.dart:114-118` (`familleUidPourUsager`) | Comparaison de prénoms pour retrouver une famille (déjà cité en D). | Élevée — fonction utilisée pour router documents/messages vers les bonnes familles. |
| `lib/screens/envoyer_document_screen.dart:16-28`, `lib/screens/envoyer_message_screen.dart:12-24` (`_resolveDestinataires`) | Résolution des destinataires via `familleUidPourUsager(nomUsager)` — hérite du même risque. | Élevée — impacte l'envoi réel des documents/messages aux familles. |

---

## Synthèse par écran/fichier (vue d'ensemble)

| Fichier | Paramètre composant | Navigation | Mock data | Comparaison | Modèle sans ID |
|---|:---:|:---:|:---:|:---:|:---:|
| `models/document.dart` | | | | | ✅ |
| `models/message.dart` | | | | | ✅ |
| `models/evenement.dart` | | | | | ✅ |
| `data/mock_data.dart` | | | ✅ | ✅ | ✅ |
| `widgets/visibilite_selector.dart` | ✅ | | | | |
| `widgets/publication_card.dart` | ✅ | | | | ✅ (Publication absente) |
| `screens/journal_de_vie_screen.dart` | ✅ | | | | |
| `screens/selection_usager_journal_screen.dart` | | ✅ | | | |
| `screens/unite_detail_screen.dart` | ✅ | | | | |
| `screens/profil_screen.dart` | | ✅ | | | |
| `screens/agenda_famille_screen.dart` | | | | ✅ (critique) | |
| `screens/envoyer_document_screen.dart` | | | | ✅ | |
| `screens/envoyer_message_screen.dart` | | | | ✅ | |
| `screens/create_evenement_screen.dart` | (consomme VisibiliteSelector) | | | | |
| `screens/create_publication_screen.dart` | (consomme VisibiliteSelector) | | | | |
| `screens/feed_famille_screen.dart` / `feed_pro_screen.dart` | | | | | ✅ (Publication absente) |

**Écrans/fichiers vérifiés et jugés sans problème d'identification par nom** (uid déjà utilisé correctement) : `documents_famille_screen.dart`, `documents_pro_screen.dart`, `messages_pro_screen.dart`, `messagerie_famille_screen.dart`, `document_detail_screen.dart` (hors champ hérité du modèle), `message_detail_screen.dart` (idem), `notifications_pro_screen.dart`, `notifications_famille_screen.dart`, `nouvelle_communication_screen.dart`, `edit_profil_screen.dart`, `main.dart`, écrans d'authentification (Login/Inscription/Splash/Welcome/Mot de passe oublié), écrans Paramètres.

---

## Estimation du volume de travail pour la correction

**Fichiers à modifier en profondeur : ~9**
- `data/mock_data.dart` (restructuration centrale : unifier les 3 nomenclatures d'unités et les 2 nomenclatures d'usagers en une seule source avec ids stables)
- `models/document.dart`, `models/message.dart`, `models/evenement.dart` (ajout de vrais champs id, dépréciation des champs "Nom" comme clé)
- `widgets/visibilite_selector.dart` (faire émettre des ids au lieu de noms)
- `widgets/publication_card.dart` + création d'un modèle `Publication`
- `screens/agenda_famille_screen.dart` (remplacer les constantes de nom par un id d'usager/unité connecté)

**Fichiers à ajuster en cascade (consommateurs) : ~8-10**
- `create_evenement_screen.dart`, `create_publication_screen.dart`, `envoyer_document_screen.dart`, `envoyer_message_screen.dart` (adaptation à la nouvelle `VisibiliteSelection` par id)
- `selection_usager_journal_screen.dart`, `journal_de_vie_screen.dart` (navigation par id)
- `profil_screen.dart`, `unite_detail_screen.dart` (navigation par id d'unité)
- `feed_famille_screen.dart`, `feed_pro_screen.dart` (passage au futur modèle `Publication`)

**Total estimé : 17-19 fichiers**, soit l'équivalent d'une session de travail dédiée ("Chantier 0"), à traiter **avant** le prochain chantier de mock data avec ids stables déjà planifié. Le point le plus risqué est `agenda_famille_screen.dart` (E1) : c'est le seul endroit où le bug d'homonymie est déjà démontrable avec les données mock actuelles (deux usagers appelés "Léo Martin" ou "Lucas Martin" existent potentiellement dans des listes différentes).

---

## Prochaine étape suggérée

Définir un jeu de mock data avec ids stables (`usager_id`, `unite_id`, `famille_uid` déjà en place) comme source unique de vérité, remplaçant les 5 listes de noms actuellement dispersées (`mockUsagers`, `mockUnites`, `mockUnitesAvecFamilles`, `mockUsagersAvecFamilles`, et les usagers imbriqués dans `mockUnitesAvecUsagers`).
