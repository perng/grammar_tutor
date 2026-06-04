import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../config/menu_config.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(loc.aboutTitle, textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: MarkdownBody(
                data: loc.aboutContentMarkdown,
                onTapLink: (text, href, title) async {
                  if (href != null) {
                    final Uri url = Uri.parse(href);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  }
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.get('close')),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _SettingsSheet(
        onAbout: _showAboutDialog,
      ),
    );
  }

  // ─── Top bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final location = GoRouterState.of(context).uri.toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2D2D3F) : AppColors.border;

    String? pageTitle;
    String? backTarget;
    bool isHome = location == '/';
    bool isMockTest = location.startsWith('/mock-test');

    if (location.startsWith('/categories/')) {
      final categoryId = location.split('/categories/').last.split('/').first;
      pageTitle = loc.get(categoryId);
      backTarget = '/';
    } else if (isMockTest) {
      pageTitle = loc.mockTestTitle;
      if (location == '/mock-test') {
        backTarget = '/';
      } else {
        backTarget = '/mock-test';
      }
    } else if (!isHome) {
      // Game route
      for (var entry in menuItemsConfig.entries) {
        for (var item in entry.value) {
          if (location == item.path ||
              location.startsWith('${item.path}/')) {
            pageTitle = loc.get(item.titleKey);
            if (location == item.path) {
              backTarget = '/categories/${entry.key}';
            } else {
              backTarget = item.path;
            }
            break;
          }
        }
        if (pageTitle != null) break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              if (isHome) ...[
                const SizedBox(width: 16),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Center(
                    child: Text('📖', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Handy Grammar',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.primaryDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                _iconBtn(
                  icon: Icons.info_outline_rounded,
                  isDark: isDark,
                  onTap: _showAboutDialog,
                ),
                const SizedBox(width: 4),
                _iconBtn(
                  icon: Icons.tune_rounded,
                  isDark: isDark,
                  onTap: _showSettingsSheet,
                ),
                const SizedBox(width: 12),
              ] else ...[
                const SizedBox(width: 8),
                _iconBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  isDark: isDark,
                  onTap: () {
                    if (backTarget != null) {
                      context.go(backTarget);
                    } else if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pageTitle ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _iconBtn(
                  icon: Icons.tune_rounded,
                  isDark: isDark,
                  onTap: _showSettingsSheet,
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D3F) : AppColors.surface2,
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A50) : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white70 : AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

// ─── Settings Bottom Sheet ──────────────────────────────────────────────────

class _SettingsSheet extends StatelessWidget {
  final VoidCallback onAbout;
  const _SettingsSheet({required this.onAbout});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final loc = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3A3A50)
                    : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
              child: Row(
                children: [
                  Text(
                    loc.settings,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2D2D3F)
                            : AppColors.surface2,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3A3A50)
                              : AppColors.border,
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: isDark ? Colors.white54 : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Language section
            _sectionLabel(context, '🌐  ${loc.selectLanguage}', isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Consumer<LocaleProvider>(
                builder: (ctx, localeProvider, _) {
                  return Row(
                    children: [
                      _langCard(
                        context: context,
                        flag: '🇺🇸',
                        name: 'English',
                        native: 'English',
                        locale: const Locale('en'),
                        current: localeProvider.locale,
                        isDark: isDark,
                        onTap: () => localeProvider.setLocale(const Locale('en')),
                      ),
                      const SizedBox(width: 8),
                      _langCard(
                        context: context,
                        flag: '🇹🇼',
                        name: '繁體中文',
                        native: 'Traditional',
                        locale: const Locale('zh', 'TW'),
                        current: localeProvider.locale,
                        isDark: isDark,
                        onTap: () =>
                            localeProvider.setLocale(const Locale('zh', 'TW')),
                      ),
                      const SizedBox(width: 8),
                      _langCard(
                        context: context,
                        flag: '🇨🇳',
                        name: '简体中文',
                        native: 'Simplified',
                        locale: const Locale('zh', 'CN'),
                        current: localeProvider.locale,
                        isDark: isDark,
                        onTap: () =>
                            localeProvider.setLocale(const Locale('zh', 'CN')),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 4),
            _sectionLabel(context, '🎨  Appearance', isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Consumer<ThemeProvider>(
                builder: (ctx, themeProvider, _) {
                  return Row(
                    children: [
                      _themeCard(
                        context: context,
                        icon: '☀️',
                        label: 'Light',
                        mode: ThemeMode.light,
                        current: themeProvider.themeMode,
                        isDark: isDark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                      ),
                      const SizedBox(width: 8),
                      _themeCard(
                        context: context,
                        icon: '🌙',
                        label: 'Dark',
                        mode: ThemeMode.dark,
                        current: themeProvider.themeMode,
                        isDark: isDark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                      ),
                      const SizedBox(width: 8),
                      _themeCard(
                        context: context,
                        icon: '📱',
                        label: 'System',
                        mode: ThemeMode.system,
                        current: themeProvider.themeMode,
                        isDark: isDark,
                        onTap: () =>
                            themeProvider.setThemeMode(ThemeMode.system),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            // About row
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                onAbout();
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D2D3F) : AppColors.surface2,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3A3A50)
                        : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('📖', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About Handy Grammar',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Version, Privacy Policy & Support',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white38 : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
            color: isDark ? Colors.white38 : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _langCard({
    required BuildContext context,
    required String flag,
    required String name,
    required String native,
    required Locale locale,
    required Locale current,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bool selected = current == locale;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isDark
                      ? AppColors.primary.withOpacity(0.25)
                      : const Color(0xFFEEF2FF))
                : (isDark
                      ? const Color(0xFF2D2D3F)
                      : AppColors.surface2),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark
                        ? const Color(0xFF3A3A50)
                        : AppColors.border),
              width: selected ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : AppColors.textPrimary),
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                native,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white38 : AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              if (selected) ...[
                const SizedBox(height: 6),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeCard({
    required BuildContext context,
    required String icon,
    required String label,
    required ThemeMode mode,
    required ThemeMode current,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final bool selected = current == mode;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? (isDark
                      ? AppColors.primary.withOpacity(0.25)
                      : const Color(0xFFEEF2FF))
                : (isDark
                      ? const Color(0xFF2D2D3F)
                      : AppColors.surface2),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark
                        ? const Color(0xFF3A3A50)
                        : AppColors.border),
              width: selected ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : AppColors.textPrimary),
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 6),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
