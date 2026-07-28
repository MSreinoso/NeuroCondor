import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_condor/data/local_progress_repository.dart';
import 'package:neuro_condor/models/character.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('registra, recompensa y compra un personaje de forma persistente',
      () async {
    final repository = LocalProgressRepository();
    await repository.load();
    await repository.register('Ana');

    expect(repository.profile!.coins, 30);
    expect(
      await repository.purchaseCharacter(Character.piquero),
      CharacterPurchaseResult.levelLocked,
    );

    final tutorialReward =
        await repository.completeLevel(0, const Duration(seconds: 20));
    final levelReward =
        await repository.completeLevel(1, const Duration(seconds: 30));
    expect(tutorialReward, 30);
    expect(levelReward, 30);

    expect(
      await repository.purchaseCharacter(Character.piquero),
      CharacterPurchaseResult.purchased,
    );
    expect(repository.isCharacterOwned(Character.piquero), isTrue);
    expect(repository.profile!.coins, 30);

    final restored = LocalProgressRepository();
    await restored.load();
    expect(restored.isCharacterOwned(Character.piquero), isTrue);
    expect(restored.profile!.coins, 30);
  });

  test('repetir un nivel entrega menos monedas que completarlo por primera vez',
      () async {
    final repository = LocalProgressRepository();
    await repository.register('Luis');

    final first =
        await repository.completeLevel(2, const Duration(seconds: 40));
    final repeated =
        await repository.completeLevel(2, const Duration(seconds: 35));

    expect(first, 33);
    expect(repeated, 18);
    expect(repository.bestTimes[2], const Duration(seconds: 35));
  });
}
