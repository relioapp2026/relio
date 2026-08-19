import 'package:flutter/material.dart';

/// Clé du `ScaffoldMessenger` racine, posée sur `MaterialApp`.
///
/// Sert à afficher un message qui **ne dépend d'aucun écran en particulier**.
///
/// Motif, appris le 2026-08-19 : un échec d'envoi de photos remontait bien
/// jusqu'à l'écran de création, mais celui-ci était déjà fermé (le SDK Storage
/// avait réessayé pendant plusieurs minutes, l'utilisateur avait quitté entre
/// temps). Le `if (!mounted) return;` qui précédait l'affichage supprimait alors
/// le message purement et simplement : la publication partait sans ses photos,
/// et personne n'était prévenu.
///
/// `ScaffoldMessenger.of(context)` reste le bon choix quand l'écran est
/// forcément vivant au moment du message. Cette clé est pour l'autre cas :
/// une opération longue dont le résultat doit être annoncé même si l'écran qui
/// l'a lancée n'existe plus.
final GlobalKey<ScaffoldMessengerState> messengerRelioKey =
    GlobalKey<ScaffoldMessengerState>();

/// Affiche [message] sur l'écran actuellement visible, quel qu'il soit.
///
/// Sans effet si l'application n'est plus montée du tout (processus tué en
/// cours d'opération) — limite assumée, voir CLAUDE.md, « Publications étape 2 ».
void afficherMessageGlobal(
  String message, {
  Duration duree = const Duration(seconds: 4),
}) {
  messengerRelioKey.currentState?.showSnackBar(
    SnackBar(content: Text(message), duration: duree),
  );
}
