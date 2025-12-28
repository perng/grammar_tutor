import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../config/menu_config.dart';

class ProgressProvider extends ChangeNotifier {
  Map<String, double> _gameCompletion = {};
  Map<String, double> get gameCompletion => _gameCompletion;

  ProgressProvider() {
    calculateProgress();
  }

  Future<void> calculateProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, double> newCompletion = {};

    // Calculate for all games
    for (var entry in menuItemsConfig.entries) {
      for (var item in entry.value) {
        String assetPath = item.assetPath;
        String path = item.path;

        try {
          final String response = await rootBundle.loadString(assetPath);
          final List<dynamic> data = json.decode(response);
          int totalLevels = data.length;

          if (totalLevels == 0) {
            newCompletion[path] = 0.0;
            continue;
          }

          String keyBase = assetPath
              .replaceAll('assets/data/', '')
              .replaceAll('.json', '');

          double totalScore = 0;

          for (int i = 0; i < totalLevels; i++) {
            final String key = '$keyBase-$i';
            final String? val = prefs.getString(key);
            if (val != null) {
              int score = int.tryParse(val) ?? 0;
              totalScore += score;
            }
          }

          newCompletion[path] = totalScore / (totalLevels * 100.0);
        } catch (e) {
          debugPrint("Error loading progress for $path: $e");
          newCompletion[path] = 0.0;
        }
      }
    }

    // Calculate progress for each category
    for (var entry in menuItemsConfig.entries) {
      String categoryKey = entry.key;
      List<MenuItem> items = entry.value;
      if (items.isEmpty) {
        newCompletion[categoryKey] = 0.0;
        continue;
      }

      double totalCategoryProgress = 0.0;
      int gameCount = 0;

      for (var item in items) {
        totalCategoryProgress += newCompletion[item.path] ?? 0.0;
        gameCount++;
      }

      if (gameCount > 0) {
        newCompletion[categoryKey] = totalCategoryProgress / gameCount;
      } else {
        newCompletion[categoryKey] = 0.0;
      }
    }

    _gameCompletion = newCompletion;
    notifyListeners();
  }

  Future<void> updateGameProgress(String key, int percentage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, percentage.toString());
    await calculateProgress();
  }
}
