import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/balance.dart';
import '../engine/game_world.dart';

/// Handles game persistence using SharedPreferences with multi-store support and JSON versioning.
class SaveService {
  static const String saveKey = 'dhaba_save_v1';
  static const String corruptSaveKey = 'dhaba_save_v1_corrupt';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Saves the current store state into SharedPreferences.
  Future<bool> saveStoreState(GameWorld world) async {
    try {
      await init();
      final prefs = _prefs;
      if (prefs == null) return false;

      // Read existing root save or initialize new structure
      Map<String, dynamic> rootData = {};
      final existingJson = prefs.getString(saveKey);
      if (existingJson != null && existingJson.isNotEmpty) {
        try {
          rootData = jsonDecode(existingJson) as Map<String, dynamic>;
        } catch (_) {
          rootData = {};
        }
      }

      rootData['version'] = 1;
      rootData['lastSavedAt'] = DateTime.now().millisecondsSinceEpoch;
      rootData['activeStoreId'] = world.progressionConfig.storeId;

      // Extract existing stores map or create empty
      Map<String, dynamic> stores = {};
      if (rootData['stores'] is Map<String, dynamic>) {
        stores = rootData['stores'] as Map<String, dynamic>;
      }

      // Serialize current store data
      final storeId = world.progressionConfig.storeId;
      final storeData = <String, dynamic>{
        'storeId': storeId,
        'storeName': world.progressionConfig.storeName,
        'wallet': world.rupees,
        'lifetimeRupees': world.lifetimeRupees,
        'reputationPercent': world.reputationPercent,
        'isReputationLocked100': world.isReputationLocked100,
        'completedMissionIds': world.completedMissionIds.toList(),
        'kettleLevel': world.chaiStation.level,
        'parathaUnlocked': world.parathaStation.isUnlocked,
        'parathaLevel': world.parathaStation.level,
        'unlockedTableIds': world.diningTables
            .where((t) => t.isUnlocked)
            .map((t) => t.id)
            .toList(),
        'cashierHired': world.hasCashier,
        'workerCount': world.workerCount,
        'playerSpeedLevel': world.playerSpeedLevel,
        'playerCapacityLevel': world.playerCapacityLevel,
        'workerSpeedLevel': world.workerSpeedLevel,
        'workerCapacityLevel': world.workerCapacityLevel,
        'cashierSpeedLevel': world.cashierSpeedLevel,
      };

      stores[storeId] = storeData;
      rootData['stores'] = stores;

      final jsonStr = jsonEncode(rootData);
      return await prefs.setString(saveKey, jsonStr);
    } catch (e) {
      return false;
    }
  }

