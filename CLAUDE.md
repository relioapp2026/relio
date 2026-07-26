# Relio — Le lien numérique du médico-social

## Contexte projet

Relio est une plateforme SaaS mobile connectant les établissements médico-sociaux, les professionnels et les familles. Le fondateur, Séb, est éducateur spécialisé depuis 20 ans et coordinateur en IME (Institut Médico-Éducatif). Il n'est pas développeur : explique tes choix techniques simplement, en français, et procède écran par écran avec validation visuelle avant de passer au suivant.

**Philosophie produit :** simplicité, accessibilité, sécurité, utilité terrain. Toujours privilégier la solution simple. Penser MVP avant vision long terme.

**Stratégie MVP :** test interne dans l'unité IME de Séb → présentation à la direction → extension aux autres établissements de l'association.

**Cibles de compilation MVP :** Android (test sur Pixel 9a physique) + Web (Firebase Hosting — les familles/collègues sur iPhone utiliseront la web app installée sur leur écran d'accueil). Le code doit rester 100 % compatible iOS pour une compilation native ultérieure (aucune dépendance incompatible iOS).

## Stack technique

- **Flutter** (Dart), projet neuf — migration depuis un prototype FlutterFlow qui sert de référence visuelle uniquement
- **Firebase** : Authentication, Firestore (région eur3), Storage (eur4), Cloud Messaging — deux projets distincts, `relio-dev` (développement, plan Blaze — obligatoire depuis fin 2024 pour activer Storage, mais usage réel en dev solo avec données fictives reste dans le palier gratuit inclus) et un futur projet de production séparé (`relio-618ca`, également Blaze, déjà créé avant le début du chantier Flutter), pas d'émulateur local (voir « Chantier Back »)
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
- Convention de nommage des champs Firestore : camelCase (ex. `unitesAcces`, `dateCreation`, `consentImage`)
- Les professionnels ont une liste `unitesAcces` (unités auxquelles ils ont accès) ; toute liste d'usagers affichée à un pro est filtrée par ses `unitesAcces`
- Les professionnels ont aussi un champ booléen `peutDiffuserEtablissement` (faux par défaut) qui autorise ou non l'envoi de documents/messages en portée « établissement » — distinct du consentement image, et distinct des publications établissement du fil d'actu qui restent ouvertes à tous les pros sans restriction. Positionné manuellement en base pour le MVP, pas d'interface de gestion. **Non commencé** — voir section « Permission diffusion établissement » plus bas.
- Création de compte par code d'invitation (collection `codes_invitation` : `role`, `usagerId` ou `unitesAcces` selon le rôle, `etablissementId`, `utilise`, `dateCreation`, `dateExpiration` [toujours `null` au MVP, pas de vérification d'expiration], `creePar`). Rôle famille ou pro rattaché à la collection unique `users` (pas de collections séparées par rôle). Génération des codes au MVP via le script de seed Node.js existant, un code par usager/famille, distribué manuellement par Séb — pas d'écran de génération (reporté à Relio Admin, Phase 2)
- Chaque usager porte un champ `consentImage` (booléens `individuelle`/`groupe`/`etablissement`, faux par défaut, jamais présumé) qui autorise ou non l'apparition visible de sa photo par type de publication — voir « Consentement image » ci-dessous
- Routage post-connexion selon le rôle : familles / professionnels / admin
- Séb a un accès de niveau coordinateur couvrant plusieurs unités

**Rôles :** famille (liée à un ou plusieurs usagers), professionnel (accès par unités), admin établissement.

## Chantier Back (Firebase) — trajectoire actée

