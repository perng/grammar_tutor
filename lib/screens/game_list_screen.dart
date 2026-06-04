import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/menu_config.dart';
import '../l10n/app_localizations.dart';
import '../providers/progress_provider.dart';
import '../theme/app_colors.dart';

class GameListScreen extends StatefulWidget {
  final String categoryId;
  const GameListScreen({super.key, required this.categoryId});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProgressProvider>(context, listen: false).calculateProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final items = menuItemsConfig[widget.categoryId];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items == null) {
      return Scaffold(
        body: Center(child: Text('Category not found: ${widget.categoryId}')),
      );
    }

    final gradColors = AppColors.gradientFor(widget.categoryId);
    final emoji = AppColors.emojiFor(widget.categoryId);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF13131F) : AppColors.background,
      body: Consumer<ProgressProvider>(
        builder: (context, progressProvider, child) {
          // Overall category completion
          final completion =
              progressProvider.gameCompletion[widget.categoryId] ?? 0.0;
          final overallPct = (completion * 100).round();

          return Column(
            children: [
              // ── Gradient header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Text(
                        emoji,
                        style: TextStyle(
                          fontSize: 80,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.get(widget.categoryId),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${items.length} games',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Progress row
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.22)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '$overallPct%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Overall progress · ${items.length} games',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.72),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(99),
                                      child: LinearProgressIndicator(
                                        value: completion,
                                        minHeight: 5,
                                        backgroundColor:
                                            Colors.white.withOpacity(0.2),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Game list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final gameCompletion =
                        progressProvider.gameCompletion[item.path] ?? 0.0;
                    final gamePct = (gameCompletion * 100).round();
                    final isNew = gamePct == 0;
                    final isDone = gamePct >= 100;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildGameCard(
                        context: context,
                        item: item,
                        completion: gameCompletion,
                        pct: gamePct,
                        isNew: isNew,
                        isDone: isDone,
                        isDark: isDark,
                        gradColors: gradColors,
                        loc: loc,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required MenuItem item,
    required double completion,
    required int pct,
    required bool isNew,
    required bool isDone,
    required bool isDark,
    required List<Color> gradColors,
    required AppLocalizations loc,
  }) {
    return GestureDetector(
      onTap: () => context.go(item.path),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDone
              ? (isDark
                    ? AppColors.green.withOpacity(0.08)
                    : const Color(0xFFF0FDF4))
              : (isDark ? const Color(0xFF1E1E2E) : Colors.white),
          border: Border(
            left: BorderSide(
              color: isDone
                  ? AppColors.green
                  : (!isNew ? AppColors.primary : Colors.transparent),
              width: 3,
            ),
            top: BorderSide(
              color: isDone
                  ? AppColors.green.withOpacity(isDark ? 0.3 : 0.4)
                  : (isDark ? const Color(0xFF2D2D3F) : AppColors.border),
              width: 1.5,
            ),
            right: BorderSide(
              color: isDone
                  ? AppColors.green.withOpacity(isDark ? 0.3 : 0.4)
                  : (isDark ? const Color(0xFF2D2D3F) : AppColors.border),
              width: 1.5,
            ),
            bottom: BorderSide(
              color: isDone
                  ? AppColors.green.withOpacity(isDark ? 0.3 : 0.4)
                  : (isDark ? const Color(0xFF2D2D3F) : AppColors.border),
              width: 1.5,
            ),
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon
            Hero(
              tag: 'game_icon_${item.path}',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.green.withOpacity(isDark ? 0.2 : 0.12)
                      : (isDark
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.surface2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: isDone
                      ? AppColors.green
                      : (isDark ? AppColors.primaryLight : AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.get(item.titleKey),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: completion,
                            minHeight: 5,
                            backgroundColor: isDark
                                ? const Color(0xFF2D2D3F)
                                : AppColors.surface2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDone
                                  ? AppColors.green
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDone
                              ? AppColors.green
                              : (isDark
                                    ? Colors.white38
                                    : AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Right: badge + play button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isNew)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.amber.withOpacity(0.2)
                          : const Color(0xFFFEF3C7),
                      border: Border.all(
                        color: isDark
                            ? AppColors.amber.withOpacity(0.4)
                            : const Color(0xFFFDE68A),
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'New',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.amber
                            : const Color(0xFF92400E),
                      ),
                    ),
                  )
                else if (isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.green.withOpacity(0.2)
                          : const Color(0xFFD1FAE5),
                      border: Border.all(
                        color: isDark
                            ? AppColors.green.withOpacity(0.4)
                            : const Color(0xFFA7F3D0),
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'Done ✓',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.green
                            : const Color(0xFF065F46),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.green : AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (isDone ? AppColors.green : AppColors.primary)
                            .withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