  /// Loads saved state for the active store and restores GameWorld entities and stats.
  Future<bool> loadStoreState(GameWorld world) async {
    try {
      await init();
      final prefs = _prefs;
      if (prefs == null) return false;

      final jsonStr = prefs.getString(saveKey);
      if (jsonStr == null || jsonStr.isEmpty) return false;

      final rootData = jsonDecode(jsonStr) as Map<String, dynamic>;
      final stores = rootData['stores'] as Map<String, dynamic>?;
      if (stores == null) return false;

      final storeId = world.progressionConfig.storeId;
      final storeData = stores[storeId] as Map<String, dynamic>?;
      if (storeData == null) return false;

      // 1. Restore Economy & Lifetime stats
      if (storeData.containsKey('wallet')) {
        world.rupees = (storeData['wallet'] as num).toDouble();
      }
      if (storeData.containsKey('lifetimeRupees')) {
        world.lifetimeRupees = (storeData['lifetimeRupees'] as num).toDouble();
      }

      // 2. Restore Reputation Percent & 100% lock
      if (storeData.containsKey('reputationPercent')) {
        world.reputationPercent =
            (storeData['reputationPercent'] as num).toDouble();
      } else if (storeData.containsKey('reputationXP')) {
        // Migration from earlier test saves
        world.reputationPercent =
            ((storeData['reputationXP'] as num).toDouble() / 10.0).clamp(0.0, 100.0);
      }
      if (storeData.containsKey('isReputationLocked100')) {
        world.isReputationLocked100 = storeData['isReputationLocked100'] as bool;
      }

      // 3. Restore Completed Missions
      if (storeData.containsKey('completedMissionIds')) {
        final list = storeData['completedMissionIds'] as List<dynamic>;
        world.completedMissionIds
          ..clear()
          ..addAll(list.map((e) => e.toString()));
      }

      // 4. Restore Kettle Level
      if (storeData.containsKey('kettleLevel')) {
        final level = (storeData['kettleLevel'] as num).toInt();
        world.chaiStation.upgradeTo(level);
        for (final pad in world.groundPads) {
          if (pad.id == 'kettle_upgrade') {
            pad.setLevel(level);
          }
        }
      }

      // 4.5 Restore Paratha Tawa Level & Unlock State
      if (storeData.containsKey('parathaUnlocked') &&
          storeData['parathaUnlocked'] == true) {
        world.parathaStation.isUnlocked = true;
        final pLevel = (storeData['parathaLevel'] as num?)?.toInt() ?? 1;
        world.parathaStation.upgradeTo(pLevel);
        for (final pad in world.groundPads) {
          if (pad.id == 'paratha_station_pad') {
            pad.setLevel(pLevel);
          }
        }
      }

      // 5. Restore Dining Tables
      if (storeData.containsKey('unlockedTableIds')) {
        final unlockedIds = (storeData['unlockedTableIds'] as List<dynamic>)
            .map((e) => (e as num).toInt())
            .toSet();
        for (final table in world.diningTables) {
          if (unlockedIds.contains(table.id)) {
            table.isUnlocked = true;
          }
        }
        for (final pad in world.groundPads) {
          if (pad.id == 'table_1_unlock' && unlockedIds.contains(1)) {
            pad.remainingCost = 0.0;
            pad.isCompleted = true;
          }
          if (pad.id == 'table_2_unlock' && unlockedIds.contains(2)) {
            pad.remainingCost = 0.0;
            pad.isCompleted = true;
          }
        }
      }

      // 6. Restore Staff (Cashier & Workers)
      if (storeData['cashierHired'] == true && !world.hasCashier) {
        world.hireCashier(free: true);
      }

      if (storeData.containsKey('workerCount')) {
        final count = (storeData['workerCount'] as num).toInt();
        while (world.workerCount < count && world.canHireWorker) {
          world.hireWorker(free: true);
        }
      }

      // 7. Restore HR Levels
      if (storeData.containsKey('playerSpeedLevel')) {
        world.playerSpeedLevel = (storeData['playerSpeedLevel'] as num).toInt();
        world.player.speed =
            GameBalance.playerSpeedLevels[world.playerSpeedLevel - 1];
      }
      if (storeData.containsKey('playerCapacityLevel')) {
        world.playerCapacityLevel =
            (storeData['playerCapacityLevel'] as num).toInt();
        world.player.carryCapacity =
            GameBalance.playerCapacityLevels[world.playerCapacityLevel - 1];
      }
      if (storeData.containsKey('workerSpeedLevel')) {
        world.workerSpeedLevel = (storeData['workerSpeedLevel'] as num).toInt();
        final newSpeed = world.currentWorkerSpeed;
        for (final s in world.staff) {
          s.speed = newSpeed;
        }
      }
      if (storeData.containsKey('workerCapacityLevel')) {
        world.workerCapacityLevel =
            (storeData['workerCapacityLevel'] as num).toInt();
        final newCap = world.currentWorkerCapacity;
        for (final s in world.staff) {
          s.carryCapacity = newCap;
        }
      }
      if (storeData.containsKey('cashierSpeedLevel')) {
        world.cashierSpeedLevel =
            (storeData['cashierSpeedLevel'] as num).toInt();
        world.counter.serviceInterval = world.cashierSpeed;
      }

      // 8. Finally, restore exact saved reputation percent and lock without duplicate upgrade additions
      if (storeData.containsKey('reputationPercent')) {
        world.reputationPercent =
            (storeData['reputationPercent'] as num).toDouble();
      } else if (storeData.containsKey('reputationXP')) {
        world.reputationPercent =
            ((storeData['reputationXP'] as num).toDouble() / 10.0).clamp(0.0, 100.0);
      }
      if (storeData.containsKey('isReputationLocked100')) {
        world.isReputationLocked100 = storeData['isReputationLocked100'] as bool;
      }

      // Update dynamic customer spawn interval based on restored reputation
      world.addReputationPercent(0.0);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clears stored game data (useful for reset / testing).
  Future<bool> clearSave() async {
    await init();
    return await _prefs?.remove(saveKey) ?? false;
  }
}