**Deux projets Firebase distincts** : `relio-dev` (développement) et `relio-618ca` (le futur projet de production, déjà créé avant le début du chantier Flutter, sous le nom d'affichage « Relio »). Développement en direct contre `relio-dev` — **pas d'émulateur Firebase local** : décision actée (revient sur une version antérieure de ce plan qui prévoyait un émulateur), plus de justification pour un projet solo sans données réelles à protéger à ce stade. Les données restent toujours fictives même une fois `relio-dev` connecté — voir « RGPD et données sensibles » plus bas.

Les deux projets sont en plan Blaze : Firestore seul reste dans le tier gratuit (Spark), mais Cloud Storage impose Blaze pour tout projet depuis fin 2024 (règle Google, pas un choix produit) — `relio-dev` a donc été passé en Blaze pour pouvoir activer Storage. Le palier gratuit inclus dans Blaze reste largement suffisant pour un usage de développement solo avec données fictives (facture réelle attendue : 0€).

**Phase 0 (terminée)** : Node.js + Firebase CLI + FlutterFire CLI installés, projet `relio-dev` créé (Authentication email/mot de passe, Firestore région eur3, Storage région eur4, tous activés), connecté au projet Flutter via `flutterfire configure` (`lib/firebase_options.dart` généré, apps Android + Web enregistrées — pas d'app iOS, pas de dossier `ios/` pour l'instant). `firebase_core` ajouté aux dépendances et `Firebase.initializeApp()` câblé dans `main.dart`, `flutter analyze` et `flutter build web` passent sans erreur.

**Phase 1 (terminée, pro et famille)** : premier compte pro réel créé manuellement sur `relio-dev` (Authentication + document `users/{uid}`, champ `role: "pro"`). C'est à cette phase que `peutDiffuserEtablissement` (bool, `false` par défaut) est devenu un vrai champ Firestore sur les comptes pro — jusqu'ici mock uniquement, voir « Permission diffusion établissement » plus bas (Item 4 du chantier Cahier de liaison). Modèle Dart `ProUser` (`lib/models/pro_user.dart`) créé. Première règle `firestore.rules` déployée : lecture de son propre document `users/{uid}` uniquement, tout le reste refusé par défaut. Testé de bout en bout sur Pixel 9a physique.

**Authentification générique pro/famille (terminée)** : modèle Dart `FamilleUser` (`lib/models/famille_user.dart`) créé, même structure que `ProUser` (`uid`, `nom`, `prenom`, `email`, `etablissementId`, `dateCreation`), avec `usagersIds` (`List<String>`, tableau même à un seul élément au MVP — pense fratrie dès le départ) au lieu de `unitesAcces`/`peutDiffuserEtablissement`. `AuthService.signIn` (`lib/services/auth_service.dart`) remplace l'ancienne `signInPro` (supprimée) : authentifie via Firebase Auth, lit `users/{uid}`, détermine le rôle et retourne un `ProUser` ou un `FamilleUser` selon la valeur de `role` (`StateError` explicite si le document n'existe pas ou si `role` est absent/inconnu), en alimentant respectivement `AuthService.currentProUser` ou `AuthService.currentFamilleUser`. `LoginScreen` reste un formulaire unique (pas d'écrans de connexion séparés) et route vers `FeedProScreen` ou `FeedFamilleScreen` selon le type retourné.

Bascule pro/famille validée de bout en bout sur Pixel 9a physique : un compte famille de test existe sur `relio-dev` (`role: "famille"`, `etablissementId: "ime_robert_seguy"`, `usagersIds: ["usager_001"]`), connexion testée, routage vers `FeedFamilleScreen` confirmé fonctionnel.

**Inscription famille par code d'invitation (terminée)** : `AuthService.signUpFamille` orchestre la création de compte réelle, dans cet ordre précis — d'abord `createUserWithEmailAndPassword` (le compte Auth doit exister *avant* de lire un code, puisque la règle `codes_invitation` exige `request.auth != null`), puis lecture directe de `codes_invitation/{code}` par id (jamais de `list`), puis écriture `users/{uid}`. Si le code est invalide ou si l'écriture est refusée, le compte Auth fraîchement créé est supprimé (`user.delete()`) pour ne laisser aucun orphelin. `InscriptionScreen` appelle ce chemin réel (indicateur de chargement anti double-clic, messages d'erreur en français pour les cas Firebase Auth classiques — email déjà utilisé, mot de passe trop faible, email invalide — et pour un code d'invitation invalide) ; `ConsentImageScreen` navigue ensuite vers `FeedFamilleScreen` (et non plus `LoginScreen`) une fois les consentements validés, puisque la session Firebase Auth est déjà active. Validé de bout en bout sur Pixel 9a : inscription → code d'invitation → compte réel → consentement → feed famille → reconnexion.

**Règles Firestore `users`/`codes_invitation` déployées sur `relio-dev`** : la création d'un document `users/{uid}` est désormais autorisée par les règles, mais réservée aux comptes famille (`role == 'famille'`), limitée à un seul usager (`usagersIds.size() == 1`), avec vérification que l'usager revendiqué correspond à un code d'invitation réel du même établissement — deux `get()` sur `codes_invitation` dans la règle (existence du code, puis correspondance `usagerId` et `etablissementId`). Les comptes pro restent créés en console, pas de règle `create` pour ce cas. `update`/`delete` verrouillés sur `users/{uid}` (`if false`) — à rouvrir plus tard avec le pattern `diff().affectedKeys().hasOnly()` (déjà documenté dans `docs/brief-technique-consentement-image-invitations.md`) le jour où une famille doit pouvoir modifier ses propres préférences. Nouvelle règle `codes_invitation/{codeId}` : lecture (`get`) autorisée à tout utilisateur authentifié pour vérifier un code précis, `list` et `write` explicitement interdits (anti-énumération) — les codes restent créés à la main en console au MVP. Modèle `FamilleUser` complété avec `codeInvitationUtilise` (String), lu en tolérant son absence (fallback `''`) pour ne pas casser les comptes famille créés manuellement avant l'ajout de ce champ.

**Propagation du compte pro dans l'app (terminée)** : `AuthService.currentProUser` (champ statique, nullable) est la source de vérité pour l'identité du pro connecté dans tout l'app — plus aucun écran ne lit `mockProConnecteUid`/`mockProConnecteNom`/`mockProConnectePeutDiffuserEtablissement` pour déterminer *qui* est connecté. `AuthService.signIn` assigne directement `AuthService.currentProUser` (ou `currentFamilleUser`) en interne selon le rôle détecté, avant que `LoginScreen` ne route vers l'écran d'accueil correspondant. Dix points migrés : `notifications_pro_screen.dart`, `documents_pro_screen.dart`, `messages_pro_screen.dart`, `feed_pro_screen.dart` (badge de notifications), `envoyer_message_screen.dart` et `envoyer_document_screen.dart` (expéditeur), `visibilite_selector.dart` (chip « Établissement »), `profil_screen.dart` (nom affiché), `selection_usager_journal_screen.dart` (filtrage par `unitesAcces`), plus le socle `AuthService`/`LoginScreen` lui-même. Chaque écran protège le cas `currentProUser == null` (liste ou badge vide plutôt qu'un crash). `FeedProScreen` est passé en `StatefulWidget` : le badge de notifications se rafraîchit désormais immédiatement au retour de `NotificationsProScreen` (`await Navigator.push` puis `setState`), plutôt qu'au hasard d'une reconstruction.

