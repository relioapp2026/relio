#!/usr/bin/env node
'use strict';

/**
 * Seed du référentiel Relio : `etablissements`, `unites`, `usagers`.
 *
 * Ce script ne contient AUCUNE donnée : tout vient de data/referentiel.json,
 * y compris les valeurs par défaut et la répartition attendue.
 *
 * Il est idempotent : rejouer le script ne produit ni doublon ni
 * modification. C'est l'outil de synchronisation du référentiel jusqu'à
 * l'arrivée de Relio Admin, pas un script à usage unique.
 *
 * ATTENTION : le SDK Admin contourne intégralement firestore.rules. D'où le
 * garde-fou sur le projectId ci-dessous, volontairement non contournable.
 *
 * Voir docs/briefs/brief-R1-referentiel-firestore.md et tools/seed/README.md.
 */

const fs = require('fs');
const os = require('os');
const path = require('path');
const admin = require('firebase-admin');

/**
 * Seul projet Firebase que ce script a le droit d'atteindre.
 *
 * Aucun flag, aucune variable d'environnement ne permet de contourner ce
 * contrôle : pour cibler un autre projet il faut modifier cette constante
 * sciemment. Le projet de production `relio-618ca` ne doit jamais pouvoir
 * être atteint par accident.
 */
const PROJET_AUTORISE = 'relio-dev';

const CHEMIN_DONNEES = path.join(__dirname, 'data', 'referentiel.json');
const CHEMIN_CLE_PAR_DEFAUT = path.join(os.homedir(), '.relio', 'relio-dev-sa.json');

/**
 * `--forcer-consentement` : repose les `consentImage` des usagers qui en
 * portent un dans le JSON, même si leur document existe déjà.
 *
 * Sans ce drapeau, `consentImage` ne s'écrit qu'à la création du document et
 * n'est jamais réécrit (voir semer()) — protection indispensable, sans quoi un
 * rejeu effacerait les consentements saisis par les familles.
 *
 * Cette option existe pour un seul usage : réinstaller les six cas de test
 * différenciés sur une base où les 55 usagers ont déjà été semés. Elle NE
 * touche QUE les usagers porteurs d'une fixture explicite dans
 * `referentiel.json` — les autres gardent leur consentement quoi qu'il arrive.
 * C'est la distinction qui empêche l'option de recréer le défaut qu'elle
 * contourne : « forcer » ne veut pas dire « tout remettre aux valeurs par
 * défaut ».
 *
 * Le garde-fou anti-production reste entier : ce drapeau ne change rien à la
 * cible, qui doit toujours être `relio-dev`.
 */
const FORCER_CONSENTEMENT = process.argv.includes('--forcer-consentement');

// --- Sortie ---------------------------------------------------------------

const titre = (t) => console.log(`\n\x1b[1m${t}\x1b[0m`);
const info = (t) => console.log(`  ${t}`);
const succes = (t) => console.log(`  \x1b[32m✓\x1b[0m ${t}`);
const alerte = (t) => console.log(`  \x1b[33m!\x1b[0m ${t}`);

function abandonner(message, details) {
  console.error(`\n\x1b[31m✗ ABANDON — ${message}\x1b[0m`);
  if (details) console.error(`\n${details}`);
  console.error('');
  process.exit(1);
}

// --- Authentification -----------------------------------------------------

/**
 * Résout le chemin de la clé de compte de service, dans cet ordre :
 *   1. GOOGLE_APPLICATION_CREDENTIALS (prioritaire, pour pointer
 *      ponctuellement vers une autre clé sans modifier le script) ;
 *   2. <répertoire personnel>/.relio/relio-dev-sa.json ;
 *   3. échec explicite.
 *
 * Objectif : `npm run seed` doit fonctionner sans aucune commande préalable,
 * y compris sous PowerShell où une variable de session doit sinon être
 * retapée à chaque ouverture de terminal.
 */
