import 'package:flutter/material.dart';

import '../ble/condor_ble_service.dart';
import '../data/local_progress_repository.dart';
import '../models/character.dart';
import '../models/level_config.dart';
import '../widgets/character_portrait.dart';
import '../widgets/time_text.dart';
import 'ble_screen.dart';
import 'game_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository, required this.ble});
  final LocalProgressRepository repository;
  final CondorBleService ble;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentTab = 0;

  void openGame(LevelConfig level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          level: level,
          repository: widget.repository,
          ble: widget.ble,
        ),
      ),
    );
  }

  LevelConfig get nextLevel {
    final levelId = widget.repository.nextLevelId;
    if (levelId == 0) return LevelConfig.tutorial;
    return LevelConfig.levels.firstWhere((level) => level.id == levelId);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([widget.repository, widget.ble]),
        builder: (context, _) {
          final titles = ['Inicio', 'Ruta por Ecuador', 'Tienda de aves'];
          return Scaffold(
            appBar: AppBar(
              title: Text(titles[currentTab]),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: ActionChip(
                    avatar: const Icon(Icons.toll_rounded, size: 19),
                    label: Text(
                      '${widget.repository.profile?.coins ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: () => setState(() => currentTab = 2),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: widget.ble.status,
                  icon: Icon(
                    widget.ble.isConnected
                        ? Icons.bluetooth_connected_rounded
                        : widget.ble.isDemoMode
                            ? Icons.science_outlined
                            : Icons.bluetooth_disabled_rounded,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => BleScreen(ble: widget.ble)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: IndexedStack(
              index: currentTab,
              children: [
                _Dashboard(
                  repository: widget.repository,
                  nextLevel: nextLevel,
                  onPlay: () => openGame(nextLevel),
                  onOpenRoute: () => setState(() => currentTab = 1),
                  onOpenShop: () => setState(() => currentTab = 2),
                ),
                _LevelsView(
                    repository: widget.repository, onOpenLevel: openGame),
                ShopScreen(repository: widget.repository),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: currentTab,
              onDestinationSelected: (index) =>
                  setState(() => currentTab = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: Icon(Icons.route_outlined),
                  selectedIcon: Icon(Icons.route_rounded),
                  label: 'Ruta',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shopping_bag_outlined),
                  selectedIcon: Icon(Icons.shopping_bag_rounded),
                  label: 'Tienda',
                ),
              ],
            ),
          );
        },
      );
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.repository,
    required this.nextLevel,
    required this.onPlay,
    required this.onOpenRoute,
    required this.onOpenShop,
  });

  final LocalProgressRepository repository;
  final LevelConfig nextLevel;
  final VoidCallback onPlay;
  final VoidCallback onOpenRoute;
  final VoidCallback onOpenShop;

  @override
  Widget build(BuildContext context) {
    final selectedName = repository.profile?.selectedCharacter ?? 'condor';
    final selected = Character.values.firstWhere(
      (character) => character.name == selectedName,
      orElse: () => Character.condor,
    );
    final progress = repository.completedLevels / LevelConfig.levels.length;
    final isTutorial = nextLevel.id == 0;

    return ListView(
      key: const PageStorageKey('dashboard'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'Hola, ${repository.profile?.name ?? ''}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Tu próxima aventura está lista.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff0e5966), Color(0xff173f4b)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff173f4b).withValues(alpha: .22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              CharacterPortrait(character: selected, size: 100),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTutorial
                          ? 'Comienza tu viaje'
                          : 'Nivel ${nextLevel.id}',
                      style: const TextStyle(
                        color: Color(0xffffd166),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nextLevel.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xffffd166),
                        foregroundColor: const Color(0xff1d302f),
                      ),
                      onPressed: onPlay,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        isTutorial ? 'Hacer tutorial' : 'Jugar ahora',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.local_fire_department_rounded,
                value: '${repository.profile?.dailyStreak ?? 0}',
                label: 'Días de racha',
                color: const Color(0xffef6b4a),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.flag_rounded,
                value: '${repository.completedLevels}/9',
                label: 'Niveles',
                color: const Color(0xff0f8b72),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tu ruta',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: onOpenRoute,
              child: const Text('Ver niveles'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recorrido por Ecuador',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text('${(progress * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(99),
                ),
                const SizedBox(height: 10),
                Text(
                  repository.tutorialCompleted
                      ? 'Sigue avanzando para habilitar nuevas aves en la tienda.'
                      : 'Completa el tutorial para abrir el primer nivel.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tu bandada',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: onOpenShop,
              child: const Text('Ir a la tienda'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: Character.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final character = Character.values[index];
              final owned = repository.isCharacterOwned(character);
              final isSelected = character == selected;
              return InkWell(
                onTap: owned
                    ? () => repository.selectCharacter(character)
                    : onOpenShop,
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 92,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      CharacterPortrait(
                        character: character,
                        size: 58,
                        locked: !owned,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        character.displayName.split(' ').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _LevelsView extends StatelessWidget {
  const _LevelsView({required this.repository, required this.onOpenLevel});

  final LocalProgressRepository repository;
  final ValueChanged<LevelConfig> onOpenLevel;

  @override
  Widget build(BuildContext context) => CustomScrollView(
        key: const PageStorageKey('levels'),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading:
                      const CircleAvatar(child: Icon(Icons.school_outlined)),
                  title: const Text(
                    'Tutorial inicial',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    repository.tutorialCompleted
                        ? 'Completado · puedes repetirlo y ganar 8 monedas'
                        : 'Aprende a cargar y saltar con el control',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => onOpenLevel(LevelConfig.tutorial),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisExtent: 176,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final level = LevelConfig.levels[index];
                final unlocked = repository.isUnlocked(level.id);
                final best = repository.bestTimes[level.id];
                final colors = switch (level.theme) {
                  LevelTheme.andes => const [
                      Color(0xffdce9e3),
                      Color(0xffc9ddd2)
                    ],
                  LevelTheme.coast => const [
                      Color(0xffffe3a3),
                      Color(0xfffff0c7)
                    ],
                  LevelTheme.amazon => const [
                      Color(0xffcce5c7),
                      Color(0xffe0efcf)
                    ],
                  LevelTheme.sunset => const [
                      Color(0xffffc5aa),
                      Color(0xffffe0c9)
                    ],
                };

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: unlocked
                            ? colors
                            : [Colors.grey.shade200, Colors.grey.shade100],
                      ),
                    ),
                    child: InkWell(
                      onTap: unlocked ? () => onOpenLevel(level) : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .72),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${level.id}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  unlocked
                                      ? Icons.landscape_rounded
                                      : Icons.lock_outline_rounded,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              level.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              best != null
                                  ? 'Mejor: ${formatDuration(best)}'
                                  : unlocked
                                      ? 'Recompensa: ${repository.rewardForLevel(level.id, firstCompletion: true)} monedas'
                                      : 'Completa el nivel anterior',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: LevelConfig.levels.length),
            ),
          ),
        ],
      );
}
