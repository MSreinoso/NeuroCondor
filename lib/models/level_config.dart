enum LevelDifficulty { tutorial, easy, medium, hard }

enum LevelTheme { andes, coast, amazon, sunset }

class PlatformSpec {
  const PlatformSpec({
    required this.x,
    required this.width,
    this.y = 0.72,
    this.hasSpikes = false,
    this.isMoving = false,
    this.moveRange = 0,
    this.moveSpeed = 0,
  });

  final double x;
  final double width;
  final double y;
  final bool hasSpikes;
  final bool isMoving;
  final double moveRange;
  final double moveSpeed;
}

class LevelConfig {
  const LevelConfig({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.platforms,
    this.theme = LevelTheme.andes,
  });

  final int id;
  final String title;
  final LevelDifficulty difficulty;
  final LevelTheme theme;
  final List<PlatformSpec> platforms;

  static const tutorial = LevelConfig(
    id: 0,
    title: 'Tutorial',
    difficulty: LevelDifficulty.tutorial,
    platforms: [
      PlatformSpec(x: 0.04, width: 0.25),
      PlatformSpec(x: 0.48, width: 0.30),
    ],
  );

  static const levels = <LevelConfig>[
    LevelConfig(
      id: 1,
      title: 'Valle sereno',
      difficulty: LevelDifficulty.easy,
      platforms: [
        PlatformSpec(x: .03, width: .22),
        PlatformSpec(x: .36, width: .25),
        PlatformSpec(x: .72, width: .24),
      ],
    ),
    LevelConfig(
      id: 2,
      title: 'Brisa andina',
      difficulty: LevelDifficulty.easy,
      platforms: [
        PlatformSpec(x: .03, width: .20),
        PlatformSpec(x: .34, width: .18, y: .66),
        PlatformSpec(x: .65, width: .29),
      ],
    ),
    LevelConfig(
      id: 3,
      title: 'Cielo claro',
      difficulty: LevelDifficulty.easy,
      platforms: [
        PlatformSpec(x: .03, width: .19),
        PlatformSpec(x: .31, width: .17),
        PlatformSpec(x: .58, width: .15, y: .65),
        PlatformSpec(x: .82, width: .15),
      ],
    ),
    LevelConfig(
      id: 4,
      title: 'Pico espinoso',
      difficulty: LevelDifficulty.medium,
      theme: LevelTheme.coast,
      platforms: [
        PlatformSpec(x: .03, width: .22),
        PlatformSpec(x: .36, width: .25, hasSpikes: true),
        PlatformSpec(x: .74, width: .22),
      ],
    ),
    LevelConfig(
      id: 5,
      title: 'Paso del sol',
      difficulty: LevelDifficulty.medium,
      theme: LevelTheme.coast,
      platforms: [
        PlatformSpec(x: .03, width: .20),
        PlatformSpec(x: .32, width: .22, y: .66, hasSpikes: true),
        PlatformSpec(x: .66, width: .16),
        PlatformSpec(x: .88, width: .10),
      ],
    ),
    LevelConfig(
      id: 6,
      title: 'Risco dorado',
      difficulty: LevelDifficulty.medium,
      theme: LevelTheme.amazon,
      platforms: [
        PlatformSpec(x: .03, width: .18),
        PlatformSpec(x: .30, width: .18, hasSpikes: true),
        PlatformSpec(x: .58, width: .17, hasSpikes: true),
        PlatformSpec(x: .84, width: .13),
      ],
    ),
    LevelConfig(
      id: 7,
      title: 'Viento cambiante',
      difficulty: LevelDifficulty.hard,
      theme: LevelTheme.amazon,
      platforms: [
        PlatformSpec(x: .03, width: .19),
        PlatformSpec(
          x: .34,
          width: .19,
          isMoving: true,
          moveRange: .06,
          moveSpeed: .55,
        ),
        PlatformSpec(x: .68, width: .26, hasSpikes: true),
      ],
    ),
    LevelConfig(
      id: 8,
      title: 'Cumbres vivas',
      difficulty: LevelDifficulty.hard,
      theme: LevelTheme.sunset,
      platforms: [
        PlatformSpec(x: .03, width: .18),
        PlatformSpec(
          x: .31,
          width: .17,
          isMoving: true,
          moveRange: .07,
          moveSpeed: .75,
        ),
        PlatformSpec(x: .59, width: .16, hasSpikes: true),
        PlatformSpec(x: .84, width: .13),
      ],
    ),
    LevelConfig(
      id: 9,
      title: 'Dominio del cielo',
      difficulty: LevelDifficulty.hard,
      theme: LevelTheme.sunset,
      platforms: [
        PlatformSpec(x: .03, width: .17),
        PlatformSpec(
          x: .28,
          width: .15,
          isMoving: true,
          moveRange: .06,
          moveSpeed: .85,
        ),
        PlatformSpec(x: .53, width: .14, hasSpikes: true),
        PlatformSpec(
          x: .76,
          width: .14,
          isMoving: true,
          moveRange: .05,
          moveSpeed: 1.0,
        ),
      ],
    ),
  ];
}
