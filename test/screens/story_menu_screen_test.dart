import 'dart:typed_data'; // Added for ByteData
import 'package:flutter/services.dart'; // Added for AssetBundle
import 'package:mobile_app/screens/games/shared/story_menu_screen.dart';
import 'package:mobile_app/providers/progress_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    print('TestAssetBundle.loadString called with key: "$key"');
    if (key == 'assets/data/test_levels.json') {
      return '''
[
  {
    "id": "1",
    "title": "Level 1",
    "content": "Test content 1",
    "explanation-zh-TW": "Expl 1 TW",
    "explanation-zh-CN": "Expl 1 CN",
    "explanation-en-US": "Expl 1 US"
  },
  {
    "id": "2",
    "title": "Level 2",
    "content": "Test content 2",
    "explanation-zh-TW": "Expl 2 TW",
    "explanation-zh-CN": "Expl 2 CN",
    "explanation-en-US": "Expl 2 US"
  }
]
''';
    }
    print('TestAssetBundle returning empty list for key: "$key"');
    return '[]';
  }

  @override
  Future<ByteData> load(String key) async {
    return ByteData(0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('StoryMenuScreen loads levels and updates progress', (
    WidgetTester tester,
  ) async {
    // 1. Setup Providers and Router
    final progressProvider = ProgressProvider();

    // We need a router to handle push
    final router = GoRouter(
      initialLocation: '/menu',
      routes: [
        GoRoute(
          path: '/menu',
          builder: (context, state) => StoryMenuScreen(
            title: 'Test Menu',
            assetPath: 'assets/data/test_levels.json',
            routePrefix: '/menu',
            progressKeyPrefix: 'test_prefix',
            assetBundle: TestAssetBundle(),
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Game Screen')),
                  body: ElevatedButton(
                    onPressed: () async {
                      // Simulate completing the game
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('test_prefix-0', '100');
                      // Force delay to ensure write completes before pop
                      await Future.delayed(const Duration(milliseconds: 50));
                      if (context.mounted) context.pop();
                    },
                    child: const Text('Complete Level'),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: progressProvider)],
        child: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );

    // 2. Wait for levels to load
    await tester.pumpAndSettle();

    // Verify levels are visible
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Level 2'), findsOneWidget);

    // Verify initial state (no completion checkmark)
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.text('(100.0%)'), findsNothing);

    // 3. Tap on Level 1
    await tester.tap(find.text('Level 1'));
    await tester.pumpAndSettle();

    // Verify we are on Game Screen
    expect(find.text('Game Screen'), findsOneWidget);

    // 4. Complete Level (tap button that sets prefs and pops)
    await tester.tap(find.text('Complete Level'));

    // Pump to process the tap and the await in the button handler
    await tester.pumpAndSettle();

    // Verify we are back on Menu
    expect(find.text('Test Menu'), findsOneWidget);

    // 5. Verify progress updated
    // The menu screen's _loadLevels should have been called upon return.
    // It should have reloaded prefs and called setState.

    // Wait one more frame if necessary? pumpAndSettle should cover it.

    // Check for "100.0%" text or Check circle
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
