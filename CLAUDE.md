# Relio — Le lien numérique du médico-social

## Contexte projet

Relio est une plateforme SaaS mobile connectant les établissements médico-sociaux, les professionnels et les familles. Le fondateur, Séb, est éducateur spécialisé depuis 20 ans et coordinateur en IME (Institut Médico-Éducatif). Il n'est pas développeur : explique tes choix techniques simplement, en français, et procède écran par écran avec validation visuelle avant de passer au suivant.

**Philosophie produit :** simplicité, accessibilité, sécurité, utilité terrain. Toujours privilégier la solution simple. Penser MVP avant vision long terme.

**Stratégie MVP :** test interne dans l'unité IME de Séb → présentation à la direction → extension aux autres établissements de l'association.

**Cibles de compilation MVP :** Android (test sur Pixel 9a physique) + Web (Firebase Hosting — les familles/collègues sur iPhone utiliseront la web app installée sur leur écran d'accueil). Le code doit rester 100 % compatible iOS pour une compilation native ultérieure (aucune dépendance incompatible iOS).

## Stack technique

- **Flutter** (Dart), projet neuf — migration depuis un prototype FlutterFlow qui sert de référence visuelle uniquement
- **Firebase** : Authentication, Firestore (région eur3), Storage (eur4), Cloud Messaging — projet Firebase existant, plan Blaze
- État : commencer simple (Provider ou Riverpod), pas d'architecture sur-dimensionnée
- Environnement : Windows 11, VS Code, Pixel 9a en débogage USB, Chrome pour le web

## Identité visuelle

- **Turquoise principal :** `#18BEA0`
- **Marine (textes) :** `#173A6A`
- **Rose-violet (CTA / boutons d'action) :** `#D94BB5`
- **Police :** Nunito (google_fonts)
- Éléments décoratifs : vagues et cercles hérités des écrans d'authentification
- Canvas de référence : 390×844 px, mais largeurs fluides (jamais de largeurs fixes en pixels)
- **Règles d'espacement :** 24 px après le header, 20 px entre les blocs, 8 px entre un label et son widget

## Architecture des données (Firestore — 11 collections)

`etablissements`, `unites`, `usagers`, `users`, `publications`, `commentaires`, `agenda`, `documents`, `notifications`, `messages`, `codes_invitation`

**Principes :**
- Multi-tenant : hiérarchie établissement → unité → usager
- Les professionnels ont une liste `unites_acces` (unités auxquelles ils ont accès) ; toute liste d'usagers affichée à un pro est filtrée par ses `unites_acces`
- Création de compte par code d'invitation (collection `codes_invitation`)
- Routage post-connexion selon le rôle : familles / professionnels / admin
- Séb a un accès de niveau coordinateur couvrant plusieurs unités

**Rôles :** famille (liée à un ou plusieurs usagers), professionnel (accès par unités), admin établissement.

## Logique métier : les 3 types de publication

1. **Individuelle** — concerne 1 usager. Visible par : la famille concernée + les professionnels autorisés (unités d'accès). Ajoutée automatiquement au journal de vie de l'usager.
2. **Groupe** — concerne une unité, avec sélection des usagers présents (tous pré-cochés, le pro décoche les absents). Visible par : les familles des usagers concernés + les professionnels concernés. Ajoutée au journal de vie de chaque usager concerné.
3. **Établissement** — pas de sélection d'usagers. Visible par tous (familles + professionnels). Valorise la vie institutionnelle.

Chaque publication : texte (max 1000 caractères), 1 à 5 photos, auteur, date, likes, commentaires, notifications.

## Écrans (référence : maquettes FlutterFlow — Séb fournira des captures)

### Périmètre SESSION 1 — test de validation (ne pas déborder)
1. **Écran de connexion (Login)** : logo Relio, champs email + mot de passe, bouton connexion rose-violet, lien « Mot de passe oublié », éléments décoratifs vagues/cercles, fond dans l'esprit turquoise
2. **FeedFamillePage** : header avec logo à gauche + cloche de notifications à droite (pas de titre de page) ; liste de PublicationCard ; footer 4 icônes (Accueil / Journal de vie / Agenda / Profil)
3. **Composant PublicationCard** : avatar + horodatage, image bord-à-bord hauteur 200 px, rangée like/commentaire avec compteurs, texte, 2 premiers commentaires affichés, bottom sheet pour tous les commentaires (fermeture par swipe vers le bas). Pas de badge de contexte sur les publications.

Pour la session 1 : données factices (mock) acceptables, la connexion Firestore réelle viendra ensuite. Objectif : valider la fidélité visuelle et le workflow avant de migrer le reste.

### Écrans suivants (sessions ultérieures, déjà spécifiés côté design)
- Splash, Welcome, Inscription (avec champ code d'invitation), Mot de passe oublié
- FeedProPage (identique au feed famille + bouton de création de publication)
- CreatePublicationPage : écran unique avec ChoiceChips Individuelle / Groupe / Établissement (turquoise plein = sélectionné, blanc bordure turquoise = non sélectionné), blocs conditionnels selon le type, sélection photos max 5 (miniatures 80×80, case « + Ajouter » à bordure turquoise pointillée), compteur 0/1000, bouton « Publier » pleine largeur rose-violet
- JournalDeViePage : header turquoise avec nom de l'usager en sous-titre, filtres de période ChoiceChips (Tout / Ce mois / Cette semaine), liste de PublicationCard, état vide chaleureux et illustré
- SelectionUsagerJournalPage (pros uniquement) : liste d'usagers filtrée par unites_acces, item = avatar 40 px + nom, ligne entière tappable
- Navigation Journal de vie : famille = accès direct depuis le footer (un seul usager associé) ; pro = via la page de sélection OU en tapant le nom/avatar d'un usager sur une PublicationCard
- Profil (version famille) : Infos personnelles, Documents, Paramètres (mot de passe, notifications, confidentialité/RGPD, aide), Déconnexion

## Contraintes et vigilance

- **RGPD et données sensibles** : les données concernent des enfants et adultes en situation de handicap. Aucune donnée réelle pendant le développement. Prévoir dès le départ des règles de sécurité Firestore strictes (jamais de règles ouvertes, même « temporairement »).
- **Accessibilité** : valeur fondamentale du projet (public TSA notamment). Tailles de texte respectueuses des réglages système, contrastes suffisants, zones tappables généreuses (min 48 px).
- Ne jamais affirmer de garanties de sécurité invérifiables ; vocabulaire conforme RGPD.
- Interface intégralement en français.

## Méthode de travail avec Séb

- Une fonctionnalité à la fois, validation par capture d'écran avant de continuer
- Expliquer ce que tu fais en langage clair (pas de jargon non expliqué)
- Classer toute recommandation : **MVP indispensable / Amélioration future / Vision long terme**
- Challenger les idées risquées, en cofondateur direct mais bienveillant
- Commandes utiles à rappeler à Séb : `flutter run` (choisir le Pixel 9a ou Chrome), `r` pour hot reload, `R` pour hot restart, `q` pour quitter
