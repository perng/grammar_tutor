import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/story_level.dart';
import '../providers/locale_provider.dart';

class ExplanationDialog {
  static Future<void> show(
    BuildContext context,
    String assetPath,
    String currentPath,
  ) async {
    try {
      // Convert data path to explanation path
      // assets/data/xyz.json -> assets/explanations/xyz.json
      final String explanationPath = assetPath.replaceAll(
        'assets/data/',
        'assets/explanations/',
      );

      final String response = await rootBundle.loadString(explanationPath);
      final Map<String, dynamic> data = json.decode(response);
      final Map<String, dynamic> contentMap = data['content'] ?? {};

      if (!context.mounted) return;

      final loc = AppLocalizations.of(context);

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(loc.get('explanation')),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Builder(
                  builder: (context) {
                    final locale = Provider.of<LocaleProvider>(
                      context,
                      listen: false,
                    ).locale;

                    String content = '';
                    if (locale.languageCode == 'zh') {
                      if (locale.countryCode == 'CN' ||
                          locale.scriptCode == 'Hans') {
                        content =
                            contentMap['zh_CN'] ?? contentMap['zh_TW'] ?? '';
                      } else {
                        content =
                            contentMap['zh_TW'] ?? contentMap['zh_CN'] ?? '';
                      }
                    } else {
                      content = contentMap['en'] ?? '';
                    }

                    if (content.isEmpty) {
                      return const Text('Explanation coming soon!');
                    }

                    return MarkdownBody(data: content, selectable: true);
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.get('close')),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        // Fallback or error message
        // If file not found, maybe show a friendly message?
        String message = 'Explanation not available yet.';
        // Check for asset not found error
        if (e.toString().contains('Unable to load asset')) {
          // File doesn't exist, use default message
        } else {
          message = 'Error: $e';
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Info'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }
}
