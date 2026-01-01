import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/story_level.dart';
import '../../../widgets/explanation_dialog.dart';

class StoryMenuScreen extends StatefulWidget {
  final String title;
  final String assetPath;
  final String routePrefix;
  final String progressKeyPrefix;
  final AssetBundle? assetBundle;

  const StoryMenuScreen({
    super.key,
    required this.title,
    required this.assetPath,
    required this.routePrefix,
    required this.progressKeyPrefix,
    this.assetBundle,
  });

  @override
  State<StoryMenuScreen> createState() => _StoryMenuScreenState();
}

class _StoryMenuScreenState extends State<StoryMenuScreen> {
  List<StoryLevel> _levels = [];
  Map<String, double> _progressMap = {};
  bool _isLoading = true;
  double _averageProgress = 0.0;

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    if (widget.assetBundle != null) {
      _loadLevels(isInitialLoad: true);
      _isInit = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _loadLevels(isInitialLoad: true);
      _isInit = false;
    }
  }

  Future<void> _loadLevels({bool isInitialLoad = false}) async {
    try {
      final bundle = widget.assetBundle ?? DefaultAssetBundle.of(context);
      final String response = await bundle.loadString(widget.assetPath);
      final List<dynamic> data = json.decode(response);
      final levels = data.map((json) => StoryLevel.fromJson(json)).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Ensure we have the latest data from game screen

      // Helper function to load progress
      Map<String, double> loadProgress() {
        final Map<String, double> progress = {};
        double totalScore = 0.0;
        for (int i = 0; i < levels.length; i++) {
          final String key = '${widget.progressKeyPrefix}-$i';
          final String? val = prefs.getString(key);
          double valDouble = val != null ? (double.tryParse(val) ?? 0.0) : 0.0;
          progress[i.toString()] = valDouble;
          totalScore += valDouble;
        }
        _averageProgress = levels.isNotEmpty ? totalScore / levels.length : 0.0;
        return progress;
      }

      // Reload progress after returning (or if not first load)
      final finalProgress = loadProgress();

      if (mounted) {
        setState(() {
          _levels = levels;
          _progressMap = finalProgress;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading levels: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text('Error: $_errorMessage')));
    }

    String titleToDisplay = widget.title;
    if (_averageProgress > 0) {
      titleToDisplay += ' (${_averageProgress.toStringAsFixed(1)}%)';
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(titleToDisplay)),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.menu_book, size: 20),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              onPressed: () {
                ExplanationDialog.show(
                  context,
                  widget.assetPath,
                  GoRouterState.of(context).uri.toString(),
                );
              },
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _levels.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final level = _levels[index];
          final progress = _progressMap[index.toString()] ?? 0.0;
          final isComplete = progress >= 100;
          final scheme = Theme.of(context).colorScheme;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          final Color bgColor = isComplete
              ? (isDark
                    ? scheme.secondaryContainer.withOpacity(0.3)
                    : const Color(0xffe8f5e9))
              : (isDark
                    ? scheme.surfaceContainerHighest
                    : Theme.of(
                        context,
                      ).cardTheme.color!); // Use white from CardTheme

          return InkWell(
            onTap: () async {
              await context.push('${widget.routePrefix}/$index');
              if (mounted) {
                _loadLevels(isInitialLoad: false);
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
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
                      color: isDark ? scheme.surface : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? scheme.outline.withOpacity(0.5)
                            : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: scheme.onSurface,
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            if (progress > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(${progress.toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: scheme.onSurfaceVariant,
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
                            backgroundColor: scheme.surfaceVariant.withOpacity(
                              0.5,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isComplete ? Colors.green : scheme.primary,
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
