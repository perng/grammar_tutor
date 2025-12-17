import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuItem {
  final String title;
  final String path;
  const MenuItem(this.title, this.path);
}

const Map<String, List<MenuItem>> menuItems = {
  '單字': [
    MenuItem('單字學習', '/wordflash'),
    MenuItem('片語學習', '/phraseboss'),
    MenuItem('單字測驗', '/vocab-hero'),
  ],
  '文法': [
    MenuItem('單複數', '/singular-plural'),
    MenuItem('定冠詞', '/article-game'),
    MenuItem('所有冠詞', '/an-a-the'),
  ],
};

class HomeScreen extends StatefulWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _activeCategory;
  final String _prefKey = 'lastVisitedMenu';

  @override
  void initState() {
    super.initState();
    _loadLastVisited();
  }

  Future<void> _loadLastVisited() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVisited = prefs.getString(_prefKey);
    String initialCategory = '單字';

    if (lastVisited != null) {
      // Find category for last visited title
      for (var entry in menuItems.entries) {
        if (entry.value.any((item) => item.title == lastVisited)) {
          initialCategory = entry.key;
          break;
        }
      }
    } else {
      // Try to determine from current route if possible, or default
      // But initState runs once.
    }

    setState(() {
      _activeCategory = initialCategory;
    });
  }

  void _handleCategoryClick(String category) {
    setState(() {
      _activeCategory = category;
    });
  }

  void _handleSubMenuClick(MenuItem item) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, item.title);
    if (mounted) {
      context.go(item.path);
    }
  }

  // Helper to sync category with current route if needed
  // But purely UI state for menu is fine.

  @override
  Widget build(BuildContext context) {
    // Determine active route for styling
    final String location = GoRouterState.of(context).uri.toString();

    // If _activeCategory is not set yet, try to derive from location
    if (_activeCategory == null) {
      for (var entry in menuItems.entries) {
        if (entry.value.any((item) => item.path == location)) {
          _activeCategory = entry.key;
          break;
        }
      }
      _activeCategory ??= '單字';
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
                      // Categories
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: menuItems.keys.map((category) {
                            final isActive = _activeCategory == category;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: TextButton(
                                onPressed: () => _handleCategoryClick(category),
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
                                    Text(category),
                                    if (isActive)
                                      Container(
                                        height: 2,
                                        width: 40, // approximate width
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
                      if (_activeCategory != null)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: menuItems[_activeCategory]!.map((item) {
                              final isActive = location == item.path;
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
                                      item.title,
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