function resoudreCheminCle() {
  const depuisEnv = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (depuisEnv && depuisEnv.trim() !== '') {
    if (!fs.existsSync(depuisEnv)) {
      abandonner(
        'la clé indiquée par GOOGLE_APPLICATION_CREDENTIALS est introuvable.',
        `Chemin lu : ${depuisEnv}\n` +
          'Corrigez la variable, ou supprimez-la pour utiliser le chemin par défaut :\n' +
          `  ${CHEMIN_CLE_PAR_DEFAUT}`,
      );
    }
    return { chemin: depuisEnv, origine: 'GOOGLE_APPLICATION_CREDENTIALS' };
  }

  if (fs.existsSync(CHEMIN_CLE_PAR_DEFAUT)) {
    return { chemin: CHEMIN_CLE_PAR_DEFAUT, origine: 'chemin par défaut' };
  }

  abandonner(
    'aucune clé de compte de service trouvée.',
    'Emplacements consultés :\n' +
      '  1. variable d\'environnement GOOGLE_APPLICATION_CREDENTIALS (non définie)\n' +
      `  2. ${CHEMIN_CLE_PAR_DEFAUT} (absent)\n\n` +
      'Pour générer la clé :\n' +
      `  Console Firebase → projet ${PROJET_AUTORISE} → Paramètres du projet\n` +
      '  → Comptes de service → « Générer une nouvelle clé privée »\n\n' +
      `Enregistrez ensuite le fichier téléchargé sous :\n  ${CHEMIN_CLE_PAR_DEFAUT}\n\n` +
      'Cette clé ne doit JAMAIS entrer dans le dépôt Git (voir .gitignore).',
  );
}

function chargerCle(chemin) {
  let brut;
  try {
    brut = fs.readFileSync(chemin, 'utf8');
  } catch (e) {
    abandonner(`impossible de lire la clé : ${chemin}`, e.message);
  }

  try {
    return JSON.parse(brut);
  } catch (e) {
    abandonner(
      `la clé n'est pas un JSON valide : ${chemin}`,
      `${e.message}\n\nLe fichier attendu est la clé privée générée par la console Firebase.`,
    );
  }
}

// --- Chargement et validation des données ---------------------------------

function chargerDonnees() {
  let brut;
  try {
    brut = fs.readFileSync(CHEMIN_DONNEES, 'utf8');
  } catch (e) {
    abandonner(`impossible de lire ${CHEMIN_DONNEES}`, e.message);
  }

  try {
    return JSON.parse(brut);
  } catch (e) {
    abandonner(`referentiel.json n'est pas un JSON valide`, e.message);
  }
}

/**
 * Contrôles de cohérence effectués AVANT toute écriture : mieux vaut échouer
 * sur un fichier mal édité que semer un référentiel incohérent.
 */
function validerDonnees(data) {
  const erreurs = [];

  const idsEtablissements = new Set();
  const idsUnites = new Set();
  const idsUsagers = new Set();

  const verifierIdsUniques = (liste, nomBloc, vus) => {
    for (const item of liste) {
      if (!item.id) erreurs.push(`${nomBloc} : une entrée n'a pas d'id.`);
      else if (vus.has(item.id)) erreurs.push(`${nomBloc} : id en double « ${item.id} ».`);
      else vus.add(item.id);
    }
  };

  verifierIdsUniques(data.etablissements, 'etablissements', idsEtablissements);
  verifierIdsUniques(data.unites, 'unites', idsUnites);
  verifierIdsUniques(data.usagers, 'usagers', idsUsagers);

  for (const unite of data.unites) {
    if (!idsEtablissements.has(unite.etablissementId)) {
      erreurs.push(`unites/${unite.id} : etablissementId inconnu « ${unite.etablissementId} ».`);
    }
  }

  for (const usager of data.usagers) {
    if (!idsUnites.has(usager.uniteId)) {
      erreurs.push(`usagers/${usager.id} : uniteId inconnu « ${usager.uniteId} ».`);
    }
    if (!idsEtablissements.has(usager.etablissementId)) {
      erreurs.push(`usagers/${usager.id} : etablissementId inconnu « ${usager.etablissementId} ».`);
    }
  }

  // Répartition attendue, telle que déclarée dans referentiel.json.
  const reel = compterParUnite(data.usagers);
  for (const [uniteId, attendu] of Object.entries(data.repartitionAttendue)) {
    const compte = reel[uniteId] || 0;
    if (compte !== attendu) {
      erreurs.push(
        `répartition : ${uniteId} contient ${compte} usager(s), ${attendu} attendu(s).`,
      );
    }
  }

  if (erreurs.length > 0) {
    abandonner(
      'referentiel.json est incohérent, aucune écriture effectuée.',
      erreurs.map((e) => `  • ${e}`).join('\n'),
    );
  }
}

