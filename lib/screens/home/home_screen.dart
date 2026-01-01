import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../config/menu_config.dart';
import '../../providers/progress_provider.dart';
import '../../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        final themeProvider = Provider.of<ThemeProvider>(context);
        final localeProvider = Provider.of<LocaleProvider>(context);

        return AlertDialog(
          title: Text(loc.settings, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.selectLanguage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: [
                  _buildLanguageButton(
                    context,
                    'English',
                    const Locale('en'),
                    localeProvider,
                  ),
                  _buildLanguageButton(
                    context,
                    '繁體中文',
                    const Locale('zh', 'TW'),
                    localeProvider,
                  ),
                  _buildLanguageButton(
                    context,
                    '简体中文',
                    const Locale('zh', 'CN'),
                    localeProvider,
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'Theme', // TODO: Add to localization
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildThemeButton(
                    context,
                    Icons.brightness_auto,
                    'System',
                    ThemeMode.system,
                    themeProvider,
                  ),
                  const SizedBox(width: 8),
                  _buildThemeButton(
                    context,
                    Icons.light_mode,
                    'Light',
                    ThemeMode.light,
                    themeProvider,
                  ),
                  const SizedBox(width: 8),
                  _buildThemeButton(
                    context,
                    Icons.dark_mode,
                    'Dark',
                    ThemeMode.dark,
                    themeProvider,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'), // TODO: Add to localization
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    String label,
    Locale locale,
    LocaleProvider provider,
  ) {
    final isSelected = provider.locale == locale;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          provider.setLocale(locale);
        }
      },
    );
  }

  Widget _buildThemeButton(
    BuildContext context,
    IconData icon,
    String label,
    ThemeMode mode,
    ThemeProvider provider,
  ) {
    final isSelected = provider.themeMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => provider.setThemeMode(mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final location = GoRouterState.of(context).uri.toString();
    final progressProvider = Provider.of<ProgressProvider>(context);
    List<Widget> breadcrumbs = [];

    // Home
    breadcrumbs.add(
      InkWell(
        onTap: () => context.go('/'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: const Icon(Icons.home_rounded, size: 24),
        ),
      ),
    );

    // ... (Existing breadcrumb logic logic but styled) ...
    // Re-implementing logic for cleaner code integration

    String? categoryId;
    String? gameTitleKey;
    String? gamePath;

    if (location.startsWith('/categories/')) {
      categoryId = location.split('/').last;
    } else if (location != '/') {
      // It's a game, find the category
      for (var entry in menuItemsConfig.entries) {
        for (var item in entry.value) {
          if (location == item.path || location.startsWith('${item.path}/')) {
            categoryId = entry.key;
            gameTitleKey = item.titleKey;
            gamePath = item.path;
            break;
          }
        }
        if (categoryId != null) break;
      }
    }

    if (categoryId != null) {
      final completion = progressProvider.gameCompletion[categoryId] ?? 0.0;
      breadcrumbs.add(
        const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
      );
      breadcrumbs.add(
        InkWell(
          onTap: () => context.go('/categories/$categoryId'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.get(categoryId),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    value: completion,
                    strokeWidth: 2,
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (gameTitleKey != null && gamePath != null) {
      final completion = progressProvider.gameCompletion[gamePath] ?? 0.0;
      breadcrumbs.add(
        const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
      );
      breadcrumbs.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Chip(
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            label: Text(loc.get(gameTitleKey)),
            avatar: CircularProgressIndicator(
              value: completion,
              strokeWidth: 2,
              backgroundColor: Colors.grey.shade300,
            ),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(mainAxisSize: MainAxisSize.min, children: breadcrumbs),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: loc.settings,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight:
            0, // Hide default AppBar but keep system UI overlay style
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          _buildBreadcrumbs(context),
          // Divider removed (border moved to breadcrumbs container)
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
