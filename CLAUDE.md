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

## Design system

### Chrome des écrans secondaires

Toute page secondaire (hors feeds) utilise `SimpleTurquoiseHeader` — jamais un en-tête
recopié à la main. Structure de référence : `Scaffold(backgroundColor: AppColors.turquoise)`
→ `SafeArea` → `Column[SimpleTurquoiseHeader, Expanded(AuthBackground(…))]`. Le fond turquoise
du `Scaffold` n'est pas décoratif : sans lui, le bandeau ne rejoint pas le haut de l'écran sous
la `SafeArea` et laisse une bande blanche. Marges horizontales du formulaire : **16 px**.
Bouton d'action : **rose-violet**, pleine largeur (le turquoise est la couleur principale, pas
celle des actions).

Appliqué aux 4 écrans de création/envoi (publication, événement, document, message) —
uniformisation faite le 2026-07-31, les écrans d'envoi étaient la référence.

### RelioFooter — deux règles distinctes, à ne pas fusionner

1. **Le `RelioFooter` est obligatoire sur les écrans d'entrée** : Splash, Welcome, Login,
   Inscription (avec code), Mot de passe oublié. Raison : première impression de marque, avant
   tout contenu lié à un enfant.
2. **Le `RelioFooter` marque les écrans de création ou de consultation de contenu vécu autour
   d'un enfant** : Publication, Événement, Cahier de liaison, et plus tard Messages/Documents/
   Agenda. Il n'apparaît pas sur les écrans utilitaires (formulaires système, sélection,
   paramètres, authentification hors écrans d'entrée listés en 1).

   **Les 4 écrans de création le portent tous** (2026-07-31) : Nouvelle publication, Nouvel
   événement, Envoyer un document, Envoyer un message. Les deux derniers l'ont reçu à la
   validation — un écran de création qui l'a et son voisin qui ne l'a pas, c'est l'incohérence
   que ce chantier corrige.

**Contrainte de placement :** toujours sur fond clair (`AuthBackground` ou équivalent), jamais
directement sur le turquoise du `Scaffold` ni sur le `FeedBottomNav` — son marine à 45 %
d'opacité y serait illisible. Sur un écran portant une barre de navigation, il se place *dans*
l'`AuthBackground`, au-dessus de la barre.

**Sur l'horizon :** la question ouverte porte sur les écrans de **consultation**, pas de
création (ceux-là sont tranchés ci-dessus). Au chantier Messagerie, vérifier si les listes et
détails Messages / Documents / Agenda — `messagerie_famille`, `messages_pro`,
`documents_famille`, `documents_pro`, `agenda_famille`, `agenda_pro`, `message_detail`,
`document_detail` — doivent recevoir le `RelioFooter` au titre de la règle 2. Aucun ne l'a
aujourd'hui. `journal_de_vie` relève de la même question. Non tranché.

## Architecture des données (Firestore — 11 collections)

`etablissements`, `unites`, `usagers`, `users`, `publications`, `commentaires`, `agenda`, `documents`, `notifications`, `messages`, `codes_invitation`

**Principes :**
- Multi-tenant : hiérarchie établissement → unité → usager
- Convention de nommage des champs Firestore : camelCase (ex. `unitesAcces`, `dateCreation`, `consentImage`)
- **Vocabulaire affiché ≠ noms de champs.** Le type de portée intermédiaire s'appelle `groupe` en base (`VisibiliteType.groupe`, `consentImage.groupe`, `portee: "groupe"`) mais **s'affiche toujours « Unité »** dans l'interface — chips de sélection, tuiles d'agenda, en-têtes de message, badges de consentement, FAQ, et jusqu'aux titres des écrans de recueil du consentement. Un pro ne pense pas « groupe », il pense « l'unité Polyvalence ». Ne jamais laisser un nom de champ remonter jusqu'à l'écran, et ne pas renommer le champ pour autant : le schéma est stable, c'est la couche d'affichage qui traduit.
- Les professionnels ont une liste `unitesAcces` (unités auxquelles ils ont accès) ; toute liste d'usagers affichée à un pro est filtrée par ses `unitesAcces`
- Les professionnels ont aussi un champ booléen `peutDiffuserEtablissement` (faux par défaut) qui autorise ou non la diffusion en portée « établissement » sur **trois** surfaces : documents, messages, et — **depuis le 2026-08-16** — les publications du fil d'actu. Distinct du consentement image. Positionné manuellement en base pour le MVP, pas d'interface de gestion. Voir section « Permission diffusion établissement » plus bas, sous-section « portée étendue » : la décision d'origine, qui laissait le fil d'actu ouvert à tous les pros, a été **inversée**.
- Second booléen de permission sur `users/{uid}` : `peutModerer` (faux par défaut), qui autorise le masquage d'une publication ou d'un commentaire **dont on n'est pas l'auteur**. Motif : aujourd'hui seul l'auteur peut masquer sa publication — si l'auteur est absent, parti de l'établissement, ou s'il est lui-même le problème, il n'existe aucun recours pour retirer une photo publiée par erreur. Inacceptable sur une plateforme diffusant des images d'enfants en situation de handicap, et bloquant pour l'autorisation du pilote. **Volontairement un booléen, pas un troisième rôle** : un rôle `admin` obligerait chaque règle, chaque requête et chaque écran à gérer un cas de plus, là où un booléen ajoute une clause `OR`. Aucun nouveau chemin de lecture n'est nécessaire (le compte de Séb couvre déjà les 3 unités via `unitesAcces`) : `peutModerer` n'affecte que les règles d'écriture et l'affichage du menu « ⋮ ». `peutModerer` et `peutDiffuserEtablissement` sont **indépendants** — ne jamais les coupler, ni dans le seed, ni dans les règles. À positionner sur au moins deux comptes dès qu'un second compte de coordination existera (un unique modérateur en congé laisse l'établissement sans recours). La mécanique de modération elle-même appartient au chantier Publications (commentaires étape 4, publications étape 6) ; tout masquage reste un soft delete tracé (`masqueePar`, `motifMasquage`), y compris par un modérateur, et l'auteur doit voir que sa publication a été masquée et par qui.
- Création de compte par code d'invitation (collection `codes_invitation` : `role`, `usagerId` ou `unitesAcces` selon le rôle, `etablissementId`, `utilise`, `dateCreation`, `dateExpiration` [toujours `null` au MVP, pas de vérification d'expiration], `creePar`). Rôle famille ou pro rattaché à la collection unique `users` (pas de collections séparées par rôle). Codes créés à la main dans la console Firestore au MVP, un code par usager/famille, distribué manuellement par Séb — pas d'écran de génération (reporté à Relio Admin, Phase 2). Le script de seed Node.js (`tools/seed/`) existe réellement depuis R1 mais couvre **uniquement le référentiel** (`etablissements`/`unites`/`usagers`), pas les codes d'invitation
- Chaque usager porte un champ `consentImage` (booléens `individuelle`/`groupe`/`etablissement`, faux par défaut, jamais présumé) qui autorise ou non l'apparition visible de sa photo par type de publication — voir « Consentement image » ci-dessous
- Routage post-connexion selon le rôle : familles / professionnels / admin
- Séb a un accès de niveau coordinateur couvrant plusieurs unités

**Rôles :** famille (liée à un ou plusieurs usagers), professionnel (accès par unités), admin établissement.

**Décisions verrouillées :**
- **Préfixage des ids du référentiel.** Tout id référentiel doit rester préfixé par son type (`usager_`, `unite_`, `etab_`) et rester globalement unique tous types confondus. C'est cette propriété qui rend sûre la fusion `unitesAcces` + `usagersIds` + `etablissementId` dans la règle de lecture `publications` — un id non préfixé introduit un risque de collision inter-collections.

## Chantier Back (Firebase) — trajectoire actée

