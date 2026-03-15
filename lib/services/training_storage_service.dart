import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training.dart';

class TrainingStorageService {
  static const String _trainingsKey = 'trainings';

  Future<List<Training>> getAllTrainings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_trainingsKey);
      if (json == null || json.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((j) => Training.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error loading trainings: $e');
      return [];
    }
  }

  Future<void> _saveTrainings(List<Training> trainings) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(trainings.map((t) => t.toJson()).toList());
    await prefs.setString(_trainingsKey, json);
  }

  Future<Training> addTraining(Training training) async {
    final trainings = await getAllTrainings();
    trainings.add(training);
    await _saveTrainings(trainings);
    return training;
  }

  Future<void> updateTraining(Training updated) async {
    final trainings = await getAllTrainings();
    final index = trainings.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      trainings[index] = updated;
      await _saveTrainings(trainings);
    }
  }

  Future<void> deleteTraining(String id) async {
    final trainings = await getAllTrainings();
    trainings.removeWhere((t) => t.id == id);
    await _saveTrainings(trainings);
  }

  Future<void> markTrainingAsUsed(String id) async {
    final trainings = await getAllTrainings();
    final index = trainings.indexWhere((t) => t.id == id);
    if (index != -1) {
      trainings[index] = trainings[index].copyWith(lastUsedAt: DateTime.now());
      await _saveTrainings(trainings);
    }
  }

  Future<bool> isNameTaken(String name, {String? excludeId}) async {
    final trainings = await getAllTrainings();
    return trainings.any(
      (t) => t.name.toLowerCase() == name.toLowerCase() && t.id != excludeId,
    );
  }
}
