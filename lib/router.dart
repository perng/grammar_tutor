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
import 'screens/games/verb_game/game_screen.dart';
import 'screens/games/be_verb_game/game_screen.dart';
import 'screens/games/question_game/game_screen.dart';
import 'screens/games/preposition_game/game_screen.dart';
import 'screens/games/pronoun_game/game_screen.dart';
import 'screens/games/shared/generic_game_screen.dart';

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
        GoRoute(
          path: '/verb-game',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Verb Tenses',
            assetPath: 'assets/data/verbs.json',
            routePrefix: '/verb-game',
            progressKeyPrefix: 'verb-game',
          ),
        ),
        GoRoute(
          path: '/be-verb-game',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Be Verbs',
            assetPath: 'assets/data/be_verb_adjectives.json',
            routePrefix: '/be-verb-game',
            progressKeyPrefix: 'be-verb-game',
          ),
        ),
        GoRoute(
          path: '/question-game',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Question Formation',
            assetPath: 'assets/data/question_formation.json',
            routePrefix: '/question-game',
            progressKeyPrefix: 'question-game',
          ),
        ),
        GoRoute(
          path: '/preposition-game',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Prepositions (In/On/At)',
            assetPath: 'assets/data/prepositions.json',
            routePrefix: '/preposition-game',
            progressKeyPrefix: 'preposition-game',
          ),
        ),
        GoRoute(
          path: '/pronoun-game',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Pronouns (He/She/It)',
            assetPath: 'assets/data/pronouns.json',
            routePrefix: '/pronoun-game',
            progressKeyPrefix: 'pronoun-game',
          ),
        ),
        GoRoute(
          path: '/present-perfect',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Present Perfect',
            assetPath: 'assets/data/present_perfect.json',
            routePrefix: '/present-perfect',
            progressKeyPrefix: 'present_perfect',
          ),
        ),
        GoRoute(
          path: '/conditionals',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Conditionals',
            assetPath: 'assets/data/conditionals.json',
            routePrefix: '/conditionals',
            progressKeyPrefix: 'conditionals',
          ),
        ),
        GoRoute(
          path: '/modals',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Modals',
            assetPath: 'assets/data/modals.json',
            routePrefix: '/modals',
            progressKeyPrefix: 'modals',
          ),
        ),
        GoRoute(
          path: '/gerunds-infinitives',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Gerunds vs Infinitives',
            assetPath: 'assets/data/gerunds_infinitives.json',
            routePrefix: '/gerunds-infinitives',
            progressKeyPrefix: 'gerunds_infinitives',
          ),
        ),
        GoRoute(
          path: '/phrasal-verbs',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Phrasal Verbs',
            assetPath: 'assets/data/phrasal_verbs.json',
            routePrefix: '/phrasal-verbs',
            progressKeyPrefix: 'phrasal_verbs',
          ),
        ),
        GoRoute(
          path: '/passive-voice',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Passive Voice',
            assetPath: 'assets/data/passive_voice.json',
            routePrefix: '/passive-voice',
            progressKeyPrefix: 'passive_voice',
          ),
        ),
        GoRoute(
          path: '/relative-clauses',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Relative Clauses',
            assetPath: 'assets/data/relative_clauses.json',
            routePrefix: '/relative-clauses',
            progressKeyPrefix: 'relative_clauses',
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
    GoRoute(
      path: '/verb-game/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return VerbGameScreen(
          levelIndex: levelIndex,
          routePrefix: '/verb-game',
        );
      },
    ),
    GoRoute(
      path: '/be-verb-game/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return BeVerbGameScreen(levelIndex: levelIndex);
      },
    ),
    GoRoute(
      path: '/question-game/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return QuestionGameScreen(levelIndex: levelIndex);
      },
    ),
    GoRoute(
      path: '/preposition-game/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return PrepositionGameScreen(levelIndex: levelIndex);
      },
    ),
    GoRoute(
      path: '/pronoun-game/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return PronounGameScreen(levelIndex: levelIndex);
      },
    ),
    GoRoute(
      path: '/present-perfect/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return GenericGameScreen(
          levelIndex: levelIndex,
          assetPath: 'assets/data/present_perfect.json',
          routePrefix: '/present-perfect',
        );
      },
    ),
    GoRoute(
      path: '/conditionals/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return GenericGameScreen(
          levelIndex: levelIndex,
          assetPath: 'assets/data/conditionals.json',
          routePrefix: '/conditionals',
        );
      },
    ),
    GoRoute(
      path: '/modals/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return GenericGameScreen(
          levelIndex: levelIndex,
          assetPath: 'assets/data/modals.json',
          routePrefix: '/modals',
        );
      },
    ),
    GoRoute(
      path: '/gerunds-infinitives/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return GenericGameScreen(
          levelIndex: levelIndex,
          assetPath: 'assets/data/gerunds_infinitives.json',
          routePrefix: '/gerunds-infinitives',
        );
      },
    ),
    GoRoute(
      path: '/phrasal-verbs/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return GenericGameScreen(
          levelIndex: levelIndex,
          assetPath: 'assets/data/phrasal_verbs.json',
          routePrefix: '/phrasal-verbs',
        );
      },
    ),
    GoRoute(
      path: '/passive-voice/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return GenericGameScreen(
          levelIndex: levelIndex,
          assetPath: 'assets/data/passive_voice.json',
          routePrefix: '/passive-voice',
        );
      },
    ),
    GoRoute(
      path: '/relative-clauses/:levelId',
      builder: (context, state) {
        final levelIdStr = state.pathParameters['levelId']!;
        final int levelIndex = int.tryParse(levelIdStr) ?? 0;
        return GenericGameScreen(
          levelIndex: levelIndex,
          assetPath: 'assets/data/relative_clauses.json',
          routePrefix: '/relative-clauses',
        );
      },
    ),
    // ... add other game play routes later
  ],
);