**Deux projets Firebase distincts** : `relio-dev` (développement) et `relio-618ca` (le futur projet de production, déjà créé avant le début du chantier Flutter, sous le nom d'affichage « Relio »). Développement en direct contre `relio-dev` — **pas d'émulateur Firebase local** : décision actée (revient sur une version antérieure de ce plan qui prévoyait un émulateur), plus de justification pour un projet solo sans données réelles à protéger à ce stade. Les données restent toujours fictives même une fois `relio-dev` connecté — voir « RGPD et données sensibles » plus bas.

Les deux projets sont en plan Blaze : Firestore seul reste dans le tier gratuit (Spark), mais Cloud Storage impose Blaze pour tout projet depuis fin 2024 (règle Google, pas un choix produit) — `relio-dev` a donc été passé en Blaze pour pouvoir activer Storage. Le palier gratuit inclus dans Blaze reste largement suffisant pour un usage de développement solo avec données fictives (facture réelle attendue : 0€).

**Phase 0 (terminée)** : Node.js + Firebase CLI + FlutterFire CLI installés, projet `relio-dev` créé (Authentication email/mot de passe, Firestore région eur3, Storage région eur4, tous activés), connecté au projet Flutter via `flutterfire configure` (`lib/firebase_options.dart` généré, apps Android + Web enregistrées — pas d'app iOS, pas de dossier `ios/` pour l'instant). `firebase_core` ajouté aux dépendances et `Firebase.initializeApp()` câblé dans `main.dart`, `flutter analyze` et `flutter build web` passent sans erreur.

**Phase 1 (terminée, pro et famille)** : premier compte pro réel créé manuellement sur `relio-dev` (Authentication + document `users/{uid}`, champ `role: "pro"`). C'est à cette phase que `peutDiffuserEtablissement` (bool, `false` par défaut) est devenu un vrai champ Firestore sur les comptes pro — jusqu'ici mock uniquement, voir « Permission diffusion établissement » plus bas (Item 4 du chantier Cahier de liaison). Modèle Dart `ProUser` (`lib/models/pro_user.dart`) créé. Première règle `firestore.rules` déployée : lecture de son propre document `users/{uid}` uniquement, tout le reste refusé par défaut. Testé de bout en bout sur Pixel 9a physique.

**Authentification générique pro/famille (terminée)** : modèle Dart `FamilleUser` (`lib/models/famille_user.dart`) créé, même structure que `ProUser` (`uid`, `nom`, `prenom`, `email`, `etablissementId`, `dateCreation`), avec `usagersIds` (`List<String>`, tableau même à un seul élément au MVP — pense fratrie dès le départ) au lieu de `unitesAcces`/`peutDiffuserEtablissement`. `AuthService.signIn` (`lib/services/auth_service.dart`) remplace l'ancienne `signInPro` (supprimée) : authentifie via Firebase Auth, lit `users/{uid}`, détermine le rôle et retourne un `ProUser` ou un `FamilleUser` selon la valeur de `role` (`StateError` explicite si le document n'existe pas ou si `role` est absent/inconnu), en alimentant respectivement `AuthService.currentProUser` ou `AuthService.currentFamilleUser`. `LoginScreen` reste un formulaire unique (pas d'écrans de connexion séparés) et route vers `FeedProScreen` ou `FeedFamilleScreen` selon le type retourné.

Bascule pro/famille validée de bout en bout sur Pixel 9a physique : un compte famille de test existe sur `relio-dev` (`role: "famille"`, `etablissementId: "ime_robert_seguy"` — **valeur à corriger en `etab_001`**, voir R1 plus bas, `usagersIds: ["usager_001"]`), connexion testée, routage vers `FeedFamilleScreen` confirmé fonctionnel.

**Inscription famille par code d'invitation (terminée)** : `AuthService.signUpFamille` orchestre la création de compte réelle, dans cet ordre précis — d'abord `createUserWithEmailAndPassword` (le compte Auth doit exister *avant* de lire un code, puisque la règle `codes_invitation` exige `request.auth != null`), puis lecture directe de `codes_invitation/{code}` par id (jamais de `list`), puis écriture `users/{uid}`. Si le code est invalide ou si l'écriture est refusée, le compte Auth fraîchement créé est supprimé (`user.delete()`) pour ne laisser aucun orphelin. `InscriptionScreen` appelle ce chemin réel (indicateur de chargement anti double-clic, messages d'erreur en français pour les cas Firebase Auth classiques — email déjà utilisé, mot de passe trop faible, email invalide — et pour un code d'invitation invalide) ; `ConsentImageScreen` navigue ensuite vers `FeedFamilleScreen` (et non plus `LoginScreen`) une fois les consentements validés, puisque la session Firebase Auth est déjà active. Validé de bout en bout sur Pixel 9a : inscription → code d'invitation → compte réel → consentement → feed famille → reconnexion.

**Règles Firestore `users`/`codes_invitation` déployées sur `relio-dev`** : la création d'un document `users/{uid}` est désormais autorisée par les règles, mais réservée aux comptes famille (`role == 'famille'`), limitée à un seul usager (`usagersIds.size() == 1`), avec vérification que l'usager revendiqué correspond à un code d'invitation réel du même établissement — deux `get()` sur `codes_invitation` dans la règle (existence du code, puis correspondance `usagerId` et `etablissementId`). Les comptes pro restent créés en console, pas de règle `create` pour ce cas. `update`/`delete` verrouillés sur `users/{uid}` (`if false`) — à rouvrir plus tard avec le pattern `diff().affectedKeys().hasOnly()` (déjà documenté dans `docs/briefs/brief-technique-consentement-image-invitations.md`) le jour où une famille doit pouvoir modifier ses propres préférences. Nouvelle règle `codes_invitation/{codeId}` : lecture (`get`) autorisée à tout utilisateur authentifié pour vérifier un code précis, `list` et `write` explicitement interdits (anti-énumération) — les codes restent créés à la main en console au MVP. Modèle `FamilleUser` complété avec `codeInvitationUtilise` (String), lu en tolérant son absence (fallback `''`) pour ne pas casser les comptes famille créés manuellement avant l'ajout de ce champ.

**Propagation du compte pro dans l'app (terminée)** : `AuthService.currentProUser` (champ statique, nullable) est la source de vérité pour l'identité du pro connecté dans tout l'app — plus aucun écran ne lit `mockProConnecteUid`/`mockProConnecteNom`/`mockProConnectePeutDiffuserEtablissement` pour déterminer *qui* est connecté. `AuthService.signIn` assigne directement `AuthService.currentProUser` (ou `currentFamilleUser`) en interne selon le rôle détecté, avant que `LoginScreen` ne route vers l'écran d'accueil correspondant. Dix points migrés : `notifications_pro_screen.dart`, `documents_pro_screen.dart`, `messages_pro_screen.dart`, `feed_pro_screen.dart` (badge de notifications), `envoyer_message_screen.dart` et `envoyer_document_screen.dart` (expéditeur), `visibilite_selector.dart` (chip « Établissement »), `profil_screen.dart` (nom affiché), `selection_usager_journal_screen.dart` (filtrage par `unitesAcces`), plus le socle `AuthService`/`LoginScreen` lui-même. Chaque écran protège le cas `currentProUser == null` (liste ou badge vide plutôt qu'un crash). `FeedProScreen` est passé en `StatefulWidget` : le badge de notifications se rafraîchit désormais immédiatement au retour de `NotificationsProScreen` (`await Navigator.push` puis `setState`), plutôt qu'au hasard d'une reconstruction.

**Chantier Référentiel — R1 terminée (2026-07-30)** : les collections `etablissements`, `unites` et `usagers` existent réellement sur `relio-dev`. C'est un **prérequis bloquant du chantier Publications**, découvert au moment de le démarrer : sans elles, aucune règle de sécurité ne peut vérifier qu'un pro a le droit de publier sur un usager (nécessite `usager.uniteId`) ni qu'une famille doit recevoir une publication (nécessite l'unité de son usager) — la règle serait obligée de faire confiance au client. Brief complet : `docs/briefs/brief-R1-referentiel-firestore.md`.

