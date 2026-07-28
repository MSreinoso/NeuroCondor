import 'package:flutter_test/flutter_test.dart';
import 'package:neuro_condor/models/level_config.dart';

void main() {
  test('hay tres niveles por dificultad', () {
    expect(
      LevelConfig.levels.where((l) => l.difficulty == LevelDifficulty.easy),
      hasLength(3),
    );
    expect(
      LevelConfig.levels.where((l) => l.difficulty == LevelDifficulty.medium),
      hasLength(3),
    );
    expect(
      LevelConfig.levels.where((l) => l.difficulty == LevelDifficulty.hard),
      hasLength(3),
    );
  });

  test(
    'los niveles medios tienen espinas y los difíciles movimiento y espinas',
    () {
      final medium = LevelConfig.levels.where(
        (l) => l.difficulty == LevelDifficulty.medium,
      );
      final hard = LevelConfig.levels.where(
        (l) => l.difficulty == LevelDifficulty.hard,
      );
      expect(medium.every((l) => l.platforms.any((p) => p.hasSpikes)), isTrue);
      expect(
        hard.every(
          (l) =>
              l.platforms.any((p) => p.hasSpikes) &&
              l.platforms.any((p) => p.isMoving),
        ),
        isTrue,
      );
    },
  );
}
