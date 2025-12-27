import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/story_level.dart';

class StoryMenuScreen extends StatefulWidget {
  final String title;
  final String assetPath;
  final String routePrefix;
  final String progressKeyPrefix;

  const StoryMenuScreen({
    super.key,
    required this.title,
    required this.assetPath,
    required this.routePrefix,
    required this.progressKeyPrefix,
  });

  @override
  State<StoryMenuScreen> createState() => _StoryMenuScreenState();
}

class _StoryMenuScreenState extends State<StoryMenuScreen> {
  List<StoryLevel> _levels = [];
  Map<String, double> _progressMap = {};
  bool _isLoading = true;
  double _averageProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    try {
      final String response = await rootBundle.loadString(widget.assetPath);
      final List<dynamic> data = json.decode(response);
      final levels = data.map((json) => StoryLevel.fromJson(json)).toList();

      final prefs = await SharedPreferences.getInstance();
      final Map<String, double> progress = {};
      double totalScore = 0.0;

      for (int i = 0; i < levels.length; i++) {
        final String key = '${widget.progressKeyPrefix}-$i';
        final String? val = prefs.getString(key);
        double valDouble = val != null ? (double.tryParse(val) ?? 0.0) : 0.0;
        progress[i.toString()] = valDouble;
        totalScore += valDouble;
      }

      double avg = levels.isNotEmpty ? totalScore / levels.length : 0.0;

      if (!mounted) return;
      setState(() {
        _levels = levels;
        _progressMap = progress;
        _averageProgress = avg;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading levels: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    String titleToDisplay = widget.title;
    if (_averageProgress > 0) {
      titleToDisplay += ' (${_averageProgress.toStringAsFixed(1)}%)';
    }

    return Scaffold(
      appBar: AppBar(title: Text(titleToDisplay)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _levels.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final level = _levels[index];
          final progress = _progressMap[index.toString()] ?? 0.0;
          final isComplete = progress >= 100;

          // Simple color logic
          final Color bgColor = isComplete
              ? const Color(0xffe8f5e9)
              : const Color(0xfff5f5f5);

          return InkWell(
            onTap: () async {
              // Pass index as levelId
              await context.push('${widget.routePrefix}/$index');
              // Reload levels to update progress
              if (mounted) {
                _loadLevels();
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                      '${index + 1}',
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
                        Row(
                          children: [
                            Text(
                              level.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (progress > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(${progress.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
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
