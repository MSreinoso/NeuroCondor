class UserProfile {
  const UserProfile({
    required this.name,
    required this.createdAt,
    this.selectedCharacter = 'condor',
    this.coins = 30,
    this.dailyStreak = 0,
    this.lastActivityDate,
    this.ownedCharacters = const ['condor'],
  });

  final String name;
  final DateTime createdAt;
  final String selectedCharacter;
  final int coins;
  final int dailyStreak;
  final DateTime? lastActivityDate;
  final List<String> ownedCharacters;

  UserProfile copyWith({
    String? name,
    DateTime? createdAt,
    String? selectedCharacter,
    int? coins,
    int? dailyStreak,
    DateTime? lastActivityDate,
    List<String>? ownedCharacters,
  }) {
    return UserProfile(
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
      coins: coins ?? this.coins,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      ownedCharacters: ownedCharacters ?? this.ownedCharacters,
    );
  }

  Map<String, Object> toJson() => {
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'selectedCharacter': selectedCharacter,
        'coins': coins,
        'dailyStreak': dailyStreak,
        'ownedCharacters': ownedCharacters,
        if (lastActivityDate != null)
          'lastActivityDate': lastActivityDate!.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, Object?> json) {
    final selected = (json['selectedCharacter'] as String?) ?? 'condor';
    final storedOwned = (json['ownedCharacters'] as List<Object?>?)
        ?.whereType<String>()
        .toList();
    final owned = <String>{
      'condor',
      ...?storedOwned,
      // Conserva el avatar seleccionado en perfiles de versiones anteriores.
      selected,
    }.toList();

    return UserProfile(
      name: json['name']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      selectedCharacter: selected,
      coins: (json['coins'] as int?) ?? 0,
      dailyStreak: (json['dailyStreak'] as int?) ?? 0,
      ownedCharacters: owned,
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.parse(json['lastActivityDate']! as String)
          : null,
    );
  }
}