Ce qui a été fait en R1 :
- **Script de seed réel** : `tools/seed/seed-referentiel.js` (Node.js + `firebase-admin`), données dans `tools/seed/data/referentiel.json`, mode d'emploi dans `tools/seed/README.md`, lancé par `npm run seed` depuis la racine. Le script ne contient **aucune donnée en dur** (valeurs par défaut et répartition attendue comprises). Idempotent (`set({merge: true})` sur un id explicite, jamais `add()`), ne supprime jamais rien (les documents en base absents du JSON sont signalés comme orphelins, pas effacés), et **préserve `dateCreation`** lors d'un rejeu. Ce n'est pas un script à usage unique : c'est l'outil de synchronisation du référentiel jusqu'à Relio Admin, l'effectif de l'IME étant rééquilibré à chaque rentrée.
- **Garde-fou anti-production non contournable** : le script lit le `project_id` dans la clé de compte de service et abandonne avant toute connexion s'il ne vaut pas exactement `relio-dev`. Aucun flag ni variable d'environnement ne permet de le contourner — cibler un autre projet exige de modifier le script sciemment. Testé (échec confirmé sur une clé `relio-618ca`).
- **Clé de compte de service hors du dépôt** : résolue par le script lui-même (`GOOGLE_APPLICATION_CREDENTIALS` sinon `~/.relio/relio-dev-sa.json`), jamais codée en dur, jamais lue depuis le dépôt. `.gitignore` couvre les noms usuels. Rappel : **la clé du SDK Admin contourne intégralement `firestore.rules`**, d'où le garde-fou.
- **Catalogue étendu de 35 à 55 usagers** (agrément de l'IME, pas l'effectif du jour : semer à pleine charge évite de découvrir un problème de liste longue le jour où l'établissement est complet), répartition **14 / 27 / 14** volontairement déséquilibrée pour reproduire la structure réelle. Ids `usager_001`–`usager_035` et leurs noms inchangés ; le cas de test d'homonymie `usager_017`/`usager_032` (« Emma Bernard », deux unités différentes) est préservé. Trois fratries préexistantes (Petit, Rousseau, Girard) couvrent le cas « nom partagé sur deux unités » qui validera la requête `array-contains-any` du feed famille.
- **`mockEtablissementId` renommé `ime_robert_seguy` → `etab_001`** : l'ancienne valeur était un nom d'affichage utilisé comme identifiant. Correction faite maintenant parce qu'elle ne coûtait que deux comptes de test ; elle en aurait coûté soixante plus tard. **Action manuelle restant à faire en console** (voir `tools/seed/README.md`) : reporter `etab_001` sur l'`etablissementId` des comptes de test pro et famille **et** de tous les documents `codes_invitation` — les trois ensemble, sinon la règle `create` sur `users/{userId}` (qui compare les deux) refusera toute nouvelle inscription famille.
- **Noms d'unités sans préfixe** : `Proximité` / `Polyvalence` / `Orientation` (et non plus « Unité Proximité »). `nom` est la seule source du libellé affiché ; aucun écran ne doit concaténer « Unité » devant, et aucune règle ni requête ne dépend du nom d'une unité — uniquement de son id.
- **Champs volontairement absents du schéma `usagers`** : `modaliteAccueil`, `hebergement`, `presenceJournee`, `nuitsInternat`. Décision actée — la présence d'un usager sur une activité est choisie par le pro au moment de publier, pas dérivée d'un champ de profil. À réintroduire au chantier Cahier de liaison **seulement s'ils s'avèrent nécessaires** ; ne pas les ajouter « au cas où ».
- **`consentImage` créé dès le seed** (les trois booléens à `false`, `dateConsentement`/`versionTexte`/`saisiPar` à `null`) pour éviter d'avoir à le rétro-remplir. `age` reste le champ du catalogue Dart (renommage hors périmètre) mais dérive désormais de `anneeNaissance`, la valeur de référence côté Firestore : `age = 2026 - anneeNaissance`. Amplitudes par unité : Proximité 5-12 ans, Polyvalence 12-16, Orientation 16-20 — les âges de `usager_011`–`usager_035` ont été réécrits en R1, ils valaient tous 6-11 ans, incohérent pour une unité d'orientation vers l'âge adulte.

**Chantier Référentiel — R2 terminée et validée sur Pixel 9a (2026-07-30)** : les trois collections sont désormais **lisibles depuis l'app**, de façon scopée. Les trois scénarios de validation sont passés — compte pro de Séb (3 unités, 14/27/14, total 55), **compte pro restreint à `unite_001` (1 unité, 14 usagers, pas 55)**, compte famille fratrie (exactement 2 usagers sur 2 unités), et test d'écriture refusé sur les trois. Le second est celui qui prouve que les règles *restreignent* au lieu de simplement autoriser : même code, même requête, périmètre différent uniquement par `unitesAcces`. Le troisième valide la branche `usagersIds` et le repli « même établissement » pour les unités. Brief : `docs/briefs/brief-R2-modeles-regles-referentiel.md`. **R2 ne débranche aucun écran** — `mockUsagersCatalogue` reste la source de tous les écrans existants jusqu'à R3.
- **Modèles Dart en lecture seule** : `Etablissement`, `Unite`, `Usager` (`lib/models/`), plus un `fromMap` ajouté à la classe `ConsentImage` existante (elle portait déjà exactement les 6 champs du schéma — pas de doublon créé). Aucun `toFirestore` : le référentiel ne s'écrit pas depuis le client. L'`id` vient **toujours** de `doc.id`, jamais d'un champ du document. Tous les `fromFirestore` sont **tolérants aux champs absents** (un document incomplet produit un objet valide, pas une exception) — faire planter l'app sur un référentiel incomplet serait un défaut de robustesse inacceptable. `Usager` n'a **pas** de champ `age` : l'âge se calcule à l'affichage depuis `anneeNaissance` (`ageApproximatif()`).
- **`ReferentielService`** (`lib/services/referentiel_service.dart`) : 6 méthodes de lecture, `Future` et jamais `Stream` (le référentiel ne bouge pas pendant une session, un flux temps réel coûterait des lectures pour rien — les flux seront pour `publications`). **Aucun cache** à cette étape : un cache masquerait les refus de règles pendant la validation. Tri et filtrage de `actif` faits **côté client** délibérément, pour ne pas imposer d'index composite à cette volumétrie. Les erreurs ne sont jamais avalées : `ReferentielService.estRefusDePermission(e)` permet de distinguer un refus de règle d'une panne réseau ou d'un bug.
- **Le contresens Firestore à ne jamais commettre** (commenté dans le service) : pour une requête de liste, les règles sont évaluées **document par document retourné**, elles ne filtrent pas. Une requête ramenant ne serait-ce qu'un document hors périmètre échoue **en entier**. Chaque méthode borne donc sa requête au périmètre de l'appelant — jamais requêter large en comptant sur les règles pour restreindre.
- **Règles déployées sur les trois collections**, `allow write: if false` partout (le référentiel se peuple par seed, plus tard par Relio Admin). Règles existantes sur `users`/`codes_invitation` inchangées. **Piège évité, vérifié sur la forme réelle des documents en base** : un compte famille n'a pas de champ `unitesAcces`, un compte pro n'a pas de `usagersIds` — or accéder à un champ absent produit une **erreur** d'évaluation (pas `null`), et le `||` court-circuite sur `true` mais pas sur une erreur à gauche. D'où `userDoc().get('champ', [])` partout, jamais `userDoc().champ`.
- **Écart assumé au brief sur la règle `unites`** : le brief proposait un accès par `unitesAcces` seul. Retenu à la place — un pro reste borné à ses `unitesAcces` (moindre privilège), et le repli « n'importe quelle unité du même établissement » est **réservé au rôle famille**, qui n'a pas de `unitesAcces` mais doit afficher le libellé de l'unité de son enfant. Un nom d'unité n'est pas une donnée sensible ; l'alternative (dériver l'unité depuis les usagers de la famille) imposerait un `get()` par usager dans la règle.
- **Écran de diagnostic TEMPORAIRE — SUPPRIMÉ en R3a**, avec sa tuile, comme prévu. Ce qui suit est l'historique de R2, conservé pour les leçons qu'il porte (le tri d'erreurs a été extrait avant suppression dans `lib/utils/chargement_referentiel.dart`, et sert désormais aux 10 écrans migrés). Il s'agissait de `lib/screens/diagnostic_referentiel_screen.dart`, accessible par une tuile « Diagnostic référentiel (temporaire) » dans Profil > Paramètres. C'était le livrable de validation de R2 : sans écran consommant le service, rien ne prouverait que les règles et le service fonctionnent. Il lit délibérément le document `users/{uid}` **brut**, sans passer par `ProUser`/`FamilleUser` : un modèle appliquerait ses valeurs par défaut et afficherait `peutModerer: false` alors que le champ est **absent** en base — un outil de diagnostic doit distinguer « absent » de « false ». Son test d'écriture vise `usagers/zzz_diagnostic_ecriture`, jamais un usager réel : si la règle était cassée, écrire sur `usager_001` corromprait une vraie donnée. **Piège rencontré et corrigé** : l'id était d'abord `__diagnostic_ecriture__`, or Firestore **réserve** le motif `__xxx__` et rejette l'écriture à la validation, *avant* d'évaluer les règles — le test échouait donc sans rien prouver. C'est la distinction « refus de règle » / « autre erreur » de l'écran qui l'a fait apparaître : regrouper toutes les erreurs sous « refusé » aurait produit un faux succès. **Le verdict affiche désormais le code Firestore brut** (`permission-denied`) et l'id visé, à côté du « Refusé (comportement attendu) » : un verdict qui ne montre pas sa cause se croit sur parole au lieu de se vérifier. Confirmé `permission-denied` sur les trois comptes de test. **Règle générale à garder : un test négatif doit distinguer « refusé pour la bonne raison » de « échoué », et afficher de quoi le prouver.**
- **Deux comptes de test à créer en console** (JSON exact dans `tools/seed/README.md`) : une famille « fratrie » (`usagersIds: ["usager_015","usager_033"]`, deux unités) et un **pro restreint à `unite_001`**. Le second est le seul qui permette un test négatif : le compte de Séb ayant les 3 unités, aucun usager n'est hors de son périmètre, donc rien ne prouverait que les règles restreignent. **Piège documenté** : `dateCreation` est obligatoire et de type `timestamp` — `ProUser`/`FamilleUser.fromFirestore` font un cast strict, un compte créé sans ce champ fait échouer la connexion avec une erreur peu parlante.
- **Vérification automatisée des règles : non disponible pour l'instant.** L'API `firebaserules.projects.test` (qui permettrait de tester les règles sans émulateur, y compris sur des comptes qui n'existent pas encore) refuse l'appel : le compte de service du SDK Admin n'a pas la permission IAM `firebaserules.rulesets.test`. Débloquable en lui accordant le rôle **Firebase Rules Admin** sur `relio-dev`. À faire avant le chantier Publications, où la règle d'ajout dans `consultations`/`confirmationsLecture` est déjà signalée comme la plus risquée de l'app — la valider à la main serait déraisonnable. En attendant, la validation des règles est manuelle, sur Pixel 9a, via l'écran de diagnostic.

**Protocole de mesure du coût des `get()` dans les règles (sujet ouvert depuis juillet, instruit en R2)** : chaque évaluation de règle appelle `get()` sur `users/{uid}`, facturé comme une lecture, et `userDoc()` est appelé jusqu'à 3 fois dans une même règle. En principe Firestore mutualise les `get()` identiques au sein d'une même évaluation — donc 1 lecture, pas 3, et une liste de 27 usagers coûterait 1 lecture supplémentaire et non 27. **À vérifier, pas à supposer.** Protocole : relever le compteur de lectures dans la console Firebase (onglet Utilisation), ouvrir un nombre connu de fois un écran qui liste les usagers avec le compte à 3 unités, relever à nouveau. **L'écran de diagnostic ayant été supprimé en R3a, utiliser `SelectionUsagerJournalScreen`** : une seule requête groupée par ouverture, sur les 55 usagers — même profil de mesure. **La console a plusieurs heures de latence sur ces compteurs : la mesure se lit le lendemain, pas dans la session** — ne pas bloquer R2 pour l'attendre. Relevé à faire à partir du 2026-07-31. Si le coût s'avère linéaire, la sortie propre est de placer `unitesAcces`/`usagersIds` dans des **custom claims** du token d'authentification, ce qui supprime le `get()` — coût : une Cloud Function à la création de compte et la gestion de la péremption des tokens. Amélioration future, déclenchée sur mesure réelle, jamais par anticipation.

**Chantier Référentiel — R3a terminée et validée sur Pixel 9a (2026-07-31)** : les six scénarios sont passés — périmètre complet (3 unités, 55 usagers), périmètre restreint (`pro.test`, 1 unité, 14 usagers), couleurs d'avatar inchangées sur les usagers témoins, **badges de consentement toujours différenciés** (le scénario qui détecte la régression silencieuse), état de chargement visible, et erreur réseau propre avec bouton « Réessayer ». Les écrans lisent le référentiel sur Firestore. `mockUsagersCatalogue` n'est plus la source d'aucune identité d'usager. Brief : `docs/briefs/brief-R3a-debranchement-lecture.md`. Périmètre confirmé en début de session : **12 fichiers dépendants**, dont 10 migrés — les 2 écrans de consentement (`consent_image_screen.dart`, `confidentialite_rgpd_screen.dart`) restent intouchés, voir R3b.

- **Point de composition unique : `UsagerAffichage`** (`lib/models/usager_affichage.dart`). Assemble les trois sources d'un usager affiché — identité Firestore, consentement image (mock), couleur d'avatar (dérivée). Les écrans ne voient jamais un `Usager` brut : `ReferentielService` expose quatre méthodes `…Affichage…` qui composent avant de retourner. **C'est le seul fichier à reprendre en R3b.**
- **Couleur d'avatar dérivée** : `avatarColorPourUsager(id)` (`lib/utils/avatar_color.dart`), somme des unités de code de l'id modulo la palette. **Volontairement pas un hachage multiplicatif** : `h*31+c` dépasse la plage des entiers exacts en JavaScript, où les `int` Dart sont des `double` — le même id donnerait une couleur sur Android et une autre sur le Web, qui est une cible du MVP. **L'ordre de la palette (`roseViolet`, `marine`, `turquoise`) n'est pas arbitraire** : il est calibré pour reproduire à l'identique les couleurs historiques de `usager_001` à `usager_035`. Mesuré : 35/55 inchangés ; les 20 qui changent sont `usager_036`–`055`, ajoutés en R1 et jamais validés visuellement. Aucune fonction pure de l'id ne peut reproduire les 55, les couleurs mock ayant été posées à la main par cycle interne à chaque unité.
- **Pattern de chargement asynchrone** : l'app ne contenait **aucun `FutureBuilder` ni `StreamBuilder`**. Le seul pattern existant était celui de l'écran de diagnostic R2 (`StatefulWidget` + `initState` → `_charger()` → champs `_chargement`/résultat → `setState`), confirmé par `_loading` dans `login_screen`/`inscription_screen`. Ce pattern a été **extrait avant de supprimer l'écran** : `ChargementReferentiel<T>` + `chargerReferentiel()` (`lib/utils/chargement_referentiel.dart`) classent l'échec en refus de règle / autre, et `lib/widgets/etat_referentiel.dart` porte les trois états visuels partagés (chargement, erreur, vide). `ChargementPerimetrePro` (`lib/widgets/chargement_perimetre_pro.dart`) mutualise le chargement « unités + usagers du pro » des 4 formulaires de création/envoi. **Ne pas introduire de `FutureBuilder` ailleurs sans reprendre l'ensemble.**
- **`VisibiliteSelector` porte désormais des objets, plus des libellés** : `List<UsagerAffichage>` / `List<Unite>` au lieu de `List<String>` de noms. `resolveUsagerId`/`familleUidPourUsager` supprimées avec — elles retournaient `null` sur un homonyme, rendant « Emma Bernard » (`usager_017`/`usager_032`) silencieusement non sélectionnable. **Corollaire important** : la liste « usagers présents » d'une publication de groupe est maintenant filtrée par l'unité choisie. L'ancien sélecteur affichait les mêmes 5 usagers quelle que soit l'unité — défaut que le catalogue factice masquait.
- **`selection_usager_journal_screen` passe de 5 usagers écrits en dur à tout le périmètre du pro** (14 ou 55). L'entrée de test « Léo Martin » (id `null`, qui ne menait nulle part) disparaît. `souvenirsCount` est retiré de cet écran **et de `JournalDeVieScreen`** : il affichait une valeur factice sans contrepartie en base. **À réintroduire à l'étape 5 du chantier Publications** (Journal de vie), calculé sur les vraies publications.
- **Supprimés** : `diagnostic_referentiel_screen.dart` + sa tuile, `mockUsagersAvecFamilles`, `mockUsagersAvecFamillesNomComplet`, `familleUidPourUsager`, `resolveUsagerId`, `resolveUniteId`, `mockUnitesCatalogue`, `MockUnite`, `mockUnites`, `mockUsagers`, `UsagerUnite`, `UniteAvecUsagers`, `mockUnitesAvecUsagers`.
- **Trois défauts trouvés pendant la validation, corrigés** : (1) **aucun retour visuel au tap** dans les listes — un `Container` décoré s'intercalait entre le `ListTile` et son `Material`, qui peignait donc ses ondes de contact derrière le fond. Antérieur à R3a, rendu bruyant par le passage de 5 à 27 lignes (assertion Flutter en debug, ~40 déclenchements). Corrigé aux 3 endroits portant ce motif ; **utiliser `Material` et non `Container` pour toute carte contenant des `ListTile`**. (2) **Firestore n'expire jamais de lui-même** : hors connexion, `get()` met la lecture en file d'attente et attend le réseau sans limite — l'indicateur de chargement tournait indéfiniment, sans erreur ni bouton. D'où `delaiMaxLecture` (10 s) dans `chargerReferentiel`. (3) La liste « usagers présents » d'une publication de groupe **ignorait l'unité choisie** et proposait les mêmes usagers quelle que soit l'unité — masqué par le catalogue factice.
- **Tri et vocabulaire des listes d'usagers** : le tri est par **nom de famille**, et les listes affichent donc « Nom Prénom » (`UsagerAffichage.nomListe`) pour que l'ordre se voie — afficher « Prénom Nom » sur une liste triée par nom la faisait paraître désordonnée. Les **titres de page** (Journal de vie, Cahier de liaison, Agenda) gardent « Prénom Nom » (`nomComplet`) : une page qui parle d'un enfant ne se lit pas comme une fiche administrative. La page de sélection d'usager est **groupée par unité**, comme Profil > Mes unités.
- **Toujours vrai après R3a** : les requêtes de liste restent bornées côté client au périmètre de l'appelant (une requête ramenant un seul document hors périmètre échoue **en entier**). Toutes les listes passent par les méthodes groupées du service — jamais un appel par usager dans une boucle.

**Ponts temporaires — il n'en reste qu'un :**
1. ~~Consentement image → `mockUsagersCatalogue`~~ — **LEVÉ en R3b (2026-08-16).** Le consentement se lit et s'écrit sur Firestore. `usagerSansAutorisationImage` et le champ `consentImage` de `MockUsager` ont été supprimés ; les 6 cas de test différenciés ont migré dans `referentiel.json`.
2. **Lien usager → comptes famille → `mockFamilles`, levée au chantier Messagerie.** La règle `users/{uid}` n'autorise chacun à lire que son propre document : aucune requête cliente ne peut retrouver les familles rattachées à un usager. Dans `envoyer_document_screen`/`envoyer_message_screen`, seul l'affichage du sélecteur est migré ; `_resolveDestinataires` reste sur le mock.

**R3b — ✅ CLOSE (2026-08-16).** Le consentement image s'écrit réellement sur Firestore. Détail complet en fin de section, sous « Chantier Référentiel — R3b ». Le chemin retenu est une **règle Firestore ciblée, pas une Cloud Function** : elle suffit à borner l'écriture au seul champ `consentImage`, pour la seule famille rattachée, sans introduire de backend à déployer et maintenir. Autres sujets R3+ : cache de lecture du référentiel (si la mesure le justifie), custom claims (conditionné à la même mesure).

**Point ouvert « refus explicite vs absence de réponse » — ✅ TRANCHÉ en R3b (2026-08-16).** Trois états visuels distincts, et non deux : c'est `dateConsentement` qui les sépare (`null` → jamais répondu). L'enum `EtatConsentImage` (`lib/models/consent_image.dart`) porte la distinction, `ConsentImageEtat` et `ConsentImageBadge` l'affichent. Motif : un refus se respecte, une absence de réponse se relance — les confondre prêtait à un parent un choix qu'il n'avait jamais exprimé.

### Chantier Référentiel — R3b close (2026-08-16)

Le consentement image s'écrit réellement. C'était le dernier écart RGPD connu du projet : les familles réglaient des toggles qui n'étaient persistés nulle part.

- **Chemin d'écriture : une règle Firestore ciblée, pas une Cloud Function.** `allow write: if false` sur `usagers` a été **remplacé** (pas complété — les `allow` s'additionnent en OU, deux lignes contradictoires auraient été illisibles) par `allow create, delete: if false` + un `allow update` borné. Deux fonctions : `familleDeLUsager()` (rôle famille **et** usager dans ses `usagersIds`, en un seul `get()`) et `consentImageValide()`.
- **Le piège de cette règle, à ne pas oublier ailleurs : `affectedKeys()` ne descend pas dans les sous-maps.** `consentImage` étant un objet imbriqué, `hasOnly(['consentImage'])` autorise la clé sans rien dire de son contenu — un client modifié y écrirait n'importe quoi. D'où la validation explicite du contenu : clés autorisées, types, `etablissement` figé à sa valeur antérieure, `dateConsentement` obligatoirement `timestamp`, `saisiPar` cloué sur `request.auth.uid`.
- **Opt-in strict.** `dateConsentement` obligatoire à l'écriture : sans horodatage, impossible de distinguer plus tard un refus explicite d'une absence de réponse. Un seul champ global (dernière modification, tous types confondus), pas un timestamp par booléen.
- **Un seul écran écrit : `ConfidentialiteRGPDScreen`** (Profil > Paramètres > Confidentialité et RGPD). Deux toggles seulement — individuelle et unité.
- **Fratrie : sections empilées, une par enfant, chacune avec son propre bouton.** Pas de sélecteur (aucun état à gérer, et un sélecteur cacherait l'existence du second enfant). Bouton par enfant parce que chaque usager est un document distinct : un bouton unique laisserait croire à une écriture atomique que Firestore ne garantit pas ici.
- **`consentImage.etablissement` n'a plus aucune représentation visuelle.** Le champ reste dans le schéma (pas de migration), figé par la règle, sans écran ni écriture. `ConsentImageEtat` affiche **deux pastilles, plus trois**. La portée établissement relève de `peutDiffuserEtablissement` + le texte d'alerte de l'étape 2.
- **Le badge ne s'affiche pas quand tout est autorisé** — c'est une alerte, et une unité compte jusqu'à 27 usagers : pastiller chaque ligne conforme noierait les deux ou trois qui demandent attention. L'absence de badge *est* le signal « rien à signaler ».
- **Le seed ne réécrit plus jamais `consentImage` sur un document existant** (paramètre `champsCreationSeule` de `semer()`, même traitement que `dateCreation`). **C'est un défaut que R3b a créé et refermé dans le même chantier** : le script est rejoué à chaque rentrée pour resynchroniser l'effectif, et il aurait écrasé les consentements donnés par les familles. Règle générale : une donnée que seule la famille peut produire ne doit jamais être réécrite par un outil d'administration.
- **Les 6 cas de test ont migré du mock vers `referentiel.json`**, avec `saisiPar: null` — ils portaient le vrai uid Firebase de Séb, et ce fichier est versionné. `dateConsentement` s'y exprime en jours relatifs (`dateConsentementJoursAvant`), jamais en date calendaire.

**Amélioration future — migration de l'écran de recueil à l'inscription.** `ConsentImageScreen` a été **neutralisé** : il informe et renvoie vers les paramètres, il n'écrit plus rien. Motif : un seul écran écrit dans ce chantier, et laisser des toggles qui n'enregistrent pas aurait été pire que pas de toggles du tout (un parent valide, rien n'est gardé, il découvre tout à zéro ensuite). À reprendre **au moment de l'étape 2 (photos) si l'onboarding le justifie** — recueillir le consentement dès l'inscription n'a de valeur que le jour où des photos circulent.

**Amélioration future — saisie déléguée (« parent sans smartphone »).** Le fallback prévu au brief de juillet (un admin/coordinateur saisit à la place du parent) est **abandonné pour ce chantier** : `saisiPar` est cloué sur `request.auth.uid`, aucun pro ne peut écrire ce champ. **Solution de repli pour le pilote : l'accompagnement humain sur le compte du parent** — Séb ou un éducateur assis à côté de lui, avec son téléphone. Pas un mécanisme technique de saisie déléguée. Un vrai rôle proxy avec traçabilité (qui a saisi pour qui, quand, sur quelle base) est classé amélioration future, hors périmètre actuel.

**Phases suivantes — ordre de câblage acté : publications → messages → documents → agenda** (notifications câblées au fil de l'eau par fonctionnalité plutôt qu'en bloc final, pas une phase à part). Raisonnement :
- **Publications d'abord**, pas par priorité fonctionnelle mais parce que c'est ce chantier qui pose les patterns réutilisés ensuite par tout le reste : règles Firestore scopées par `unitesAcces`, upload photos vers Storage, pagination du feed, soft delete (`masquee`/`dateMasquage`). Le Journal de vie en découle directement, puisqu'il est alimenté par les publications.
- **Messagerie immédiatement après** : c'est le cœur réel du cahier de liaison papier que Relio remplace — l'échange bilatéral quotidien entre pro et famille. Ni l'agenda ni les documents ne remplacent le carnet ; la messagerie, si.
- **Décision produit actée** : le périmètre du test de validation interne à l'unité de Séb est publications + messagerie, pas publications seule — présenter l'app sans messagerie reviendrait à demander un retour terrain sur un produit qui ne remplace pas encore le carnet.
- **Documents** (autorisations à signer, etc.) **puis agenda** ensuite, dans cet ordre.

**Chantier publications, découpage acté en trois itérations :**
1. **Publications texte seul** — ✅ **CLOSE, validée sur Pixel 9a le 2026-07-31.** Voir le détail ci-dessous.
2. **Upload photos** — ✅ **CLOSE, validée sur Pixel 9a le 2026-08-19.** Voir « Publications — étape 2 close » ci-dessous.
3. **Likes et commentaires** : dépendent des publications déjà existantes, donc après.

**Séquencement Publications Étape 2 (photos) — décision du 2026-08-16, appliquée et close le 2026-08-19**

Storage et l'upload photo pour les trois types de publication (individuelle, groupe,
établissement) s'activent **ensemble, en un seul chantier, après R3b** — pas d'activation
partielle ni de feature flag par type.

Raison : établissement n'a structurellement aucun `usagersConcernes`, donc R3b (écriture du
consentement) ne le concerne pas techniquement. Une activation asymétrique était possible
(établissement ouvert dès un texte d'alerte, individuelle/groupe gatés par R3b) mais a été
écartée au profit de la simplicité — une seule condition d'activation pour tout Storage, pas
deux comportements à maintenir pour gagner une session sur un seul type.

**Garde-fou retenu pour établissement** (une fois Storage ouvert) : texte d'alerte fixe affiché
sous le sélecteur de photo à chaque publication établissement (**pas une modale qu'on ferme une
fois**) : rappel de vérifier l'absence de visage identifiable. S'ajoute à
`peutDiffuserEtablissement` (qui restreint qui accède à ce type) et à la formation du pro (hors
produit). **Pas de détection technique, pas de checkbox de déclaration.**

**Ordre : R3b (consentement, tous types) → Étape 2 (Storage + photos, tous types, ensemble).**

### Publications — étape 1 close (2026-07-31)

Brief : `docs/briefs/brief-publications-etape1.md` (son encadré de tête a été **remis à jour le 2026-08-16** pour refléter le rétablissement de la clause `peutDiffuserEtablissement` — voir « portée étendue »). Scénarios passés : création des 3 portées, `cibles` vérifiée en console, modification, masquage, périmètre restreint de `pro.test`, publication établissement par un pro sans permission, feed famille fratrie filtré, absence constatée d'une publication hors périmètre.

> **⚠️ Un scénario de cette liste s'est inversé le 2026-08-16.** « Publication établissement
> par un pro sans permission » a été validé le 31/07 avec le résultat « **réussit** ». Depuis
> l'extension de `peutDiffuserEtablissement`, le résultat attendu est « **refusée** » (chip
> grisé côté interface, `permission-denied` côté règle). **Ce n'est pas une régression, c'est
> un changement de comportement voulu** — ne pas le relire plus tard comme un défaut, et ne
> pas « corriger » la règle pour retrouver l'ancien résultat.

- **Champ `cibles`** (`array<string>`) : le champ technique qui permet aux feeds pro et famille d'utiliser **la même requête et le même index** malgré des périmètres de nature différente. Individuelle → `[usagerId, uniteId]` ; groupe → `[...usagersPresents, uniteId]` ; établissement → `[etablissementId]`. Dérivable de `usagersConcernes`/`uniteId`/`typePublication`, calculé à la création, **jamais modifié ensuite**. `usagersConcernes` reste le champ *sémantique* (il alimentera le Journal de vie) ; ne pas confondre les deux.
- **La fusion `unitesAcces` + `usagersIds` + `etablissementId` dans un seul `hasAny`** n'est sûre que grâce au préfixage des ids — voir « Décisions verrouillées ».
- **Un seul `get()` par évaluation, garanti par construction** : la fonction `accesLecture()` de `firestore.rules` lie `userDoc()` dans un `let` plutôt que de l'appeler trois fois. Ça supprime la dépendance à la mutualisation des `get()`, qui reste non mesurée — avec une page de 15, trois `get()` non mutualisés auraient fait échouer la requête (plafond : 20 par requête).
- **Index composite obligatoire** : `firestore.indexes.json` (`cibles` CONTAINS + `dateCreation` DESC), déclaré dans `firebase.json`, déployé. Sans lui Firestore **refuse** la requête du feed — ce n'est pas une optimisation.
- **Décision (b) du brief §2, actée** : la règle de création vérifie que `uniteId` appartient aux `unitesAcces` de l'auteur, mais **pas** que chaque usager de `usagersConcernes` relève de cette unité (ce serait un `get()` par usager). Résidu de risque accepté pour le MVP : un client modifié pourrait glisser un id d'usager d'une autre unité du même établissement. À reconsidérer sur incident réel.
- **`Future` paginé par curseur, pas de `Stream`** — décision d'architecture qui **engage Messages, Documents et Agenda** : le même pattern y sera réutilisé tel quel. Le temps réel est reporté à l'étape 3, où un compteur qui bouge en direct apporte une vraie valeur. Pagination : 15 par page, `startAfterDocument`, bouton « Charger plus », tirer-pour-actualiser.
- **`masquee` filtré côté client**, pas dans la requête (éviter un index composite de plus). Conséquence assumée : une page de 15 peut en afficher 13.
- **La règle de lecture ne filtre pas `masquee`** — délibérément. Une publication masquée reste lisible par son périmètre ; c'est l'affichage qui décide. L'auteur et les modérateurs la voient avec un bandeau « Masquée par… » ; tous les autres ne la voient pas. Une règle qui la masquerait empêcherait l'auteur de constater le retrait.
- **`peutModerer` est réel** : champ sur `users/{uid}`, lu par `ProUser`, utilisé par la règle `update` (branche masquage) et par l'affichage du menu « ⋮ ». *Modifier* reste réservé à l'auteur, même pour un modérateur — modérer, c'est retirer, jamais réécrire les mots d'un autre.
- **Défaut corrigé au passage — `VisibiliteSelection.uniteConcerneeId` ne valait que pour la portée groupe.** Une publication individuelle partait donc sans unité, et la règle la refusait systématiquement. Le sélecteur déduit désormais l'unité de l'usager choisi. Les trois autres écrans qui partagent `VisibiliteSelector` testent tous `type == groupe` avant de lire ce champ : aucun impact.
- **Défaut corrigé au passage — la déconnexion n'existait pas.** Le bouton « Déconnexion » naviguait vers `LoginScreen` sans fermer Firebase Auth ni vider `AuthService.currentProUser`/`currentFamilleUser`. Invisible tant qu'aucun écran ne bornait ses requêtes sur l'identité en mémoire ; bloquant dès que le feed l'a fait (une session famille ouverte après une session pro requêtait avec le périmètre du pro → `permission-denied` sur **tout** le feed). `AuthService.signOut()` ferme les deux, et `signIn` vide les deux champs avant d'en poser un. **Invariant : au plus une identité renseignée à la fois.**
- **Sélecteur de photos retiré de `CreatePublicationScreen`** jusqu'à l'étape 2 : il ajoutait des vignettes factices qui n'allaient nulle part. Tant que rien n'était persisté c'était cohérent ; maintenant que la publication part réellement en base, un pro y aurait perdu ses photos sans le savoir.
- **Likes et commentaires affichés mais inertes** (compteurs à 0, estompés, sans tap) jusqu'à l'étape 3 — le schéma ne porte aucun champ de comptage. L'interactivité précédente (like animé, bottom sheet `_CommentsSheet`) a été retirée et reste dans l'historique Git au commit `9fde98c`.
- **`mockPublications` conservé, marqué `// TEMPORAIRE`** : il n'alimente plus aucun écran, il n'est gardé que pour ses commentaires de démonstration, futures fixtures de l'étape 3. À supprimer avec `PublicationCommentaire` à ce moment-là.
- **Le seul point de la définition de terminé non vérifié** : le scénario 3 du brief (« un pro tente de publier sur une unité hors de son périmètre → refusée ») **n'est pas atteignable depuis l'interface** — le sélecteur ne propose que les unités autorisées. La règle existe et est active (c'est elle qui a refusé toutes les publications individuelles avant le correctif ci-dessus), mais elle protège contre un client modifié, que l'app ne sait pas simuler. Le prouver demande le rôle IAM **Firebase Rules Admin**, dont l'attribution est reportée et réservée en priorité à la règle de Messagerie.

### Publications — étape 2 close (2026-08-19) : Storage et photos

Les photos circulent réellement, sur les **trois types de publication activés ensemble**
comme prévu. Les 8 scénarios de validation sont passés sur Pixel 9a.

**Les six décisions du chantier**

**1. Compression — JPEG, qualité 80, 1920 px sur le plus grand côté**, via
`flutter_image_compress`, côté client, avant envoi, identique aux trois types. On passe de
3-8 Mo à 200-600 Ko.
- **Le piège de `minWidth`/`minHeight`, à ne pas réintroduire** : malgré leur nom, ces
  paramètres garantissent que le résultat reste *au moins* aussi grand que la boîte
  donnée. La doc du package l'illustre — 4000×2000 avec `minWidth: 1920, minHeight: 1080`
  sort en **2160×1080**. Leur passer naïvement `1920, 1920` ferait sortir une photo
  4032×3024 de Pixel en 2560×1920. `PhotoService` mesure donc les dimensions réelles
  d'abord (`ImageDescriptor.encoded`, en-tête seul, sans décoder les 12 millions de
  pixels) et passe la cible exacte.
- **Tout en mémoire, jamais sur des fichiers** : sur le Web — cible MVP — le package
  n'expose que `compressWithList`. Un seul code pour Android, Web et iOS.
- **EXIF supprimé** (`keepExif: false`) : une photo de téléphone embarque les
  **coordonnées GPS** du lieu de prise de vue, donc l'adresse de l'IME, lisibles par
  toutes les familles destinataires. Corollaire **obligatoire** : `autoCorrectionAngle:
  true`, sinon toutes les photos verticales s'affichent couchées — l'orientation est
  précisément portée par l'EXIF qu'on supprime.
- La compression a lieu **à la sélection**, pas à la publication : mémoire bornée
  (5 × ~400 Ko au lieu de 5 × 8 Mo), publication rapide, fichier illisible signalé avant
  que le pro n'ait rédigé son texte.

**2. Chemins Storage — `publications/{publicationId}/{index}.jpg`, index 0 à 4.** Aucune
hiérarchie établissement / unité / usager : la publication reste la seule source de vérité
sur la portée, et `storage.rules` la relit plutôt que de dupliquer cette logique.
- **Le nom d'origine du fichier est abandonné** (décision affinée le 2026-08-19, le brief
  prévoyait `{index}_{nomFichier}.jpg`) : une photo peut arriver nommée
  `Emma_Bernard_sortie.jpg`, et ce nom se retrouverait dans un chemin Storage, dans l'URL
  publique et dans la console. Le prénom d'un enfant n'a rien à faire dans une URL, et
  l'ordre est déjà porté par l'index.
- C'est aussi ce nom contraint qui **borne le dossier à 5 objets** : les règles Storage ne
  savent pas compter les fichiers d'un dossier, contraindre le nom est le seul garde-fou
  possible à ce niveau.

**3. Suppression — soft delete seul, aucune suppression physique.** `allow delete: if
false` côté Storage comme côté Firestore. Les fichiers d'une publication masquée restent
en Storage ; aucun chemin légitime de l'app n'y mène.
- **À ne jamais présenter autrement : le masquage n'est PAS une révocation technique.**
  `photos` contient des **URLs de téléchargement**, qui portent leur propre jeton et
  fonctionnent ensuite sans authentification. Qui détient l'URL y accède encore après
  masquage.
- **Échappatoire manuelle en cas d'incident réel** : régénérer le jeton d'accès du fichier
  depuis la console Firebase (Storage → le fichier → jeton). Ça invalide **toutes** les
  URLs existantes pour ce fichier. Geste grossier et non granulaire, mais suffisant pour un
  pilote à un seul établissement. Une révocation automatique au masquage (Cloud Function)
  reste une **amélioration future**.
- **Pourquoi des URLs et non des chemins** : redemander l'URL à chaque affichage coûterait
  ~2 lectures Firestore par photo et par rafraîchissement (un fil de 15 publications à 3
  photos = 90 lectures) **sans rien protéger de plus** — l'URL rendue porte un jeton dans
  les deux cas. Le gain de l'option « chemin » se limite à cesser d'émettre de nouveaux
  liens, pas à révoquer les anciens.

**4. Règles Storage — même logique d'accès que Firestore, jamais une seconde logique.**
`accesLecture()` de `storage.rules` est la **copie conforme** de celle de
`firestore.rules` ; les deux doivent le rester. Lecture = périmètre de la publication ;
écriture = l'auteur seul, et seulement tant que `photos` est vide.
- **Plafond dur : deux documents Firestore par évaluation** (« No more than two Firestore
  documents may be accessed in a single Rules evaluation »). La règle de lecture en
  consomme exactement deux — utilisateur + publication. **Aucune place pour un troisième
  `get()`** : un besoin supplémentaire devra passer par une dénormalisation dans le
  document publication.
- **La faute commise et corrigée le jour même** : la première version appelait
  `publicationDoc()` **deux fois** dans la même règle d'écriture — exactement ce que
  `firestore.rules` avait déjà réglé avec un `let`. Toujours **lier puis lire la
  liaison**, jamais appeler deux fois.
- Troisième branche ajoutée au `allow update` de `publications` : l'auteur écrit `photos`
  **une seule fois**, si la liste est encore vide, 1 à 5 entrées. Ordre des opérations :
  document créé (`photos: []`) → photos envoyées → URLs inscrites. L'ordre inverse
  (pré-générer l'id) a été écarté : la règle Storage n'aurait rien à vérifier, et un pro
  qui abandonne laisserait des fichiers **orphelins et définitifs**, que rien ne référence
  et que personne n'a le droit de supprimer.

**5. Garde-fou administration — le script de seed ne doit JAMAIS être étendu à Storage.**
Ni créer, ni modifier, ni supprimer un fichier. Même principe que `champsCreationSeule`
sur `consentImage` en R3b : **une donnée produite par un utilisateur réel — ici une photo
envoyée par un pro — ne doit jamais pouvoir être écrasée par un outil de
resynchronisation** rejoué à chaque rentrée.

**6. Garde-fou établissement — un texte d'alerte fixe**, non fermable, sous le sélecteur de
photo, à chaque publication de type établissement : « Publication établissement : vérifiez
qu'aucun visage n'est identifiable sur les photos partagées. » Ni case à cocher de
déclaration, ni détection technique, ni affichage de la liste des refus. Orange
`shade800` — la teinte des refus de consentement partout ailleurs dans l'app, pour qu'un
pro n'ait rien à réapprendre.

**⚠️ Le piège d'activation cross-service — à relire avant TOUT chantier touchant une règle
qui appelle `firestore.get()`**

Une règle Storage qui interroge Firestore exige une **activation explicite du lien entre
les deux produits**. Sans elle, l'appel échoue, la condition entière échoue, et le client
reçoit un `403 / StorageException -13021` (« User does not have permission to access this
object ») **nu, sans rien qui désigne la cause**.

**Un déploiement CLI non interactif n'affiche jamais l'invite d'activation.** `firebase
deploy --only storage` répond « compiled successfully » puis « released rules », et rien
d'autre — la règle est bien déployée et bien compilée, elle refuse simplement tout. Seule
la console web montre le bandeau.

Avant de conclure à un échec :
1. Console Firebase → **Storage → Règles** : vérifier qu'aucun bandeau « appels de base de
   données multiservices non configurés » n'apparaît, et l'activer depuis là si c'est le
   cas.
2. **Attendre quelques minutes** : l'activation se propage avec du retard. Un test
   immédiat peut encore échouer sans que rien ne soit cassé.
3. Seulement ensuite, chercher ailleurs.

**Méthode de diagnostic qui a fonctionné, à reprendre telle quelle** : déployer une version
de la règle **sans aucun `firestore.get()`** (authentification, forme du nom, taille et
type conservés), tester un envoi, puis remettre la vraie immédiatement. Si l'envoi passe,
la cause est dans les appels cross-service et non dans les prédicats locaux — isolé en un
seul déploiement, sans deviner.

**Storage ne renonce jamais tout seul non plus — leçon jumelle de R3a**

Par défaut le SDK Storage réessaie **jusqu'à 10 minutes** avant de faire remonter un échec
d'envoi. Pendant tout ce temps l'écran tourne sans rien dire, et si l'utilisateur quitte
l'écran entre-temps, un `if (!mounted) return;` supprime le message. **Les deux se sont
produits ensemble le 2026-08-19** : le refus de règle existait, personne ne l'a su. D'où
trois correctifs, à ne pas défaire :
- `setMaxUploadRetryTime` / `setMaxOperationRetryTime` à **30 s** dans `main.dart` —
  l'analogue exact de `delaiMaxLecture` (R3a), sur un autre produit. Ce délai borne les
  **reprises après échec**, pas la durée d'un transfert qui progresse.
- Le message d'échec passe par une `GlobalKey<ScaffoldMessengerState>`
  (`lib/utils/messages_globaux.dart`) posée sur `MaterialApp.scaffoldMessengerKey`, et
  **avant** le test de `mounted` : il s'affiche même si l'écran d'origine est parti.
  `mounted` ne sert plus qu'au `pop()`.
- `log()` (`dart:developer`) avec l'id de la publication et l'erreur d'origine — il a fallu
  fouiller le logcat Android brut pour retrouver le 403.
- **Écarté : un champ `photosEnEchec` en base.** Durable et affichable, donc tentant, mais
  **poser ce marqueur demande le réseau, alors que la première cause d'échec d'envoi est la
  perte du réseau** : un marqueur absent exactement quand il compte vaut moins que pas de
  marqueur.
- **Limite assumée** : si l'app est tuée en plein envoi, aucun message n'est possible. Le
  filet reste le fil lui-même — une publication sans photo, ça se voit. Recours unique, et
  c'est ce que dit le message : masquer et republier, les photos n'étant pas ajoutables
  après coup.

**Résidu accepté, NON fermé** — le verrou est « `photos` encore vide », **identique dans
les deux fichiers de règles**. Conséquence : une publication de l'étape 1 (qui ne porte pas
le champ `photos`) pourrait recevoir des photos après coup via un client modifié. Borné à
ses propres publications, 5 photos, une seule fois. Le fermer demanderait une fenêtre
temporelle après `dateCreation`, qui devrait exister **à l'identique des deux côtés** —
sinon des fichiers arriveraient dans Storage sans que le document puisse jamais les
référencer, ce qui serait un pire défaut que celui qu'on corrige. **Deux verrous identiques
valent mieux qu'un verrou plus fin de chaque côté.** Accepté tel quel, comme la décision
(b) de l'étape 1.

**Hors périmètre, confirmé** : le **Journal de vie n'affiche aucune publication réelle**
(tuiles mock en dur), c'est l'étape 5. Les photos y apparaîtront le jour où les
publications y apparaîtront — il n'y avait rien à y faire pour ce chantier.

**Comptes de test disponibles sur `relio-dev`** : un compte pro (Esteban, 3 unités, `peutDiffuserEtablissement: true`, `peutModerer: true`), un compte pro restreint (`pro.test`, `unite_001` seule, les deux permissions à `false`) et deux comptes famille — un simple (KSOS Mama, `usagersIds: ["usager_001"]`) et un fratrie (`usagersIds: ["usager_015","usager_033"]`, deux unités). **Les trois profils sont nécessaires** : le compte complet ne peut rien prouver seul, puisque rien n'est hors de son périmètre.

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
- ~~Les consentements image sont lus et écrits dans `mockUsagersCatalogue`~~ — **RÉGLÉ en R3b (2026-08-16)**, voir « Chantier Référentiel — R3b close ». `ConfidentialiteRGPDScreen` écrit réellement sur Firestore ; `ConsentImageScreen` (inscription) a été neutralisé et n'écrit plus rien. C'était le dernier écart RGPD connu ; il est fermé avant le pilote comme prévu.
- **Cas de test du badge de consentement — reposés en R3b dans `referentiel.json`** : six usagers (`usager_001`, `002`, `003`, `017`, `031`, `032`) portent un `consentImage` délibérément varié. Ils couvrent désormais les **trois** états (`usager_001`/`017`/`031` tout autorisé, `usager_002`/`032` refus explicite, `usager_003` mixte), les 49 autres fournissant le cas « non renseigné ». `saisiPar` y vaut **`null`** — les fixtures du mock portaient le vrai uid Firebase de Séb, et `referentiel.json` est versionné : le graver aurait été irréversible. `dateConsentement` s'exprime en **jours relatifs**, jamais en date figée. Deux cas valent d'être signalés : la paire d'homonymes `usager_017`/`usager_032` porte volontairement des consentements **opposés** — c'est le cas qui détecte une résolution par nom au lieu de l'id ; et `usager_031` est sur une troisième unité, ce qui vérifie que le badge suit l'usager et non l'unité.
- `utilise` et `dateUtilisation` (schéma `codes_invitation`) ne sont jamais mis à jour après la lecture d'un code — écriture interdite côté client par la règle `write: if false`. Aucune traçabilité d'usage des codes (combien de fois, par qui, quand) tant qu'il n'y a pas de Cloud Function pour le faire côté serveur.
- **Amélioration future — Cloud Function de validation serveur du code d'invitation** : la règle `create` sur `users/{userId}` fait deux `get()` sur `codes_invitation` directement dans les security rules, ce qui fonctionne pour un établissement pilote mais mérite d'être révisé (coût, complexité, logique métier plus riche) avant l'ouverture de Relio à un deuxième établissement — probablement en déplaçant cette validation vers une Cloud Function dédiée plutôt que de l'alourdir davantage dans les règles.
- **Point de vigilance — typage de `AuthService.signIn`** : la méthode retourne `Object` (soit un `ProUser`, soit un `FamilleUser`), départagé par un `is ProUser` côté appelant (`LoginScreen`). Ça reste lisible pour deux rôles, mais à retyper plus explicitement (union type/sealed class, ou un enum de rôle assorti d'un record) le jour où le rôle `admin_etablissement` rejoindra `AuthService.signIn` — un enchaînement de `is`/`else` ne passera pas bien à trois rôles ou plus.
- **Dette technique — pont temporaire dans `mock_data.dart`** : `mockProConnecteUid` a été changé de `'pro_martin'` vers l'uid Firebase réel du compte pro de test de Séb (`greI7Ibic4eZCRNnfFnMCv1pTxw1`), marqué `// TEMPORAIRE` dans le code, avec une entrée correspondante ajoutée dans `mockProsCatalogue` pour que `findProById` ne plante pas. Nécessaire car les données mock de notifications/documents/messages référencent encore `destinataireId`/`envoyePar`/`expediteurId` via ce même mock — sans ce pont, elles n'apparaîtraient jamais pour le compte pro réellement connecté. À retirer une fois ces collections câblées sur Firestore (chantier futur, pas encore planifié) ; d'ici là, `mock_data.dart` contient littéralement l'uid Firebase d'une vraie personne.

## Logique métier : les 3 types de publication

1. **Individuelle** — concerne 1 usager. Visible par : la famille concernée + les professionnels autorisés (unités d'accès). Ajoutée automatiquement au journal de vie de l'usager.
2. **Groupe** (affiché « Unité » — voir la règle de vocabulaire dans « Architecture des données ») — concerne une unité, avec sélection des usagers présents (tous pré-cochés, le pro décoche les absents). Visible par : les familles des usagers concernés + les professionnels concernés. Ajoutée au journal de vie de chaque usager concerné.
3. **Établissement** — pas de sélection d'usagers. Visible par tous (familles + professionnels). Valorise la vie institutionnelle.

Chaque publication : texte (max 1000 caractères), 1 à 5 photos, auteur, date, likes, commentaires, notifications.

### ✅ POINT BLOQUANT REFERMÉ le 2026-08-19 — publications d'établissement et consentement image

> **Ce point est clos.** Il est conservé ci-dessous parce qu'il documente un angle mort
> structurel qui, lui, n'a pas disparu : une publication d'établissement ne cible aucun
> usager, donc aucun consentement image ne peut lui être opposé. Trois garde-fous s'y
> superposent désormais — `peutDiffuserEtablissement` (qui publie), le texte d'alerte fixe
> de l'étape 2 (ce que la photo montre), et la formation du pro (hors produit). **Ne pas le
> rouvrir sans raison nouvelle, et ne pas remplacer le texte d'alerte par une case à cocher :
> les deux ont été instruits et tranchés.**

Les publications de type `etablissement` n'ont, par construction, aucun `usagersConcernes` — donc aucun mécanisme de vérification de consentement image ne s'applique à elles, quel que soit l'auteur. Dès que l'étape 2 introduit les photos, ce point doit être tranché avant d'ouvrir l'upload sur ce type de publication : soit un mécanisme de déclaration explicite au moment de publier (ex. confirmation « aucun enfant identifiable dont la famille a refusé le consentement n'apparaît sur cette photo »), soit une restriction de contenu (publications établissement limitées à du contenu non-identifiant : décors, bâtiments, activités sans visage reconnaissable), soit la restriction d'auteur envisagée aujourd'hui (`peutDiffuserEtablissement`) combinée à une formation ciblée des coordinateurs sur ce risque précis. **Ne pas ouvrir l'étape 2 sur les publications établissement sans avoir tranché ce point.**

**Mise à jour du 2026-08-16 :** la troisième branche (restriction d'auteur) est **retenue et implémentée** — `peutDiffuserEtablissement` gate désormais la publication établissement, voir « portée étendue ». Elle réduit le risque en réservant ce type de publication à des comptes formés, mais **ne referme pas le point bloquant** : elle contrôle *qui* publie, pas *ce que la photo montre*. Un coordinateur autorisé peut toujours diffuser à tout l'établissement la photo d'un enfant dont la famille a refusé le consentement « établissement ».

**Le volet contenu a été tranché le 2026-08-16** — voir « Séquencement Publications Étape 2 » plus bas. Garde-fou retenu : un **texte d'alerte fixe** sous le sélecteur de photo, à chaque publication établissement. **Ni checkbox de déclaration, ni détection technique, ni affichage de la liste des refus** — les trois ont été envisagés puis écartés. **Implémenté et validé le 2026-08-19** (`_AlerteEtablissement` dans `create_publication_screen.dart`) : le point bloquant est refermé.

## Consentement image (usagers)

Les familles autorisent ou refusent la diffusion de la photo de leur enfant, **par type de publication** (individuelle / groupe / établissement), sans que ce choix ne conditionne jamais l'accès au service (RGPD art. 7§4 — non-conditionnement).

**Règle centrale :** un refus n'empêche jamais un pro de publier une photo. Il affiche seulement un badge d'alerte informatif (« Pas d'autorisation image ») sur les écrans de sélection d'usager pour une publication individuelle ou de groupe (`SelectionUsagerJournalPage`, `CreatePublicationPage`) — pas de sélection d'usager en établissement, donc pas de badge applicable. Aucun blocage technique, sur aucun des trois types.

**Schéma `usagers/{usagerId}.consentImage`** : `individuelle` / `groupe` / `etablissement` (bool, faux par défaut) + `dateConsentement`, `versionTexte`, `saisiPar` (uid famille, ou uid admin/coordinateur en fallback pour un parent sans smartphone). Modifiable uniquement par la famille liée à l'usager ou un admin/coordinateur — règle de sécurité Firestore dédiée (même pattern que les publications).

**Recueil :** écran dédié juste après la création de compte famille par code d'invitation, avant l'accès au reste de l'app (3 toggles décochés par défaut, ton chaleureux, prénom dynamique, rassurance explicite que le refus n'empêche pas d'utiliser Relio — texte complet dans `docs/briefs/brief-technique-consentement-image-invitations.md`). Modifiable ensuite dans Profil > Paramètres > Confidentialité/RGPD (mêmes toggles, pré-remplis).

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
- ~~Publication établissement (fil d'actu) reste ouverte à tous les pros, sans restriction.~~ **Décision inversée le 2026-08-16** — voir « portée étendue » ci-dessous. Le motif d'origine (contenu de valorisation institutionnelle, moins sensible qu'un document ou un message) n'a pas résisté à l'ouverture des photos : une photo diffusée à toutes les familles de l'établissement est au moins aussi sensible qu'un document.
- **Reste à faire (Item 4, repositionné après la Phase 1 du chantier Back)** : champ réel `peutDiffuserEtablissement` sur `users/{uid}` en base Firestore + la security rule associée (voir Architecture des données, Chantier Back et Contraintes et vigilance) — invérifiable avant que la collection `users/{uid}` réelle existe (Phase 1), donc à ne pas écrire avant.

### `peutDiffuserEtablissement` — portée étendue (2026-08-16)

`peutDiffuserEtablissement` gate désormais **deux surfaces, pas une seule** :

- Documents diffusés (existant — le chip grisé couvre en réalité **documents et messages**, voir la puce ci-dessus ; côté règles Firestore, aucune des deux collections n'est encore écrite)
- **Publications de type établissement (nouveau)**

Un seul booléen, **pas de rôle dédié** coordination/direction/admin. Individuelle et groupe restent
gérées par `unitesAcces` seul, aucune permission supplémentaire dessus.

**UI** — option « Établissement » grisée / non cliquable dans le sélecteur de type de
`CreatePublicationPage` si `peutDiffuserEtablissement != true`, même traitement visuel que les
autres restrictions déjà en place dans l'app (paramètre `restrictionEtablissementActive` de
`VisibiliteSelector`, aucun composant nouveau).

**Firestore rules** — refus en écriture de toute publication `typePublication == "etablissement"`
si le compte pro auteur n'a pas `peutDiffuserEtablissement == true`. **Étendre la règle existante**
sur la collection `publications`, ne pas en créer une seconde en parallèle.

Aucun changement de modèle de données. **Aucune gestion rétroactive** si le booléen change après
coup — les publications déjà créées restent inchangées.

**Ce que cette extension ne règle pas** : elle restreint *qui* publie, pas *ce que la photo
contient*. Le point bloquant de l'étape 2 sur le consentement image des publications
d'établissement (voir « Logique métier ») reste donc ouvert.

## Contraintes et vigilance

- **RGPD et données sensibles** : les données concernent des enfants et adultes en situation de handicap. Aucune donnée réelle pendant le développement. Prévoir dès le départ des règles de sécurité Firestore strictes (jamais de règles ouvertes, même « temporairement »). Le consentement à l'image est géré par type de publication et ne conditionne jamais l'accès au service (RGPD art. 7§4) — voir « Consentement image ». `firestore.rules` existe et est déployé sur `relio-dev` ; la règle ci-dessous reste à ajouter. Collections couvertes à ce jour : `users` et `codes_invitation` (Phase 1), `etablissements`/`unites`/`usagers` depuis R2 (lecture scopée par le document `users/{uid}` du demandeur, écriture cliente interdite — le seed y écrit via le SDK Admin, qui contourne les règles ; **une exception depuis R3b** : une famille peut écrire le seul champ `consentImage` de son usager, contenu de la sous-map validé clé par clé), et `publications` depuis l'étape 1 du chantier Publications (lecture scopée par `cibles`, création réservée aux pros et bornée à leurs `unitesAcces`, modification à **trois** branches depuis l'étape 2 — texte, masquage, photos — `allow delete: if false`). **`storage.rules` existe et est déployé depuis le 2026-08-19** : il couvre `publications/{publicationId}/{fichier}` et ne duplique aucune logique de portée, il relit le document publication via `firestore.get()` — lire impérativement « Le piège d'activation cross-service » avant d'y toucher.
- **Règle à ajouter (non commencée, dépend du champ `peutDiffuserEtablissement`)** : sur les collections `documents` et `messages`, refuser toute écriture avec `portee: "etablissement"` si `peutDiffuserEtablissement` n'est pas `true` sur le profil de l'auteur. Réutiliser le pattern `diff().affectedKeys().hasOnly()` déjà documenté dans `docs/briefs/brief-technique-consentement-image-invitations.md` pour la règle de consentement image, à adapter ici. Invérifiable avant la Phase 1 du chantier Back (pas de collection `users/{uid}` réelle avant ça) — ne pas l'écrire avant.
- **Accessibilité** : valeur fondamentale du projet (public TSA notamment). Tailles de texte respectueuses des réglages système, contrastes suffisants, zones tappables généreuses (min 48 px).
- Ne jamais affirmer de garanties de sécurité invérifiables ; vocabulaire conforme RGPD.
- Interface intégralement en français.

## Méthode de travail avec Séb

- Une fonctionnalité à la fois, validation par capture d'écran avant de continuer
- Expliquer ce que tu fais en langage clair (pas de jargon non expliqué)
- Classer toute recommandation : **MVP indispensable / Amélioration future / Vision long terme**
- Challenger les idées risquées, en cofondateur direct mais bienveillant
- Commandes utiles à rappeler à Séb : `flutter run` (choisir le Pixel 9a ou Chrome), `r` pour hot reload, `R` pour hot restart, `q` pour quitter
