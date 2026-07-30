# Brief R3a — Débranchement en lecture du référentiel

**Chantier :** Référentiel
**Étape :** R3a (sur 2 : R3b concerne l'écriture du consentement image, hors périmètre ici)
**Prérequis :** R2 close (commit `b5e167e` puis `7ef6d57`), règles validées sur Pixel 9a
**Cible Firebase :** `relio-dev` exclusivement, aucune écriture n'est concernée par R3a

---

## 0. Pourquoi ce chantier est découpé en deux

Le comptage des références a identifié 12 fichiers dépendant de `mockUsagersCatalogue`, et deux
sites d'écriture (`consent_image_screen.dart`, `confidentialite_rgpd_screen.dart`) qui n'ont
aucune contrepartie Firestore — R2 a posé `allow write: if false` sur `usagers`, il n'existe
aucun chemin d'écriture client pour le consentement.

**R3a** débranche tout ce qui est lecture pure. **R3b**, une session distincte, ouvrira un
chemin d'écriture pour le consentement (probablement une Cloud Function, pour préserver
`allow write: if false` sur le reste du document). R3b n'est pas requis avant le chantier
Publications — il devient bloquant uniquement au moment où de vraies familles utiliseront
Relio, ce qui dépend du dossier d'autorisation du pilote, pas du calendrier de code.

**Contrainte transversale à R3a, non négociable : le consentement image continue d'être lu et
écrit exclusivement depuis `mockUsagersCatalogue`, partout, y compris dans les écrans migrés
vers Firestore pour leurs autres champs.** L'objet `Usager` semé sur Firestore porte
`consentImage` à `false` sur les 55 documents — un écran qui lirait ce champ depuis Firestore
afficherait « aucun consentement » sur les 6 usagers dont le mock porte un état volontairement
différencié, ce qui casserait silencieusement le test du badge d'alerte sans qu'aucune erreur
ne se déclenche. C'est plus dangereux qu'une régression visible.

---

## 1. Vérification préalable du périmètre exact

Le comptage transmis contient des artefacts de mise en forme (tableaux tronqués, noms de
fichiers visiblement fusionnés, ex. `create_evenemcation_screen.dart`). **Avant toute
modification**, régénère toi-même la liste exhaustive et exacte des 12 fichiers et de leurs
lignes précises — ne te fie pas aux noms de fichiers du comptage précédent tels quels s'ils te
semblent corrompus. Confirme la liste avant de continuer.

---

## 2. `avatarColor` — dérivation déterministe

`MockUsager.avatarColor` n'existe pas dans le schéma Firestore. Remplacer par une fonction pure :

```dart
Color avatarColorPourUsager(String usagerId) {
  // Dérivée déterministe de l'id — même id, même couleur, à chaque appel,
  // sur chaque appareil, sans dépendre du mock.
}
```

Emplacement : `lib/utils/` ou équivalent existant pour les fonctions pures partagées — aligne-toi
sur la convention déjà en place plutôt que d'en créer une nouvelle.

Exigence : un même `usagerId` doit produire la même couleur avant et après R3a. Vérifier
visuellement sur au moins 3 usagers déjà connus sur le Pixel : la couleur affichée ne doit pas
changer par rapport à ce qui est actuellement visible.

---

## 3. Point de composition unique pour l'affichage d'un usager

Plutôt que de laisser chacun des 10 fichiers dépendants recomposer séparément
« champs Firestore + consentement mock + couleur dérivée », créer un point de composition
unique — par exemple une méthode `ReferentielService.getUsagerAffichage(id)` ou une classe
d'enrichissement dédiée — qui retourne un objet portant :

- les champs identitaires depuis Firestore (`prenom`, `nom`, `uniteId`, `anneeNaissance`,
  `photoUrl`, `actif`)
- `consentImage` depuis `mockUsagersCatalogue` via `findUsagerById`, inchangé
- la couleur dérivée de la section 2

**Un seul endroit à modifier en R3b**, quand le consentement rejoindra Firestore. Documenter
explicitement en commentaire, à cet endroit précis, la raison de ce pont temporaire et sa
date de péremption prévue (R3b).

Ne pas dupliquer cette logique de composition dans les écrans eux-mêmes.

---

## 4. Migration des 10 fichiers dépendants

Pour chacun : remplacer la lecture synchrone de `mockUsagersCatalogue` (directe ou via
`findUsagerById`, `mockUnitesAvecUsagers`, `resolveUsagerId`, `mockUsagersAvecFamillesNomComplet`)
par un appel au point de composition de la section 3, ou par `ReferentielService` pour les
besoins qui ne concernent pas l'affichage individuel (listes par unité, par pro).

**Préférer les méthodes de liste du service (`getUsagersParUnite`, `getUsagersPourPro`,
`getUsagersPourFamille`) à des appels un par un dans une boucle.** Un écran qui listait
10 usagers via 10 appels individuels multiplierait les lectures facturées par 10 — le service
expose déjà les méthodes groupées depuis R2, à utiliser systématiquement pour tout affichage
de liste.

### Le point dur transversal : l'asynchronicité

Le mock était une liste en mémoire, lue instantanément. Firestore est asynchrone. Chacun des
10 écrans doit gérer un état de chargement qu'il n'avait pas — c'est le vrai risque de
régression visuelle de cette étape, plus que le changement de source en lui-même.

