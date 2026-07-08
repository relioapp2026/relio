import 'package:flutter_test/flutter_test.dart';

import 'package:relio/main.dart';

void main() {
  testWidgets('Login screen affiche les champs email et mot de passe',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RelioApp());

    expect(find.text('Relio'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
  });
}
