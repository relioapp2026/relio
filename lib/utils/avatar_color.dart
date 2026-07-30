import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Palette des avatars d'usager.
///
/// **L'ordre n'est pas arbitraire et ne doit pas être « remis dans l'ordre de
/// la charte ».** Il est choisi pour que [avatarColorPourUsager] reproduise
/// exactement les couleurs qu'affichait le catalogue mock (`MockUsager.
/// avatarColor`) pour `usager_001` à `usager_035` — les seuls usagers ayant
/// été validés visuellement avant le chantier Référentiel. Changer cet ordre
/// change la couleur de tous les avatars de l'app.
const _palette = [
  AppColors.roseViolet,
  AppColors.marine,
  AppColors.turquoise,
];

/// Couleur d'avatar d'un usager, dérivée de son id.
///
/// Chantier Référentiel / R3a. Le schéma Firestore `usagers` ne porte **pas**
/// de champ `avatarColor` (décision R1 : une couleur d'affichage n'a rien à
/// faire en base). La couleur est donc calculée, et non stockée.
///
/// Contrat : **même id, même couleur**, à chaque appel, sur chaque appareil et
/// sur chaque plateforme. Sans ça, les avatars changeraient de teinte à chaque
/// lancement de l'app.
///
/// ### Pourquoi une simple somme, et pas un hachage multiplicatif
///
/// Un hachage classique (`h = h * 31 + c`) dépasse vite la plage des entiers
/// exacts en JavaScript, où les `int` Dart sont des `double` : le même id
/// donnerait alors une couleur sur Android et une autre sur le Web, qui est
/// une cible de compilation du MVP. La somme des unités de code reste sous
/// 2 500 pour un id Firestore de 20 caractères — exacte partout, donc
/// réellement déterministe.
///
/// La qualité de dispersion d'une somme est médiocre dans l'absolu, mais sans
/// conséquence ici : il s'agit de répartir des ids quasi séquentiels sur trois
/// teintes décoratives, pas de construire un index.
Color avatarColorPourUsager(String usagerId) {
  var somme = 0;
  for (var i = 0; i < usagerId.length; i++) {
    somme += usagerId.codeUnitAt(i);
  }
  return _palette[somme % _palette.length];
}
