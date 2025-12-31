import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../config/menu_config.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/pie_chart_painter.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                onTap: () {
                  Provider.of<LocaleProvider>(
                    context,
                    listen: false,
                  ).setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('繁體中文'),
                onTap: () {
                  Provider.of<LocaleProvider>(
                    context,
                    listen: false,
                  ).setLocale(const Locale('zh', 'TW'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('简体中文'),
                onTap: () {
                  Provider.of<LocaleProvider>(
                    context,
                    listen: false,
                  ).setLocale(const Locale('zh', 'CN'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final location = GoRouterState.of(context).uri.toString();
    final progressProvider = Provider.of<ProgressProvider>(context);
    List<Widget> breadcrumbs = [];

    // Home Emoji
    breadcrumbs.add(
      TextButton(
        onPressed: () => context.go('/'),
        child: const Text('🏠', style: TextStyle(fontSize: 20)),
      ),
    );

    // Identify Category and Game
    // Identify Category and Game
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
      breadcrumbs.add(const Text('>', style: TextStyle(color: Colors.grey)));
      breadcrumbs.add(
        TextButton(
          onPressed: () => context.go('/categories/$categoryId'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.get(categoryId),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              CustomPaint(
                size: const Size(16, 16),
                painter: PieChartPainter(
                  percentage: completion,
                  color: Colors.green,
                  bgColor: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (gameTitleKey != null && gamePath != null) {
      final completion = progressProvider.gameCompletion[gamePath] ?? 0.0;
      breadcrumbs.add(const Text('>', style: TextStyle(color: Colors.grey)));
      breadcrumbs.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Text(
                loc.get(gameTitleKey),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              CustomPaint(
                size: const Size(16, 16),
                painter: PieChartPainter(
                  percentage: completion,
                  color: Colors.blue,
                  bgColor: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Add spacer to push settings to the right
    breadcrumbs.add(const Spacer());

    breadcrumbs.add(
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: _showLanguageDialog,
        tooltip: loc.settings,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: Colors.grey.shade100,
      child: Row(children: breadcrumbs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(bottom: false, child: _buildBreadcrumbs(context)),
          const Divider(height: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
