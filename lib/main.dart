import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'utils/messages_globaux.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Storage ne renonce jamais de lui-même dans un délai qu'un humain tolère :
  // par défaut le SDK réessaie **jusqu'à 10 minutes** avant de faire remonter
  // un échec d'envoi. Pendant tout ce temps l'écran tourne sans rien dire —
  // c'est exactement le piège rencontré côté Firestore en R3a, qui avait donné
  // `delaiMaxLecture`, sur un autre produit.
  //
  // Ce délai borne les **reprises après échec**, pas la durée d'un transfert
  // qui progresse : un envoi lent mais qui avance n'est pas interrompu.
  //
  // Réglage global du SDK, donc ici et pas dans un service métier.
  FirebaseStorage.instance.setMaxUploadRetryTime(const Duration(seconds: 30));
  FirebaseStorage.instance.setMaxOperationRetryTime(const Duration(seconds: 30));

  runApp(const RelioApp());
}

class RelioApp extends StatelessWidget {
  const RelioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relio',
      // Permet d'annoncer le résultat d'une opération longue même si l'écran
      // qui l'a lancée a été quitté entre-temps — voir `messages_globaux.dart`.
      scaffoldMessengerKey: messengerRelioKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