function compterParUnite(usagers) {
  const compte = {};
  for (const usager of usagers) {
    compte[usager.uniteId] = (compte[usager.uniteId] || 0) + 1;
  }
  return compte;
}

// --- Construction des documents -------------------------------------------

/**
 * `dateCreation` est délibérément absente de ces charges utiles : elle est
 * ajoutée uniquement à la création, jamais lors d'un rejeu (voir semer()).
 */

function documentEtablissement(etab) {
  return { nom: etab.nom };
}

function documentUnite(unite) {
  return {
    nom: unite.nom,
    etablissementId: unite.etablissementId,
    ordre: unite.ordre,
  };
}

/**
 * Un usager peut surcharger `consentImage` pour servir de cas de test.
 *
 * Chantier R3b — six usagers portent un consentement volontairement
 * différencié (tout accepté / tout refusé / mixte / jamais répondu), qui
 * couvre les trois états du badge. Ils vivaient auparavant dans
 * `mockUsagersCatalogue`, et y portaient un vrai uid Firebase dans
 * `saisiPar` ; le JSON étant versionné, `saisiPar` y reste TOUJOURS `null`.
 *
 * `dateConsentement` s'exprime en nombre de jours **relatif à aujourd'hui**
 * (`dateConsentementJoursAvant`), jamais en date calendaire : une date figée
 * vieillirait dans le dépôt et finirait par décrire un consentement recueilli
 * « il y a trois ans ». Même convention que les dates relatives du mock.
 */
function documentUsager(usager, defauts) {
  const surcharge = usager.consentImage;
  let consentImage = { ...defauts.consentImage };

  if (surcharge) {
    const { dateConsentementJoursAvant, ...reste } = surcharge;
    consentImage = { ...consentImage, ...reste, saisiPar: null };

    if (typeof dateConsentementJoursAvant === 'number') {
      const d = new Date();
      d.setDate(d.getDate() - dateConsentementJoursAvant);
      consentImage.dateConsentement = admin.firestore.Timestamp.fromDate(d);
    }
  }

  return {
    prenom: usager.prenom,
    nom: usager.nom,
    uniteId: usager.uniteId,
    etablissementId: usager.etablissementId,
    anneeNaissance: usager.anneeNaissance,
    photoUrl: defauts.photoUrl,
    actif: defauts.actif,
    consentImage,
  };
}

/** Comparaison profonde limitée aux types présents dans le référentiel. */
function memeValeur(a, b) {
  if (a === b) return true;
  if (a === null || b === null) return false;
  if (typeof a !== 'object' || typeof b !== 'object') return false;

  const clesA = Object.keys(a);
  const clesB = Object.keys(b);
  if (clesA.length !== clesB.length) return false;
  return clesA.every((cle) => Object.prototype.hasOwnProperty.call(b, cle) && memeValeur(a[cle], b[cle]));
}

/** Vrai si tous les champs de `charge` sont déjà à l'identique en base. */
function dejaAJour(existant, charge) {
  return Object.keys(charge).every((cle) => memeValeur(existant[cle], charge[cle]));
}

// --- Écriture -------------------------------------------------------------

