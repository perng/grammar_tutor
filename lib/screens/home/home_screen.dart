import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
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
  Map<String, double> _gameCompletion = {};

  final Map<String, String> _itemPathToAsset = {
    '/singular-plural': 'assets/data/singular.json',
    '/article-game': 'assets/data/articles.json',
    '/an-a-the': 'assets/data/fruits.json',
    '/verb-game': 'assets/data/verbs.json',
    '/be-verb-game': 'assets/data/be_verb_adjectives.json',
    '/question-game': 'assets/data/question_formation.json',
    '/preposition-game': 'assets/data/prepositions.json',
    '/pronoun-game': 'assets/data/pronouns.json',
    '/present-perfect': 'assets/data/present_perfect.json',
    '/conditionals': 'assets/data/conditionals.json',
    '/modals': 'assets/data/modals.json',
    '/gerunds-infinitives': 'assets/data/gerunds_infinitives.json',
    '/phrasal-verbs': 'assets/data/phrasal_verbs.json',
    '/passive-voice': 'assets/data/passive_voice.json',
    '/relative-clauses': 'assets/data/relative_clauses.json',
    '/transitive-intransitive': 'assets/data/transitive_intransitive.json',
    '/countable-uncountable': 'assets/data/countable_uncountable.json',
  };

  @override
  void initState() {
    super.initState();
    _loadLastVisited();
    _calculateGameProgress();
  }

  Future<void> _calculateGameProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, double> newCompletion = {};

    for (var entry in _itemPathToAsset.entries) {
      String routerPath = entry.key;
      String assetPath = entry.value;

      try {
        final String response = await rootBundle.loadString(assetPath);
        final List<dynamic> data = json.decode(response);
        int totalLevels = data.length;
        if (totalLevels == 0) {
          newCompletion[routerPath] = 0.0;
          continue;
        }

        String keyBase = assetPath
            .replaceAll('assets/data/', '')
            .replaceAll('.json', '');

        double totalScore = 0;

        for (int i = 0; i < totalLevels; i++) {
          final String key = '$keyBase-$i';
          final String? val = prefs.getString(key);
          if (val != null) {
            int score = int.tryParse(val) ?? 0;
            totalScore += score;
          }
        }

        newCompletion[routerPath] = totalScore / (totalLevels * 100.0);
      } catch (e) {
        debugPrint("Error loading progress for $routerPath: $e");
        newCompletion[routerPath] = 0.0;
      }
    }

    // Calculate progress for each category
    for (var entry in menuItemsConfig.entries) {
      String categoryKey = entry.key;
      List<MenuItem> items = entry.value;
      if (items.isEmpty) {
        newCompletion[categoryKey] = 0.0;
        continue;
      }

      double totalCategoryProgress = 0.0;
      int gameCount = 0;

      for (var item in items) {
        totalCategoryProgress += newCompletion[item.path] ?? 0.0;
        gameCount++;
      }

      if (gameCount > 0) {
        newCompletion[categoryKey] = totalCategoryProgress / gameCount;
      } else {
        newCompletion[categoryKey] = 0.0;
      }
    }

    if (mounted) {
      setState(() {
        _gameCompletion = newCompletion;
      });
    }
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
      // Re-calculate progress after small delay to catch updates
      Future.delayed(const Duration(seconds: 1), _calculateGameProgress);
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
                            final completion =
                                _gameCompletion[categoryKey] ?? 0.0;
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
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(loc.get(categoryKey)),
                                        if (completion > 0) ...[
                                          const SizedBox(width: 6),
                                          CustomPaint(
                                            size: const Size(12, 12),
                                            painter: PieChartPainter(
                                              percentage: completion,
                                              color: isActive
                                                  ? Colors.black
                                                  : Colors.grey,
                                              bgColor: Colors.grey.shade300,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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
                              final completion =
                                  _gameCompletion[item.path] ?? 0.0;

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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          loc.get(item.titleKey),
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: isActive
                                                ? Colors.black
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Tiny Pie Chart
                                        CustomPaint(
                                          size: const Size(12, 12),
                                          painter: PieChartPainter(
                                            percentage: completion,
                                            color: isActive
                                                ? Colors.blue.shade700
                                                : Colors.grey.shade500,
                                            bgColor: Colors.grey.shade300,
                                          ),
                                        ),
                                      ],
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

class PieChartPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color bgColor;

  PieChartPainter({
    required this.percentage,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()..color = bgColor;
    canvas.drawCircle(center, radius, bgPaint);

    // Foreground pie
    if (percentage > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2, // Start at -90 degrees (12 o'clock)
        2 * 3.14159 * percentage,
        true, // Use center for pie slice
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.color != color ||
        oldDelegate.bgColor != bgColor;
  }
}
