import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_condor/app.dart';
import 'package:neuro_condor/ble/condor_ble_service.dart';
import 'package:neuro_condor/data/local_progress_repository.dart';
import 'package:neuro_condor/models/level_config.dart';
import 'package:neuro_condor/screens/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<LocalProgressRepository> registeredRepository() async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalProgressRepository();
    await repository.load();
    await repository.register('Participante de prueba');
    return repository;
  }

  void usePhoneViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
  }

  testWidgets('las pestañas principales no se superponen en teléfono estrecho',
      (tester) async {
    usePhoneViewport(tester);
    final repository = await registeredRepository();

    await tester.pumpWidget(NeuroCondorApp(repository: repository));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Ruta').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tienda').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.bluetooth_disabled_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('registro y controles de juego caben en 320 por 568',
      (tester) async {
    usePhoneViewport(tester);

    SharedPreferences.setMockInitialValues({});
    final emptyRepository = LocalProgressRepository();
    await emptyRepository.load();
    await tester.pumpWidget(NeuroCondorApp(repository: emptyRepository));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final repository = await registeredRepository();
    final ble = CondorBleService()..enableDemoMode();
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          level: LevelConfig.tutorial,
          repository: repository,
          ble: ble,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    ble.dispose();
  });
}