/**
 * [champsCreationSeule] : champs posés à la création du document et **jamais
 * réécrits ensuite**, sur le modèle de `dateCreation`.
 *
 * Chantier R3b — c'est `consentImage` qui l'impose, et le motif n'est pas
 * l'esthétique. Depuis R3b, une famille écrit réellement ce champ depuis
 * l'app. Or ce script est rejoué à chaque rentrée pour resynchroniser
 * l'effectif : sans cette protection, un rejeu réécrirait `consentImage` avec
 * la valeur du JSON et **effacerait les consentements donnés par les
 * familles** — remise à `false` des 49 usagers sans cas de test, et écrasement
 * des 6 autres. Une donnée que seule la famille peut produire ne doit jamais
 * être réécrite par un outil d'administration.
 *
 * Effet de bord utile : l'idempotence est préservée. `dateConsentement` étant
 * relative à la date d'exécution, l'inclure dans la comparaison ferait
 * signaler six modifications à chaque rejeu.
 *
 * C'est une **fonction** de l'entrée, et non une liste fixe : la protection
 * peut se lever pour certains usagers et pas pour d'autres (voir
 * `--forcer-consentement`).
 */
async function semer(firestore, nomCollection, entrees, construireDocument, champsCreationSeule = () => []) {
  const collection = firestore.collection(nomCollection);

  // Une seule lecture par collection plutôt qu'un get() par document : moins
  // d'appels, et permet au passage de repérer les documents orphelins.
  const instantane = await collection.get();
  const existants = new Map();
  instantane.forEach((doc) => existants.set(doc.id, doc.data()));

  const bilan = { crees: 0, modifies: 0, inchanges: 0 };
  const batch = firestore.batch();
  let operations = 0;

  for (const entree of entrees) {
    const chargeComplete = construireDocument(entree);
    const existant = existants.get(entree.id);

    if (!existant) {
      batch.set(collection.doc(entree.id), {
        ...chargeComplete,
        dateCreation: admin.firestore.FieldValue.serverTimestamp(),
      });
      operations += 1;
      bilan.crees += 1;
      continue;
    }

    // Document déjà en base : on écarte les champs qui ne se posent qu'à la
    // création, pour ne jamais écraser ce que l'app y a écrit depuis.
    const charge = { ...chargeComplete };
    for (const champ of champsCreationSeule(entree)) delete charge[champ];

    if (dejaAJour(existant, charge)) {
      bilan.inchanges += 1;
      continue;
    }

    // merge: true, et `dateCreation` absente de la charge : la valeur déjà
    // en base est préservée telle quelle.
    batch.set(collection.doc(entree.id), charge, { merge: true });
    operations += 1;
    bilan.modifies += 1;
  }

  if (operations > 0) await batch.commit();

  const orphelins = [...existants.keys()].filter(
    (id) => !entrees.some((entree) => entree.id === id),
  );

  return { bilan, orphelins };
}

// --- Contrôle de cohérence post-écriture ----------------------------------

async function controlerRepartition(firestore, repartitionAttendue) {
  const instantane = await firestore.collection('usagers').get();
  const usagers = instantane.docs.map((doc) => doc.data());
  const reel = compterParUnite(usagers);

  const ecarts = [];
  const uniteIds = new Set([...Object.keys(repartitionAttendue), ...Object.keys(reel)]);

  for (const uniteId of [...uniteIds].sort()) {
    const attendu = repartitionAttendue[uniteId];
    const compte = reel[uniteId] || 0;

    if (attendu === undefined) {
      ecarts.push(`${uniteId} : ${compte} usager(s) en base, unité non prévue par la répartition.`);
      continue;
    }
    if (compte !== attendu) {
      ecarts.push(`${uniteId} : ${compte} usager(s) en base, ${attendu} attendu(s).`);
      continue;
    }
    succes(`${uniteId} : ${compte} usagers (attendu ${attendu})`);
  }

  info(`total : ${usagers.length} usagers`);

  if (ecarts.length > 0) {
    abandonner(
      'contrôle de cohérence en échec — le référentiel en base ne correspond pas à la répartition attendue.',
      ecarts.map((e) => `  • ${e}`).join('\n'),
    );
  }
}

