import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

class MenuItem {
  final String titleKey;
  final String path;
  const MenuItem(this.titleKey, this.path);
}

const Map<String, List<MenuItem>> menuItemsConfig = {
  'category_articles': [
    MenuItem('game_def_article', '/article-game'),
    MenuItem('game_all_articles', '/an-a-the'),
  ],
  'category_nouns_pronouns': [
    MenuItem('game_singular', '/singular-plural'),
    MenuItem('game_pronouns', '/pronoun-game'),
    MenuItem('game_countable', '/countable-uncountable'),
  ],
  'category_prepositions': [MenuItem('game_prepositions', '/preposition-game')],
  'category_verbs': [
    MenuItem('game_be_verb', '/be-verb-game'),
    MenuItem('game_transitive', '/transitive-intransitive'),
    MenuItem('game_modals', '/modals'),
    MenuItem('game_gerunds', '/gerunds-infinitives'),
    MenuItem('game_phrasal', '/phrasal-verbs'),
  ],
  'category_tenses': [
    MenuItem('game_tenses', '/verb-game'),
    MenuItem('game_present_perfect', '/present-perfect'),
    MenuItem('game_passive', '/passive-voice'),
  ],
  'category_structure': [
    MenuItem('game_questions', '/question-game'),
    MenuItem('game_conditionals', '/conditionals'),
    MenuItem('game_relative', '/relative-clauses'),
  ],
};

class HomeScreen extends StatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _activeCategoryKey;
  final String _prefKey = 'lastVisitedMenuKey';

  @override
  void initState() {
    super.initState();
    _loadLastVisited();
  }

  Future<void> _loadLastVisited() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVisitedKey = prefs.getString(_prefKey);
    String initialCategoryKey = 'category_articles';

    if (lastVisitedKey != null) {
      // Find category for last visited title key
      for (var entry in menuItemsConfig.entries) {
        if (entry.value.any((item) => item.titleKey == lastVisitedKey)) {
          initialCategoryKey = entry.key;
          break;
        }
      }
    }

    if (mounted) {
      setState(() {
        _activeCategoryKey = initialCategoryKey;
      });
    }
  }

  void _handleCategoryClick(String categoryKey) async {
    final prefs = await SharedPreferences.getInstance();
    String? requiredPath = prefs.getString('usage_last_path_$categoryKey');

    // If no history for this category, default to first item
    if (requiredPath == null) {
      if (menuItemsConfig[categoryKey] != null &&
          menuItemsConfig[categoryKey]!.isNotEmpty) {
        requiredPath = menuItemsConfig[categoryKey]!.first.path;
      }
    }

    setState(() {
      _activeCategoryKey = categoryKey;
    });

    if (requiredPath != null && mounted) {
      context.go(requiredPath); // Navigate to the menu screen of the game
    }
  }

  void _handleSubMenuClick(MenuItem item) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, item.titleKey);

    // Save this path as the last visited for its category
    String? categoryKey;
    for (var entry in menuItemsConfig.entries) {
      if (entry.value.any((i) => i.path == item.path)) {
        categoryKey = entry.key;
        break;
      }
    }
    if (categoryKey != null) {
      await prefs.setString('usage_last_path_$categoryKey', item.path);
    }

    // Navigate to last played level or first level
    final String lastPlayedKey = 'last_played_index_${item.path}';
    final int lastIndex = prefs.getInt(lastPlayedKey) ?? 0;

    if (mounted) {
      context.go('${item.path}/$lastIndex');
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // Determine active route for styling
    final String location = GoRouterState.of(context).uri.toString();

    // If _activeCategoryKey is not set yet, try to derive from location
    if (_activeCategoryKey == null) {
      for (var entry in menuItemsConfig.entries) {
        if (entry.value.any(
          (item) =>
              item.path == location || location.startsWith('${item.path}/'),
        )) {
          _activeCategoryKey = entry.key;
          break;
        }
      }
      _activeCategoryKey ??= 'category_articles';
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Container(),
                          ), // Spacer to center categories roughly if needed, or just push settings to right
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: _showLanguageDialog,
                            tooltip: loc.settings,
                          ),
                        ],
                      ),
                      // Categories
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: menuItemsConfig.keys.map((categoryKey) {
                            final isActive = _activeCategoryKey == categoryKey;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: TextButton(
                                onPressed: () =>
                                    _handleCategoryClick(categoryKey),
                                style: TextButton.styleFrom(
                                  foregroundColor: isActive
                                      ? Colors.black
                                      : Colors.grey,
                                  textStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(loc.get(categoryKey)),
                                    if (isActive)
                                      Container(
                                        height: 2,
                                        width: 40,
                                        color: Colors.black,
                                        margin: const EdgeInsets.only(top: 4),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Submenu
                      if (_activeCategoryKey != null)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: menuItemsConfig[_activeCategoryKey]!.map((
                              item,
                            ) {
                              final isActive =
                                  location == item.path ||
                                  location.startsWith('${item.path}/');
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                ),
                                child: InkWell(
                                  onTap: () => _handleSubMenuClick(item),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: isActive
                                        ? BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          )
                                        : null,
                                    child: Text(
                                      loc.get(item.titleKey),
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isActive
                                            ? Colors.black
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),
          ];
        },
        body: widget.child,
      ),
    );
  }
}
