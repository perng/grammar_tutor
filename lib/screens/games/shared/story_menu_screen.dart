import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/story_level.dart';
import '../../../widgets/explanation_dialog.dart';
import '../../../theme/app_colors.dart';

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
  String? _errorMessage;
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
      await prefs.reload();

      Map<String, double> loadProgress() {
        final Map<String, double> progress = {};
        double totalScore = 0.0;
        for (int i = 0; i < levels.length; i++) {
          final String key = '${widget.progressKeyPrefix}-$i';
          final String? val = prefs.getString(key);
          double valDouble =
              val != null ? (double.tryParse(val) ?? 0.0) : 0.0;
          progress[i.toString()] = valDouble;
          totalScore += valDouble;
        }
        _averageProgress =
            levels.isNotEmpty ? totalScore / levels.length : 0.0;
        return progress;
      }

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text('Error: $_errorMessage')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doneCount =
        _progressMap.values.where((p) => p >= 100).length;
    final totalCount = _levels.length;
    final overallProgress = totalCount > 0 ? _averageProgress / 100.0 : 0.0;
    final overallPct = (overallProgress * 100).round();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF13131F) : AppColors.background,
      body: Column(
        children: [
          // ── Gradient header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCount levels',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 14),
                // Summary strip
                Row(
                  children: [
                    _sumItem('$totalCount', 'Levels'),
                    const SizedBox(width: 8),
                    _sumItem('$doneCount', 'Done'),
                    const SizedBox(width: 8),
                    _sumItem('${totalCount - doneCount}', 'Left'),
                  ],
                ),
              ],
            ),
          ),

          // ── Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // Explanation banner
                GestureDetector(
                  onTap: () {
                    ExplanationDialog.show(
                      context,
                      widget.assetPath,
                      GoRouterState.of(context).uri.toString(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEDE9FE), Color(0xFFDBEAFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: const Color(0xFFC4B5FD), width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grammar Explanation',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF4C1D95),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Read notes before playing',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6D28D9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Overall progress
                Row(
                  children: [
                    Text(
                      'Overall Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white38 : AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$overallPct%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: overallProgress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark
                        ? const Color(0xFF2D2D3F)
                        : AppColors.surface2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF059669),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Level grid label
                Text(
                  'SELECT A LEVEL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                    color: isDark ? Colors.white38 : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),

                // 2-column level grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: _levels.length,
                  itemBuilder: (context, index) {
                    final level = _levels[index];
                    final progress = _progressMap[index.toString()] ?? 0.0;
                    final isDone = progress >= 100;
                    return _buildLevelCard(
                      context: context,
                      index: index,
                      level: level,
                      progress: progress,
                      isDone: isDone,
                      isDark: isDark,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumItem(String num, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              num,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.72),
                letterSpacing: 0.06,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard({
    required BuildContext context,
    required int index,
    required StoryLevel level,
    required double progress,
    required bool isDone,
    required bool isDark,
  }) {
    Color borderColor;
    Color bgColor;
    Color progressColor;

    if (isDone) {
      borderColor = isDark
          ? AppColors.green.withOpacity(0.4)
          : const Color(0xFFA7F3D0);
      bgColor = isDark
          ? AppColors.green.withOpacity(0.08)
          : const Color(0xFFF0FDF4);
      progressColor = AppColors.green;
    } else if (progress > 0) {
      borderColor = isDark
          ? AppColors.primaryLight.withOpacity(0.4)
          : AppColors.primaryLight;
      bgColor = isDark
          ? AppColors.primary.withOpacity(0.08)
          : const Color(0xFFEEF2FF);
      progressColor = AppColors.primary;
    } else {
      borderColor =
          isDark ? const Color(0xFF2D2D3F) : AppColors.border;
      bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
      progressColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () async {
        await context.push('${widget.routePrefix}/$index');
        if (mounted) {
          _loadLevels(isInitialLoad: false);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'LEVEL ${index + 1}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.08,
                        color: isDark ? Colors.white38 : AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isDone ? '✅' : (progress > 0 ? '▶️' : '⭕'),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    level.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress / 100.0,
                    minHeight: 4,
                    backgroundColor: isDark
                        ? const Color(0xFF2D2D3F)
                        : AppColors.surface2,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDone
                      ? '100%'
                      : (progress > 0
                            ? '${progress.round()}%'
                            : '0%'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDone
                        ? AppColors.green
                        : (progress > 0
                              ? (isDark ? AppColors.primaryLight : AppColors.primary)
                              : (isDark ? Colors.white38 : AppColors.textMuted)),
                  ),
                ),
              ],
            ),
            // Play button at bottom-right
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDone ? AppColors.green : AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: (isDone ? AppColors.green : AppColors.primary)
                          .withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