// --- Programme principal --------------------------------------------------

async function principal() {
  titre('Relio — seed du référentiel');

  const { chemin, origine } = resoudreCheminCle();
  const cle = chargerCle(chemin);
  info(`clé : ${chemin} (${origine})`);

  // GARDE-FOU ANTI-PRODUCTION — avant toute connexion, donc avant toute
  // écriture possible. Le projectId est lu dans la clé elle-même.
  if (cle.project_id !== PROJET_AUTORISE) {
    abandonner(
      `cette clé cible le projet « ${cle.project_id } », et non « ${PROJET_AUTORISE} ».`,
      'Ce script écrit exclusivement sur le projet de développement.\n' +
        'Le SDK Admin contourne intégralement firestore.rules : une écriture\n' +
        'accidentelle sur la production serait irréversible.\n\n' +
        'Aucun flag ne permet de contourner ce contrôle. Vérifiez la clé utilisée.',
    );
  }
  succes(`projet cible : ${cle.project_id}`);

  const data = chargerDonnees();
  validerDonnees(data);
  succes('referentiel.json validé');

  if (FORCER_CONSENTEMENT) {
    const cibles = data.usagers.filter((u) => u.consentImage).map((u) => u.id);
    alerte(
      `--forcer-consentement : ${cibles.length} usager(s) verront leur consentImage RÉÉCRIT ` +
        `(${cibles.join(', ')}).`,
    );
    alerte(
      'Les autres usagers conservent le leur. À n\'utiliser que pour réinstaller les cas de test.',
    );
  }

  admin.initializeApp({ credential: admin.credential.cert(cle) });
  const firestore = admin.firestore();

  // Seconde vérification, après initialisation : le projectId effectif de
  // l'application doit lui aussi correspondre.
  const projetEffectif = admin.app().options?.credential?.projectId || cle.project_id;
  if (projetEffectif !== PROJET_AUTORISE) {
    abandonner(`projet effectif inattendu après initialisation : « ${projetEffectif} ».`);
  }

  titre('Écriture');
  const resultats = {
    etablissements: await semer(firestore, 'etablissements', data.etablissements, documentEtablissement),
    unites: await semer(firestore, 'unites', data.unites, documentUnite),
    usagers: await semer(
      firestore,
      'usagers',
      data.usagers,
      (usager) => documentUsager(usager, data.defautsUsager),
      // Par défaut, `consentImage` n'est jamais réécrit sur un document
      // existant. `--forcer-consentement` lève cette protection pour les SEULS
      // usagers porteurs d'une fixture explicite dans le JSON : les autres
      // conservent leur consentement dans tous les cas, y compris avec le
      // drapeau. Voir FORCER_CONSENTEMENT.
      (usager) =>
        FORCER_CONSENTEMENT && usager.consentImage ? [] : ['consentImage'],
    ),
  };

  for (const [nom, { bilan, orphelins }] of Object.entries(resultats)) {
    info(
      `${nom.padEnd(16)} ${String(bilan.crees).padStart(3)} créé(s)   ` +
        `${String(bilan.modifies).padStart(3)} modifié(s)   ` +
        `${String(bilan.inchanges).padStart(3)} inchangé(s)`,
    );
    if (orphelins.length > 0) {
      alerte(
        `${nom} : ${orphelins.length} document(s) en base absent(s) de referentiel.json ` +
          `(${orphelins.join(', ')}) — non supprimé(s), le seed n'efface jamais.`,
      );
    }
  }

  titre('Contrôle de cohérence');
  await controlerRepartition(firestore, data.repartitionAttendue);

  console.log('\n\x1b[32mSeed terminé.\x1b[0m\n');
}

principal().catch((e) => {
  abandonner('erreur inattendue.', e && e.stack ? e.stack : String(e));
});
