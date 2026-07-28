import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/character.dart';
import '../models/user_profile.dart';

enum CharacterPurchaseResult {
  purchased,
  alreadyOwned,
  levelLocked,
  insufficientCoins,
}

class LocalProgressRepository extends ChangeNotifier {
  static const _profileKey = 'profile.v1';
  static const _recordsKey = 'records.v1';
  static const _tutorialKey = 'tutorial.v1';

  UserProfile? profile;
  Map<int, Duration> bestTimes = {};
  bool tutorialCompleted = false;

  int get completedLevels =>
      bestTimes.keys.where((levelId) => levelId > 0).length;

  int get nextLevelId {
    if (!tutorialCompleted) return 0;
    for (var levelId = 1; levelId <= 9; levelId++) {
      if (!bestTimes.containsKey(levelId)) return levelId;
    }
    return 9;
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawProfile = preferences.getString(_profileKey);
    if (rawProfile != null) {
      profile = UserProfile.fromJson(
        jsonDecode(rawProfile) as Map<String, Object?>,
      );
    }
    final rawRecords = preferences.getString(_recordsKey);
    if (rawRecords != null) {
      final decoded = jsonDecode(rawRecords) as Map<String, Object?>;
      bestTimes = decoded.map(
        (key, value) =>
            MapEntry(int.parse(key), Duration(milliseconds: value! as int)),
      );
    }
    tutorialCompleted = preferences.getBool(_tutorialKey) ?? false;
  }

  Future<void> register(String name) async {
    profile = UserProfile(name: name.trim(), createdAt: DateTime.now());
    await _saveProfile();
    notifyListeners();
  }

  int rewardForLevel(int levelId, {required bool firstCompletion}) {
    if (levelId == 0) return firstCompletion ? 30 : 8;
    return 12 + (levelId * 3) + (firstCompletion ? 15 : 0);
  }

  /// Guarda el récord y acredita la recompensa como una sola operación lógica.
  Future<int> completeLevel(int levelId, Duration elapsed) async {
    if (profile == null) return 0;

    final firstCompletion = !bestTimes.containsKey(levelId);
    final reward = rewardForLevel(levelId, firstCompletion: firstCompletion);
    final current = bestTimes[levelId];
    if (current == null || elapsed < current) bestTimes[levelId] = elapsed;
    if (levelId == 0) tutorialCompleted = true;

    await _registerActivityWithoutNotify();
    profile = profile!.copyWith(coins: profile!.coins + reward);

    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(
        _recordsKey,
        jsonEncode(
          bestTimes.map((key, value) => MapEntry('$key', value.inMilliseconds)),
        ),
      ),
      preferences.setBool(_tutorialKey, tutorialCompleted),
      preferences.setString(_profileKey, jsonEncode(profile!.toJson())),
    ]);
    notifyListeners();
    return reward;
  }

  /// Compatibilidad con integraciones que guardaban el tiempo directamente.
  Future<void> saveCompletion(int levelId, Duration elapsed) async {
    await completeLevel(levelId, elapsed);
  }

  bool isUnlocked(int levelId) {
    if (!tutorialCompleted) return false;
    return levelId == 1 || bestTimes.containsKey(levelId - 1);
  }

  bool isCharacterOwned(Character character) =>
      character == Character.condor ||
      (profile?.ownedCharacters.contains(character.name) ?? false);

  bool meetsCharacterLevel(Character character) =>
      character.requiredLevel == 0 ||
      bestTimes.containsKey(character.requiredLevel);

  bool isCharacterUnlocked(Character character) => isCharacterOwned(character);

  Future<CharacterPurchaseResult> purchaseCharacter(Character character) async {
    final currentProfile = profile;
    if (currentProfile == null) {
      return CharacterPurchaseResult.insufficientCoins;
    }
    if (isCharacterOwned(character)) {
      return CharacterPurchaseResult.alreadyOwned;
    }
    if (!meetsCharacterLevel(character)) {
      return CharacterPurchaseResult.levelLocked;
    }
    if (currentProfile.coins < character.price) {
      return CharacterPurchaseResult.insufficientCoins;
    }

    profile = currentProfile.copyWith(
      coins: currentProfile.coins - character.price,
      ownedCharacters: [...currentProfile.ownedCharacters, character.name],
    );
    await _saveProfile();
    notifyListeners();
    return CharacterPurchaseResult.purchased;
  }

  Future<void> selectCharacter(Character character) async {
    if (profile == null || !isCharacterOwned(character)) return;
    profile = profile!.copyWith(selectedCharacter: character.name);
    await _saveProfile();
    notifyListeners();
  }

  Future<void> addCoins(int amount) async {
    if (profile == null || amount <= 0) return;
    profile = profile!.copyWith(coins: profile!.coins + amount);
    await _saveProfile();
    notifyListeners();
  }

  Future<void> registerActivity() async {
    if (await _registerActivityWithoutNotify()) {
      await _saveProfile();
      notifyListeners();
    }
  }

  Future<bool> _registerActivityWithoutNotify() async {
    if (profile == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = profile!.lastActivityDate;
    final lastDay =
        last == null ? null : DateTime(last.year, last.month, last.day);

    var newStreak = profile!.dailyStreak;
    if (lastDay == null) {
      newStreak = 1;
    } else {
      final difference = today.difference(lastDay).inDays;
      if (difference == 1) {
        newStreak++;
      } else if (difference > 1) {
        newStreak = 1;
      }
    }

    if (newStreak == profile!.dailyStreak && lastDay == today) return false;
    profile = profile!.copyWith(dailyStreak: newStreak, lastActivityDate: now);
    return true;
  }

  Future<void> _saveProfile() async {
    if (profile == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_profileKey, jsonEncode(profile!.toJson()));
  }
}
