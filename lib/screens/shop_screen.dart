import 'package:flutter/material.dart';

import '../data/local_progress_repository.dart';
import '../models/character.dart';
import '../widgets/character_portrait.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.repository});
  final LocalProgressRepository repository;

  Future<void> _purchase(BuildContext context, Character character) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CharacterPortrait(character: character, size: 104),
              const SizedBox(height: 16),
              Text(
                character.displayName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                character.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.toll_rounded),
                  label: Text('Desbloquear por ${character.price}'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ahora no'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await repository.purchaseCharacter(character);
    if (!context.mounted) return;
    final message = switch (result) {
      CharacterPurchaseResult.purchased =>
        '¡${character.displayName} se unió a tu bandada!',
      CharacterPurchaseResult.alreadyOwned => 'Este personaje ya es tuyo.',
      CharacterPurchaseResult.levelLocked =>
        'Completa el nivel ${character.requiredLevel} para desbloquearlo.',
      CharacterPurchaseResult.insufficientCoins =>
        'Aún no tienes suficientes monedas.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = repository.profile?.coins ?? 0;
    return CustomScrollView(
      key: const PageStorageKey('shop'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffffd166), Color(0xffffb547)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.toll_rounded, size: 38),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tu saldo'),
                        Text(
                          '$balance monedas',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Text('Completa niveles para ganar más.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) => SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 330,
                mainAxisExtent: constraints.crossAxisExtent < 400 ? 336 : 312,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final character = Character.values[index];
                final owned = repository.isCharacterOwned(character);
                final levelReady = repository.meetsCharacterLevel(character);
                final selected =
                    repository.profile?.selectedCharacter == character.name;
                final affordable = balance >= character.price;

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CharacterPortrait(
                              character: character,
                              size: 76,
                              locked: !owned && !levelReady,
                            ),
                            const Spacer(),
                            if (selected)
                              const Chip(
                                avatar: Icon(Icons.check_circle, size: 18),
                                label: Text('En uso'),
                              )
                            else if (!owned)
                              Chip(
                                avatar:
                                    const Icon(Icons.toll_rounded, size: 18),
                                label: Text('${character.price}'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          character.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          character.region,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            character.description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: owned
                              ? OutlinedButton.icon(
                                  onPressed: selected
                                      ? null
                                      : () =>
                                          repository.selectCharacter(character),
                                  icon: Icon(
                                    selected ? Icons.check : Icons.flutter_dash,
                                  ),
                                  label: Text(
                                    selected
                                        ? 'Seleccionado'
                                        : 'Usar personaje',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : FilledButton.icon(
                                  onPressed: levelReady && affordable
                                      ? () => _purchase(context, character)
                                      : null,
                                  icon: Icon(
                                    !levelReady
                                        ? Icons.lock_outline_rounded
                                        : Icons.shopping_bag_outlined,
                                  ),
                                  label: Text(
                                    !levelReady
                                        ? 'Completa nivel ${character.requiredLevel}'
                                        : affordable
                                            ? 'Desbloquear'
                                            : 'Faltan ${character.price - balance}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: Character.values.length),
            ),
          ),
        ),
      ],
    );
  }
}
