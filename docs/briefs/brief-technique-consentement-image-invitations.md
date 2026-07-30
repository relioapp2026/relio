# Brief technique — Consentement image & Invitations

**Statut :** Spécifié et validé par Séb, prêt pour implémentation
**À intégrer pendant :** le chantier de câblage des collections `usagers` et `publications`
**Dépendances :** Chantier 0 (catalogue usagers unifié) — déjà clos

---

## 1. Contexte produit

Relio permet aux professionnels de publier des photos des usagers dans trois contextes : publication individuelle, de groupe, établissement. Les familles doivent pouvoir autoriser ou refuser la diffusion de l'image de leur enfant, **par type de publication**, sans que ce refus ne bloque jamais l'usage de Relio (principe RGPD art. 7§4 — non-conditionnement de l'accès au service).

**Règle produit centrale :** un refus de consentement n'empêche **jamais** un pro de publier une photo. Il informe simplement le pro (badge visuel) que l'usager concerné ne doit pas apparaître visible sur la photo. Aucun blocage technique, sur aucun des trois types de publication.

---

## 2. Schéma Firestore — `usagers/{usagerId}`

Ajouter le champ suivant au document usager existant :

```
usagers/{usagerId}
  ...champs existants (nom, prenom, uniteId, etablissementId, etc.)
  consentImage: {
    individuelle: bool,          // défaut: false
    groupe: bool,                // défaut: false
    etablissement: bool,         // défaut: false
    dateConsentement: timestamp,
    versionTexte: string,        // ex: "v1" — trace la version du texte présenté au parent
    saisiPar: string,            // uid du compte famille, ou uid admin/coordinateur en fallback
  }
```

**Règles :**
- Les trois booléens sont `false` par défaut à la création du document usager (avant tout recueil).
- Aucune présomption de consentement : tant que `dateConsentement` est absent, considérer les trois valeurs comme `false`.
- Modifiable par : le compte famille lié à cet usager (via `familles/{uid}.usagerId`), ou un admin/coordinateur en fallback (parent sans smartphone, blocage technique).

**Règle de sécurité Firestore (pattern déjà utilisé pour les publications) :**

```javascript
match /usagers/{usagerId} {
  allow update: if request.auth != null &&
    (
      // La famille liée à cet usager peut modifier uniquement son propre champ consentImage
      (get(/databases/$(database)/documents/familles/$(request.auth.uid)).data.usagerId == usagerId
        && request.resource.data.diff(resource.data).affectedKeys()
             .hasOnly(['consentImage']))
      ||
      // Un admin/coordinateur peut modifier en fallback
      (isAdminOuCoordinateur(request.auth.uid))
    );
}
```

---

## 3. Écran de recueil — création de compte famille

**Emplacement dans le parcours :** juste après la création du compte famille via code d'invitation, avant l'accès au reste de l'app. Obligatoire au sens où chaque ligne doit recevoir un choix explicite (les cases restent décochées par défaut si le parent ne touche à rien — ce n'est pas bloquant, c'est le comportement RGPD-conforme par défaut).

**Contenu de l'écran (texte v1, ton chaleureux, prénom dynamique) :**

```
Titre : Autorisation à l'image

Intro :
"Relio permet aux professionnels de partager des photos du
quotidien de {prenom} : ateliers, sorties, moments de vie en
unité. C'est à vous de choisir ce que vous souhaitez autoriser.
Vous pourrez modifier ce choix à tout moment depuis votre profil."

Rassurance :
"Que vous acceptiez ou non, vous pourrez utiliser Relio
normalement : messagerie, agenda, documents et journal de vie
restent disponibles dans tous les cas."

--- Toggle 1 (décoché par défaut) ---
Publications individuelles
"Photo de {prenom} visible uniquement par vous, dans une
publication qui le/la concerne personnellement."
☐ J'autorise

--- Toggle 2 (décoché par défaut) ---
Publications de groupe
"Photo de {prenom} visible par les familles des enfants présents
lors d'une activité de son unité."
☐ J'autorise

--- Toggle 3 (décoché par défaut) ---
Publications établissement
"Photo de {prenom} visible par toutes les familles de
l'établissement, lors d'un événement ou d'un temps fort de la
vie institutionnelle."
☐ J'autorise

Note bas de page :
"Si vous ne cochez pas une case, les professionnels pourront
tout de même partager des photos des activités de {prenom} sans
qu'il/elle y apparaisse."

Bouton : Valider mes choix
```

**Résolution de `{prenom}` :** lecture directe de `usagers/{usagerId}.prenom`, où `usagerId` provient du document `invitations/{code}` utilisé à l'inscription (voir section 5).

**Au clic sur "Valider mes choix" :** écrit `consentImage` sur le document usager avec `dateConsentement: now()`, `versionTexte: "v1"`, `saisiPar: <uid famille>`.

---

## 4. Écran de modification — Profil famille

**Emplacement :** Profil > Paramètres > Confidentialité/RGPD (emplacement déjà prévu dans la spec Profil famille existante).

Réutiliser les mêmes trois toggles, pré-remplis avec l'état actuel de `consentImage`. Toute modification réécrit `dateConsentement` et conserve `versionTexte` (sauf si le texte a changé de version — cas non traité au MVP, voir section 7).

---

## 5. Collection `invitations` (création de compte par code)

```
invitations/{code}
  role: "famille" | "pro"
  usagerId: string              // requis si role = "famille"
  unitesAcces: array<string>    // requis si role = "pro"
  etablissementId: string
  utilise: bool                 // défaut: false
  dateCreation: timestamp
  dateExpiration: null          // pas de limite au MVP (décision Séb)
  creePar: string                // uid admin/coordinateur, ou "seed_script" au MVP
```

**Flux à l'inscription :**

1. L'utilisateur saisit uniquement le code reçu (canal de remise hors périmètre technique Relio).
2. L'app lit `invitations/{code}`.
3. Vérifie `utilise == false` (pas de vérification d'expiration au MVP puisque `dateExpiration` est toujours `null`).
4. Si valide :
   - Si `role == "famille"` → crée `familles/{nouvelUserId}` avec `usagerId` recopié du code.
   - Si `role == "pro"` → crée `pros/{nouvelUserId}` avec `unitesAcces` recopié du code.
5. Marque `invitations/{code}.utilise = true`.

**Génération des codes au MVP :** via le script de seed Node.js existant (celui qui alimente déjà `mockUsagersCatalogue`). Une entrée `invitations` par usager/famille à générer, code communiqué manuellement par Séb aux familles de son unité de test. Pas d'écran de génération — reporté à Relio Admin (Phase 2).

---

## 6. Badge d'alerte non-consentement (écrans de sélection usager)

**Où l'afficher :**
- `SelectionUsagerJournalPage` et tout écran de sélection d'usager(s) pour une publication individuelle ou de groupe (`CreatePublicationPage`).

**Comportement :**
- Pour chaque usager listé, vérifier le champ `consentImage` correspondant au type de publication en cours de création (`individuelle` ou `groupe`).
- Si `false` → afficher un badge visuel clair à côté du nom (ex. icône + texte court : "Pas d'autorisation image").
- Aucun blocage : le pro peut sélectionner l'usager et ajouter une photo malgré le badge. Le badge informe, ne bloque pas.
- Publication établissement : pas de sélection d'usager (type déjà sans cette étape), donc pas de badge applicable — consigne établissement hors périmètre technique (photos d'ambiance, pas de gros plan identifiable).

---

## 7. Hors périmètre MVP (Amélioration future / Vision long terme)

- Masquage rétroactif automatisé des publications photo existantes en cas de révocation de consentement (le mécanisme `masquee` déjà posé pour les publications permet de le faire manuellement si besoin, sans développement supplémentaire).
- Gestion de version du texte de consentement (`versionTexte`) et re-consentement si le texte évolue.
- Écran de génération de codes d'invitation dans Relio Admin.
- Expiration des codes d'invitation.
- Détection/floutage automatique de visages non-consentants sur les photos de groupe (Relio IA).
