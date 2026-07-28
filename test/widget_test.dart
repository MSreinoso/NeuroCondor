import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_condor/app.dart';
import 'package:neuro_condor/data/local_progress_repository.dart';
import 'package:neuro_condor/models/character.dart';
import 'package:neuro_condor/widgets/character_portrait.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('muestra el registro en el primer inicio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalProgressRepository();
    await repository.load();

    await tester.pumpWidget(NeuroCondorApp(repository: repository));

    expect(find.text('Neuro Cóndor'), findsOneWidget);
    expect(find.text('Comenzar viaje'), findsOneWidget);
    expect(find.text('Nombre del participante'), findsOneWidget);
  });

  testWidgets('renderiza los ocho personajes sin errores', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final character in Character.values)
                CharacterPortrait(character: character, size: 100),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CharacterPortrait), findsNWidgets(8));
    expect(tester.takeException(), isNull);
  });
}