Avant de modifier le premier écran, identifie le pattern de chargement déjà utilisé ailleurs
dans l'app (`FutureBuilder`, état `isLoading` géré manuellement, ou autre) et **réutilise ce
pattern existant** plutôt que d'en introduire un nouveau. S'il n'en existe aucun, propose-en un
avant de l'appliquer aux 10 fichiers, pour qu'il soit cohérent partout.

Chaque écran migré doit gérer explicitement : chargement en cours, erreur (`permission-denied`
distinguable des autres, comme en R2), et résultat vide — pas seulement le cas nominal.

### Fichiers concernés

Utilise la liste que tu auras revérifiée à la section 1, organisée par symbole source :

- Lecture directe du catalogue → `mock_data.dart` lui-même, plus les 3 écrans identifiés en
  lecture/écriture de `consentImage` (ceux-ci ne sont **pas** migrés en R3a, voir section 0)
- Via `mockUsagers` / `findUsagerById`
- Via `resolveUsagerId`
- Via `usagerSansAutorisationImage` — **ne pas migrer cette fonction elle-même**, elle doit
  continuer à lire le mock pour le consentement (section 0). Seuls les autres champs affichés
  par les écrans qui l'appellent sont concernés par la migration.
- Via `mockUnitesAvecUsagers`
- Via `mockUsagersAvecFamillesNomComplet`

---

## 5. Suppression du code mort

`mockUsagersAvecFamilles` et `familleUidPourUsager` : zéro usage externe confirmé. Supprimer,
pas migrer.

---

## 6. Écran et tuile de diagnostic

`diagnostic_referentiel_screen.dart` et sa tuile dans `profil_screen.dart` ont rempli leur
rôle : valider R2. Supprimer les deux, comme annoncé lors de la clôture de R2.

---

## 7. Commentaires de documentation

Les 9 occurrences cosmétiques recensées (`mock_data.dart:20,273,618`, `models/document.dart:34`,
`models/evenement.dart:30`, `models/message.dart:30`, et les deux fichiers d'écrans/widgets
identifiés dans le comptage) : mettre à jour pour refléter que le référentiel vit désormais sur
Firestore. Vérifie leur emplacement exact toi-même (section 1) plutôt que de te fier aux noms
tronqués du comptage.

---

## 8. Ce qui reste inchangé, et pourquoi

- `mockUsagersCatalogue` **n'est pas supprimé**. Il continue de porter la seule source de
  vérité du consentement image jusqu'à R3b.
- `consent_image_screen.dart` et `confidentialite_rgpd_screen.dart` ne sont pas touchés.
- Aucune règle de sécurité n'est modifiée.
- Aucune écriture Firestore n'est introduite.

---

## 9. Validation sur Pixel 9a

Pour chacun des 10 écrans migrés, dans cet ordre :

1. L'écran s'affiche sans erreur avec le compte de Séb (3 unités, 55 usagers)
2. L'écran s'affiche correctement avec `pro.test` (1 unité, 14 usagers) — c'est ce compte qui
   vérifie qu'un écran migré respecte bien le scope réel, pas un scope apparent
3. Les couleurs d'avatar sont identiques à ce qu'elles étaient avant la migration, sur au moins
   3 usagers déjà connus
4. Les badges de consentement (là où ils s'affichent) montrent toujours les 6 états
   différenciés du mock, pas un « aucun consentement » généralisé
5. Un état de chargement visible et cohérent apparaît brièvement, pas un écran vide ou figé
6. Couper la connexion réseau un instant sur l'un des écrans : l'erreur doit s'afficher
   proprement, pas un crash

Le point 4 est le plus important de cette liste : c'est lui qui détecte la régression silencieuse
décrite en section 0.

---

## 10. Définition de « terminé »

- [ ] `flutter analyze` sans erreur
- [ ] Liste exacte des 12 fichiers reconfirmée en début de session (section 1)
- [ ] `avatarColorPourUsager` créée, couleurs identiques avant/après sur 3 usagers témoins
- [ ] Point de composition unique créé et documenté, avec date de péremption R3b en commentaire
- [ ] Les 10 fichiers dépendants migrés vers `ReferentielService` / le point de composition
- [ ] `consent_image_screen.dart` et `confidentialite_rgpd_screen.dart` non modifiés
- [ ] `mockUsagersAvecFamilles` et `familleUidPourUsager` supprimés
- [ ] `diagnostic_referentiel_screen.dart` et sa tuile supprimés
- [ ] Les 9 commentaires de documentation mis à jour
- [ ] Les 6 scénarios de validation de la section 9 passés sur les 10 écrans, avec le compte
      `pro.test` en plus du compte de Séb
- [ ] CLAUDE.md à jour : R3a close, R3b spécifié comme prérequis du pilote (pas du chantier
      Publications), avec un rappel explicite que le consentement reste sur le mock jusque-là
- [ ] Commit unique et descriptif

---

## 11. Hors périmètre de R3a

- Chemin d'écriture du consentement image (Cloud Function envisagée) → **R3b**, avant le pilote,
  pas avant Publications
- Suppression de `mockUsagersCatalogue` lui-même → après R3b
- Mise en cache des lectures du référentiel → après mesure de consommation, si justifiée
- Custom claims → amélioration future, conditionnée à la même mesure
- Collection `publications` → chantier suivant
