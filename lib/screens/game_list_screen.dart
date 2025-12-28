import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/menu_config.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/progress_provider.dart';

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

    if (items == null) {
      return Scaffold(
        body: Center(child: Text('Category not found: ${widget.categoryId}')),
      );
    }

    return Scaffold(
      body: Consumer<ProgressProvider>(
        builder: (context, progressProvider, child) {
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: items.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final title = loc.get(item.titleKey);
              final completion =
                  progressProvider.gameCompletion[item.path] ?? 0.0;
              final percentage = (completion * 100).round();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    context.go(item.path);
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    title: Text(
                      '$title ($percentage%)',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
