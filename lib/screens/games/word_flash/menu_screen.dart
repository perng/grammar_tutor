import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/word_flash_models.dart';

class WordFlashMenuScreen extends StatefulWidget {
  final String gameType;
  const WordFlashMenuScreen({super.key, this.gameType = 'wordflash'});

  @override
  State<WordFlashMenuScreen> createState() => _WordFlashMenuScreenState();
}

class _WordFlashMenuScreenState extends State<WordFlashMenuScreen> {
  List<Level> _levels = [];
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
        'assets/data/${widget.gameType}/levels.json',
      );
      final List<dynamic> data = json.decode(response);
      final levels = data.map((json) => Level.fromJson(json)).toList();

      final prefs = await SharedPreferences.getInstance();
      final Map<String, double> progress = {};

      for (var level in levels) {
        final String key = '${widget.gameType}-progress-${level.id}';
        final String? val = prefs.getString(key);
        if (val != null) {
          progress[level.id] = double.tryParse(val) ?? 0.0;
        } else {
          progress[level.id] = 0.0;
        }
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

  Color _getBackgroundColor(double progress) {
    // Simplified color logic
    if (progress >= 100) return const Color(0xffe8f5e9);
    if (progress <= 0) return const Color(0xfff5f5f5);

    // Lerp between Red (0) -> Yellow (50) -> Green (100) light versions
    if (progress < 50) {
      return Color.lerp(
        const Color(0xffffebee),
        const Color(0xfffffde7),
        progress / 50,
      )!;
    } else {
      return Color.lerp(
        const Color(0xfffffde7),
        const Color(0xfff1f8e9),
        (progress - 50) / 50,
      )!;
    }
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
          final bgColor = _getBackgroundColor(progress);

          // Extract number from id (e.g. wf_level_001 -> 001)
          final levelNum = level.id.split('_').last;

          return InkWell(
            onTap: () {
              context.push('/wordflash/${level.id}');
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
                          level.title
                              .replaceAll('[', '')
                              .replaceAll(']', ''), // Simple format
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
                              progress >= 100 ? Colors.green : Colors.blue,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (progress >= 100)
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