**Phases suivantes — ordre de câblage acté : publications → messages → documents → agenda** (notifications câblées au fil de l'eau par fonctionnalité plutôt qu'en bloc final, pas une phase à part). Raisonnement :
- **Publications d'abord**, pas par priorité fonctionnelle mais parce que c'est ce chantier qui pose les patterns réutilisés ensuite par tout le reste : règles Firestore scopées par `unitesAcces`, upload photos vers Storage, pagination du feed, soft delete (`masquee`/`dateMasquage`). Le Journal de vie en découle directement, puisqu'il est alimenté par les publications.
- **Messagerie immédiatement après** : c'est le cœur réel du cahier de liaison papier que Relio remplace — l'échange bilatéral quotidien entre pro et famille. Ni l'agenda ni les documents ne remplacent le carnet ; la messagerie, si.
- **Décision produit actée** : le périmètre du test de validation interne à l'unité de Séb est publications + messagerie, pas publications seule — présenter l'app sans messagerie reviendrait à demander un retour terrain sur un produit qui ne remplace pas encore le carnet.
- **Documents** (autorisations à signer, etc.) **puis agenda** ensuite, dans cet ordre.

**Décisions de modélisation actées, à ne pas perdre :**
- `users/{uid}` unique avec champ `role` — jamais de split familles/pros en collections séparées (déjà le cas ci-dessus, confirmé).
- Dénormalisation : `uniteId` et `etablissementId` présents sur tout document de contenu (publications, agenda, documents, messages), quel que soit le type de portée — même si dérivable via l'unité.
- Publications : jamais de suppression physique — un retrait se fait via `masquee` (bool) + `dateMasquage`, jamais un `delete()`. Édition réservée à l'auteur ; les champs auteur, date, `typePublication` et usagers concernés restent non modifiables après création.
- Codes d'invitation réutilisables : deux parents séparés d'un même usager utilisent le **même** code pour créer chacun leur propre compte famille — pas un système à usage unique. Le champ `utilise` prévu dans le schéma `codes_invitation` (voir « Architecture des données » plus haut) devra être réconcilié avec cette décision quand la collection sera réellement implémentée (ne pas l'interpréter comme "un seul compte par code").
- `usagersIds` (et non `usagerId` singulier) sur `FamilleUser` dès le MVP, même si un seul élément aujourd'hui pour chaque compte — prépare le cas de la fratrie (plusieurs usagers rattachés à une même famille) sans migration de schéma plus tard.
- La validation du code d'invitation à la création d'un compte famille se fait **côté règles Firestore** (server-side, non contournable par le client), pas seulement côté formulaire — voir la règle `create` sur `users/{userId}` ci-dessus. Même si `inscription_screen.dart` reste mocké aujourd'hui, la garantie de sécurité existe déjà au niveau base de données.

**Sujets ouverts, non bloquants, à ne pas perdre de vue :**
- Droit à l'effacement RGPD (suppression/anonymisation d'un usager sortant, droit de rectification famille) — pas encore conçu, à traiter avant toute présentation à la direction, pas bloquant pour le MVP interne.
- Coût réel des `get()` dans les security rules sur les requêtes de liste (feed) — à mesurer concrètement une fois `relio-dev` connecté, pas en théorie.
- Expiration des codes d'invitation — le champ `dateExpiration` existe déjà dans le modèle mais n'est exploité par aucune règle.
- Les consentements image (`ConsentImageScreen`) sont encore écrits dans `mockUsagersCatalogue`, pas dans Firestore — aucune persistance réelle pour l'instant. Point RGPD à traiter dans une session dédiée, puisque ça touche la collection `usagers` qui n'est pas encore câblée.
- `utilise` et `dateUtilisation` (schéma `codes_invitation`) ne sont jamais mis à jour après la lecture d'un code — écriture interdite côté client par la règle `write: if false`. Aucune traçabilité d'usage des codes (combien de fois, par qui, quand) tant qu'il n'y a pas de Cloud Function pour le faire côté serveur.
- **Amélioration future — Cloud Function de validation serveur du code d'invitation** : la règle `create` sur `users/{userId}` fait deux `get()` sur `codes_invitation` directement dans les security rules, ce qui fonctionne pour un établissement pilote mais mérite d'être révisé (coût, complexité, logique métier plus riche) avant l'ouverture de Relio à un deuxième établissement — probablement en déplaçant cette validation vers une Cloud Function dédiée plutôt que de l'alourdir davantage dans les règles.
- **Point de vigilance — typage de `AuthService.signIn`** : la méthode retourne `Object` (soit un `ProUser`, soit un `FamilleUser`), départagé par un `is ProUser` côté appelant (`LoginScreen`). Ça reste lisible pour deux rôles, mais à retyper plus explicitement (union type/sealed class, ou un enum de rôle assorti d'un record) le jour où le rôle `admin_etablissement` rejoindra `AuthService.signIn` — un enchaînement de `is`/`else` ne passera pas bien à trois rôles ou plus.
- **Dette technique — pont temporaire dans `mock_data.dart`** : `mockProConnecteUid` a été changé de `'pro_martin'` vers l'uid Firebase réel du compte pro de test de Séb (`greI7Ibic4eZCRNnfFnMCv1pTxw1`), marqué `// TEMPORAIRE` dans le code, avec une entrée correspondante ajoutée dans `mockProsCatalogue` pour que `findProById` ne plante pas. Nécessaire car les données mock de notifications/documents/messages référencent encore `destinataireId`/`envoyePar`/`expediteurId` via ce même mock — sans ce pont, elles n'apparaîtraient jamais pour le compte pro réellement connecté. À retirer une fois ces collections câblées sur Firestore (chantier futur, pas encore planifié) ; d'ici là, `mock_data.dart` contient littéralement l'uid Firebase d'une vraie personne.

## Logique métier : les 3 types de publication

1. **Individuelle** — concerne 1 usager. Visible par : la famille concernée + les professionnels autorisés (unités d'accès). Ajoutée automatiquement au journal de vie de l'usager.
2. **Groupe** — concerne une unité, avec sélection des usagers présents (tous pré-cochés, le pro décoche les absents). Visible par : les familles des usagers concernés + les professionnels concernés. Ajoutée au journal de vie de chaque usager concerné.
3. **Établissement** — pas de sélection d'usagers. Visible par tous (familles + professionnels). Valorise la vie institutionnelle.

Chaque publication : texte (max 1000 caractères), 1 à 5 photos, auteur, date, likes, commentaires, notifications.

## Consentement image (usagers)

Les familles autorisent ou refusent la diffusion de la photo de leur enfant, **par type de publication** (individuelle / groupe / établissement), sans que ce choix ne conditionne jamais l'accès au service (RGPD art. 7§4 — non-conditionnement).

**Règle centrale :** un refus n'empêche jamais un pro de publier une photo. Il affiche seulement un badge d'alerte informatif (« Pas d'autorisation image ») sur les écrans de sélection d'usager pour une publication individuelle ou de groupe (`SelectionUsagerJournalPage`, `CreatePublicationPage`) — pas de sélection d'usager en établissement, donc pas de badge applicable. Aucun blocage technique, sur aucun des trois types.

**Schéma `usagers/{usagerId}.consentImage`** : `individuelle` / `groupe` / `etablissement` (bool, faux par défaut) + `dateConsentement`, `versionTexte`, `saisiPar` (uid famille, ou uid admin/coordinateur en fallback pour un parent sans smartphone). Modifiable uniquement par la famille liée à l'usager ou un admin/coordinateur — règle de sécurité Firestore dédiée (même pattern que les publications).

**Recueil :** écran dédié juste après la création de compte famille par code d'invitation, avant l'accès au reste de l'app (3 toggles décochés par défaut, ton chaleureux, prénom dynamique, rassurance explicite que le refus n'empêche pas d'utiliser Relio — texte complet dans `docs/brief-technique-consentement-image-invitations.md`). Modifiable ensuite dans Profil > Paramètres > Confidentialité/RGPD (mêmes toggles, pré-remplis).

**Hors périmètre MVP :** masquage rétroactif automatisé en cas de révocation, gestion de version du texte de consentement et re-consentement, écran de génération de codes d'invitation, expiration des codes, détection/floutage automatique de visages non consentants (Relio IA).

## Écrans (référence : maquettes FlutterFlow — Séb fournira des captures)

### Périmètre SESSION 1 — test de validation (ne pas déborder)
1. **Écran de connexion (Login)** : logo Relio, champs email + mot de passe, bouton connexion rose-violet, lien « Mot de passe oublié », éléments décoratifs vagues/cercles, fond dans l'esprit turquoise
2. **FeedFamillePage** : header avec logo à gauche + cloche de notifications à droite (pas de titre de page) ; liste de PublicationCard ; footer 4 icônes (Accueil / Journal de vie / Agenda / Profil — footer d'origine, remplacé depuis par Cahier de liaison, voir section « Cahier de liaison » plus bas)
3. **Composant PublicationCard** : avatar + horodatage, image bord-à-bord hauteur 200 px, rangée like/commentaire avec compteurs, texte, 2 premiers commentaires affichés, bottom sheet pour tous les commentaires (fermeture par swipe vers le bas). Pas de badge de contexte sur les publications.

Pour la session 1 : données factices (mock) acceptables, la connexion Firestore réelle viendra ensuite. Objectif : valider la fidélité visuelle et le workflow avant de migrer le reste.

### Écrans suivants (sessions ultérieures, déjà spécifiés côté design)
- Splash, Welcome, Inscription (avec champ code d'invitation ; pour un compte famille, suivie de l'écran de recueil du consentement image avant l'accès à l'app), Mot de passe oublié
- FeedProPage (identique au feed famille + bouton de création de publication)
- CreatePublicationPage : écran unique avec ChoiceChips Individuelle / Groupe / Établissement (turquoise plein = sélectionné, blanc bordure turquoise = non sélectionné), blocs conditionnels selon le type, sélection photos max 5 (miniatures 80×80, case « + Ajouter » à bordure turquoise pointillée), compteur 0/1000, bouton « Publier » pleine largeur rose-violet, badge d'alerte sur les usagers sans consentement image pour le type sélectionné (individuelle/groupe)
- JournalDeViePage : header turquoise avec nom de l'usager en sous-titre, filtres de période ChoiceChips (Tout / Ce mois / Cette semaine), liste de PublicationCard, état vide chaleureux et illustré
- SelectionUsagerJournalPage (pros uniquement) : liste d'usagers filtrée par unitesAcces, item = avatar 40 px + nom + badge si consentement image refusé, ligne entière tappable
- Navigation Journal de vie : famille = accès direct depuis le footer (un seul usager associé) ; pro = via la page de sélection OU en tapant le nom/avatar d'un usager sur une PublicationCard
- Profil (version famille) : Infos personnelles, Documents, Paramètres (mot de passe, notifications, confidentialité/RGPD [inclut la modification du consentement image par type de publication], aide), Déconnexion

### Cahier de liaison (construit)

- Remplace le bouton Agenda du footer. Nouveau footer : Accueil / Journal de vie / **Cahier de liaison** / Profil.
- **CahierDeLiaisonPage** : nouvelle page d'accueil par usager. Header façon JournalDeViePage (bandeau turquoise, nom de l'usager en sous-titre). Flèche retour visible côté pro uniquement (arrive depuis SelectionUsagerJournalPage, filtré par `unitesAcces`) ; absente côté famille (accès direct depuis le footer, un seul usager associé).
- 3 tuiles à aperçu enrichi, ordre fixe : Messagerie, Agenda, Documents. Chaque tuile : icône + libellé + ligne d'aperçu + badge compteur rouge (réutilise le composant badge déjà utilisé sur la cloche de notifications et les alertes RGPD) + chevron. Toute la carte est tappable, mène vers la sous-page correspondante.
- Si aucune donnée récente sur une rubrique : pas de badge, texte d'aperçu neutre (ex. « Aucun message récent ») plutôt qu'une ligne vide.
- Compteurs et aperçus actuellement calculés sur données mock — câblage Firestore réel prévu en phase de migration backend (amélioration future, pas MVP).

### NouvelleCommunicationPage — mise à jour (construit)

- 3e carte ajoutée : « Créer un événement », route vers la logique de création d'événement agenda existante.
- Les 3 flux (Document / Message rapide / Événement) réutilisent tous le même bloc de sélection destinataire individuel/unité/établissement, structure héritée de CreatePublicationPage.

### Permission diffusion établissement (Item 3 construit — mock uniquement)

- Catalogue mock des pros créé (`MockPro`/`mockProsCatalogue` dans `mock_data.dart`) : champ `peutDiffuserEtablissement` (bool, `false` par défaut). Deux comptes coordination/direction l'ont à `true`. Positionné manuellement pour le MVP (pas d'interface de gestion avant Relio Admin, Phase 2) — restera vrai également une fois Firestore branché.
- Chip « Établissement » grisé (désactivé au tap) dans EnvoyerDocumentPage et l'écran message quand le pro connecté a `peutDiffuserEtablissement` à `false`, via le nouveau paramètre `restrictionEtablissementActive` de `VisibiliteSelector` (`false`/absent pour l'agenda et le fil d'actu, comportement inchangé là-bas). Pas de texte d'explication sous le chip — testé puis retiré à la demande de Séb, le grisé seul suffit.
- Publication établissement (fil d'actu) reste ouverte à tous les pros, sans restriction — décision volontaire (contenu de valorisation institutionnelle, moins sensible qu'une information factuelle type document/message), à réévaluer seulement si abus constaté en usage réel.
- **Reste à faire (Item 4, repositionné après la Phase 1 du chantier Back)** : champ réel `peutDiffuserEtablissement` sur `users/{uid}` en base Firestore + la security rule associée (voir Architecture des données, Chantier Back et Contraintes et vigilance) — invérifiable avant que la collection `users/{uid}` réelle existe (Phase 1), donc à ne pas écrire avant.

## Contraintes et vigilance

- **RGPD et données sensibles** : les données concernent des enfants et adultes en situation de handicap. Aucune donnée réelle pendant le développement. Prévoir dès le départ des règles de sécurité Firestore strictes (jamais de règles ouvertes, même « temporairement »). Le consentement à l'image est géré par type de publication et ne conditionne jamais l'accès au service (RGPD art. 7§4) — voir « Consentement image ». `firestore.rules` existe et est déployé sur `relio-dev` (collections `users` et `codes_invitation` couvertes, voir « Chantier Back ») ; la règle ci-dessous reste à ajouter.
- **Règle à ajouter (non commencée, dépend du champ `peutDiffuserEtablissement`)** : sur les collections `documents` et `messages`, refuser toute écriture avec `portee: "etablissement"` si `peutDiffuserEtablissement` n'est pas `true` sur le profil de l'auteur. Réutiliser le pattern `diff().affectedKeys().hasOnly()` déjà documenté dans `docs/brief-technique-consentement-image-invitations.md` pour la règle de consentement image, à adapter ici. Invérifiable avant la Phase 1 du chantier Back (pas de collection `users/{uid}` réelle avant ça) — ne pas l'écrire avant.
- **Accessibilité** : valeur fondamentale du projet (public TSA notamment). Tailles de texte respectueuses des réglages système, contrastes suffisants, zones tappables généreuses (min 48 px).
- Ne jamais affirmer de garanties de sécurité invérifiables ; vocabulaire conforme RGPD.
- Interface intégralement en français.

## Méthode de travail avec Séb

- Une fonctionnalité à la fois, validation par capture d'écran avant de continuer
- Expliquer ce que tu fais en langage clair (pas de jargon non expliqué)
- Classer toute recommandation : **MVP indispensable / Amélioration future / Vision long terme**
- Challenger les idées risquées, en cofondateur direct mais bienveillant
- Commandes utiles à rappeler à Séb : `flutter run` (choisir le Pixel 9a ou Chrome), `r` pour hot reload, `R` pour hot restart, `q` pour quitter
