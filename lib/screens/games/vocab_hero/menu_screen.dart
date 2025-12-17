import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/vocab_hero_models.dart';

class VocabHeroMenuScreen extends StatefulWidget {
  const VocabHeroMenuScreen({super.key});

  @override
  State<VocabHeroMenuScreen> createState() => _VocabHeroMenuScreenState();
}

class _VocabHeroMenuScreenState extends State<VocabHeroMenuScreen> {
  List<VocabLevel> _levels = [];
  Map<String, double> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/VocabHero/vh_levels.json',
      );
      final List<dynamic> data = json.decode(response);
      final levels = data.map((json) => VocabLevel.fromJson(json)).toList();

      final prefs = await SharedPreferences.getInstance();
      final Map<String, double> progress = {};

      for (var level in levels) {
        final String key = 'vocabHero-progress-${level.id}';
        final String? val = prefs.getString(key);
        progress[level.id] = val != null ? (double.tryParse(val) ?? 0.0) : 0.0;
      }

      setState(() {
        _levels = levels;
        _progressMap = progress;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading levels: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTitle(String title) {
    return title.replaceAll('[', '').replaceAll(']', '');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _levels.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final level = _levels[index];
          final progress = _progressMap[level.id] ?? 0.0;
          final isComplete = progress >= 100;

          // Simple color logic
          final Color bgColor = isComplete
              ? const Color(0xffe8f5e9)
              : const Color(0xfff5f5f5);
          final levelNum = level.id.split('_').last; // e.g. 001

          return InkWell(
            onTap: () {
              context.push('/vocab-hero/${level.id}');
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      levelNum,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTitle(level.title),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isComplete ? Colors.green : Colors.blue,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isComplete)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(Icons.check_circle, color: Colors.green),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
