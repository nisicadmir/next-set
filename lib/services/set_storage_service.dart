import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_set.dart';

class SetStorageService {
  static const String _setsKey = 'workout_sets';

  // Get all sets
  Future<List<WorkoutSet>> getAllSets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final setsJson = prefs.getString(_setsKey);

      if (setsJson == null || setsJson.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(setsJson);
      return decoded.map((json) => WorkoutSet.fromJson(json)).toList();
    } catch (e) {
      // If there's an error loading sets, return empty list
      // This prevents app crashes from corrupted data
      debugPrint('Error loading sets: $e');
      return [];
    }
  }

  // Save all sets
  Future<void> _saveSets(List<WorkoutSet> sets) async {
    final prefs = await SharedPreferences.getInstance();
    final setsJson = jsonEncode(sets.map((set) => set.toJson()).toList());
    await prefs.setString(_setsKey, setsJson);
  }

  // Add a new set
  Future<WorkoutSet> addSet(WorkoutSet set) async {
    final sets = await getAllSets();
    sets.add(set);
    await _saveSets(sets);
    return set;
  }

  // Update an existing set
  Future<void> updateSet(WorkoutSet updatedSet) async {
    final sets = await getAllSets();
    final index = sets.indexWhere((set) => set.id == updatedSet.id);

    if (index != -1) {
      sets[index] = updatedSet;
      await _saveSets(sets);
    }
  }

  // Delete a set
  Future<void> deleteSet(String id) async {
    final sets = await getAllSets();
    sets.removeWhere((set) => set.id == id);
    await _saveSets(sets);
  }

  // Get recently used sets (sorted by lastUsedAt)
  Future<List<WorkoutSet>> getRecentlyUsedSets({int limit = 5}) async {
    final sets = await getAllSets();
    final recentSets = sets.where((set) => set.lastUsedAt != null).toList();

    recentSets.sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));

    return recentSets.take(limit).toList();
  }

  // Update last used time
  Future<void> markSetAsUsed(String id) async {
    final sets = await getAllSets();
    final index = sets.indexWhere((set) => set.id == id);

    if (index != -1) {
      sets[index] = sets[index].copyWith(lastUsedAt: DateTime.now());
      await _saveSets(sets);
    }
  }

  // Check if name already exists (excluding a specific id for updates)
  Future<bool> isNameTaken(String name, {String? excludeId}) async {
    final sets = await getAllSets();
    return sets.any(
      (set) =>
          set.name.toLowerCase() == name.toLowerCase() && set.id != excludeId,
    );
  }
}
