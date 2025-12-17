import 'package:go_router/go_router.dart';
import 'screens/home/home_screen.dart';

import 'screens/games/word_flash/menu_screen.dart';
import 'screens/games/word_flash/game_screen.dart';
import 'screens/games/vocab_hero/menu_screen.dart';
import 'screens/games/vocab_hero/game_screen.dart';
import 'screens/games/shared/story_menu_screen.dart';
import 'screens/games/singular_plural/game_screen.dart';
import 'screens/games/article_game/game_screen.dart';
import 'screens/games/an_a_the_game/game_screen.dart';

final router = GoRouter(
  initialLocation: '/wordflash',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return HomeScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/wordflash',
          builder: (context, state) => const WordFlashMenuScreen(),
        ),
        GoRoute(
          path: '/vocab-hero',
          builder: (context, state) => const VocabHeroMenuScreen(),
        ),
        GoRoute(
          path: '/phraseboss',
          builder: (context, state) =>
              const WordFlashMenuScreen(gameType: 'phraseboss'),
        ),
        GoRoute(
          path: '/singular-plural',
          builder: (context, state) => const StoryMenuScreen(
            title: 'One or Many',
            assetPath: 'assets/data/singular.json',
            routePrefix: '/singular-plural',
            progressKeyPrefix: 'singular-plural',
          ),
        ),
        GoRoute(
          path: '/article-game',
          builder: (context, state) => const StoryMenuScreen(
            title: 'The Game',
            assetPath: 'assets/data/articles.json',
            routePrefix: '/article-game',
            progressKeyPrefix: 'article-game',
          ),
        ),
        GoRoute(
          path: '/an-a-the',
          builder: (context, state) => const StoryMenuScreen(
            title: 'A, An, or The',
            assetPath: 'assets/data/fruits.json',
            routePrefix: '/an-a-the',
            progressKeyPrefix: 'an-a-the',
          ),
        ),
      ],
    ),
    // Full screen game routes
    GoRoute(
      path: '/wordflash/:levelId',
      builder: (context, state) {
        final levelId = state.pathParameters['levelId']!;
        return WordFlashGameScreen(levelId: levelId, gameType: 'wordflash');
      },
    ),
    GoRoute(
      path: '/phraseboss/:levelId',
      builder: (context, state) {
        final levelId = state.pathParameters['levelId']!;
        return WordFlashGameScreen(levelId: levelId, gameType: 'phraseboss');
      },
    ),
    GoRoute(
      path: '/vocab-hero/:levelId',
      builder: (context, state) {
        final levelId = state.pathParameters['levelId']!;
        return VocabHeroGameScreen(levelId: levelId);
      },
    ),
    GoRoute(
      path: '/singular-plural/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return SingularPluralGameScreen(levelIndex: levelIndex);
      },
    ),
    GoRoute(
      path: '/article-game/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return ArticleGameScreen(levelIndex: levelIndex);
      },
    ),
    GoRoute(
      path: '/an-a-the/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return AnATheGameScreen(levelIndex: levelIndex);
      },
    ),
    // ... add other game play routes later
  ],
);
