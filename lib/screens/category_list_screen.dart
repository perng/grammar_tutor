import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/menu_config.dart';
import '../l10n/app_localizations.dart';
import '../providers/progress_provider.dart';
import '../theme/app_colors.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF13131F) : AppColors.background,
      body: Consumer<ProgressProvider>(
        builder: (context, progressProvider, child) {
          final keys = menuItemsConfig.keys.toList();

          // Compute stats
          final totalGames = menuItemsConfig.values
              .fold(0, (sum, list) => sum + list.length);
          final completions = keys
              .map((k) => progressProvider.gameCompletion[k] ?? 0.0)
              .toList();
          final overallPct = completions.isNotEmpty
              ? (completions.reduce((a, b) => a + b) /
                      completions.length *
                      100)
                  .round()
              : 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Stats row
              _buildStatsRow(
                context,
                categories: keys.length,
                games: totalGames,
                pct: overallPct,
                isDark: isDark,
              ),
              const SizedBox(height: 18),

              // ── Mock Test hero card
              _buildMockTestCard(context, loc, isDark),
              const SizedBox(height: 24),

              // ── Section heading
              _sectionHeading(context, 'Grammar Topics', '${keys.length} categories', isDark),
              const SizedBox(height: 12),

              // ── Category list
              ...keys.map((key) {
                final completion =
                    progressProvider.gameCompletion[key] ?? 0.0;
                final gamesInCat = menuItemsConfig[key]?.length ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildCategoryCard(
                    context: context,
                    loc: loc,
                    categoryKey: key,
                    completion: completion,
                    gameCount: gamesInCat,
                    isDark: isDark,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context, {
    required int categories,
    required int games,
    required int pct,
    required bool isDark,
  }) {
    return Row(
      children: [
        _statCard(context, '$categories', 'Categories', isDark),
        const SizedBox(width: 10),
        _statCard(context, '$games+', 'Games', isDark),
        const SizedBox(width: 10),
        _statCard(context, '$pct%', 'Complete', isDark),
      ],
    );
  }

  Widget _statCard(
      BuildContext context, String num, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF2D2D3F) : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
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
        child: Column(
          children: [
            Text(
              num,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xFF818CF8) : AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.07,
                color: isDark ? Colors.white38 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockTestCard(
      BuildContext context, AppLocalizations loc, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/mock-test'),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.mockTestGrad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc.mockTestTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        loc.mockTestSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.78),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Start Test',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Score badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(
      BuildContext context, String title, String count, bool isDark) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
            color: isDark ? Colors.white38 : AppColors.textMuted,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.surface2,
            border: Border.all(
              color: isDark
                  ? AppColors.primary.withOpacity(0.3)
                  : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required AppLocalizations loc,
    required String categoryKey,
    required double completion,
    required int gameCount,
    required bool isDark,
  }) {
    final pct = (completion * 100).round();
    final isComplete = pct >= 100;
    final emoji = AppColors.emojiFor(categoryKey);
    final iconBg = AppColors.iconBgFor(categoryKey);
    final gradColors = AppColors.gradientFor(categoryKey);
    final accentColor = gradColors.last;

    return GestureDetector(
      onTap: () => context.go('/categories/$categoryKey'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          border: Border.all(
            color: isComplete
                ? AppColors.green.withOpacity(isDark ? 0.35 : 0.4)
                : (isDark ? const Color(0xFF2D2D3F) : AppColors.border),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? accentColor.withOpacity(0.2) : iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            // Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.get(categoryKey),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$gameCount games',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: completion,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? const Color(0xFF2D2D3F)
                          : AppColors.surface2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete ? AppColors.green : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right side: pct + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isComplete
                        ? AppColors.green
                        : (isDark ? AppColors.primaryLight : AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? Colors.white38 : AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
