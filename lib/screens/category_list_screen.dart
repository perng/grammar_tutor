import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/menu_config.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/progress_provider.dart';

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

    // Using a GridView for a nicer presentation, or standard ListView
    return Scaffold(
      body: Consumer<ProgressProvider>(
        builder: (context, progressProvider, child) {
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: menuItemsConfig.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final categoryKey = menuItemsConfig.keys.elementAt(index);
              final title = loc.get(categoryKey);
              final completion =
                  progressProvider.gameCompletion[categoryKey] ?? 0.0;
              final percentage = (completion * 100).round();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  title: Text(
                    '$title ($percentage%)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    context.go('/categories/$categoryKey');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
