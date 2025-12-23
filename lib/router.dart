import 'package:go_router/go_router.dart';
import 'screens/home/home_screen.dart';

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
  initialLocation: '/singular-plural',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return HomeScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/singular-plural',
          builder: (context, state) => const StoryMenuScreen(
            title: 'One or Many',
            assetPath: 'assets/data/singular.json',
            routePrefix: '/singular-plural',
            progressKeyPrefix: 'singular-plural',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
              builder: (context, state) {
                final levelIdStr = state.pathParameters['levelId']!;
                final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                return SingularPluralGameScreen(levelIndex: levelIndex);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/article-game',
          builder: (context, state) => const StoryMenuScreen(
            title: 'The Game',
            assetPath: 'assets/data/articles.json',
            routePrefix: '/article-game',
            progressKeyPrefix: 'article-game',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
              builder: (context, state) {
                final levelIdStr = state.pathParameters['levelId']!;
                final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                return ArticleGameScreen(levelIndex: levelIndex);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/an-a-the',
          builder: (context, state) => const StoryMenuScreen(
            title: 'A, An, or The',
            assetPath: 'assets/data/an_a_the.json',
            routePrefix: '/an-a-the',
            progressKeyPrefix: 'an-a-the',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
              builder: (context, state) {
                final levelIdStr = state.pathParameters['levelId']!;
                final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                return AnATheGameScreen(levelIndex: levelIndex);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/verb-game',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Verb Tenses',
            assetPath: 'assets/data/verbs.json',
            routePrefix: '/verb-game',
            progressKeyPrefix: 'verb-game',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
              builder: (context, state) {
                final levelIdStr = state.pathParameters['levelId']!;
                final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                return VerbGameScreen(
                  levelIndex: levelIndex,
                  routePrefix: '/verb-game',
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/be-verb-game',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Be Verbs',
            assetPath: 'assets/data/be_verb_adjectives.json',
            routePrefix: '/be-verb-game',
            progressKeyPrefix: 'be-verb-game',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
              builder: (context, state) {
                final levelIdStr = state.pathParameters['levelId']!;
                final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                return BeVerbGameScreen(levelIndex: levelIndex);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/question-game',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Question Formation',
            assetPath: 'assets/data/question_formation.json',
            routePrefix: '/question-game',
            progressKeyPrefix: 'question-game',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
              builder: (context, state) {
                final levelIdStr = state.pathParameters['levelId']!;
                final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                return QuestionGameScreen(
                  levelIndex: levelIndex,
                  routePrefix: '/question-game',
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/preposition-game',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Prepositions (In/On/At)',
            assetPath: 'assets/data/prepositions.json',
            routePrefix: '/preposition-game',
            progressKeyPrefix: 'preposition-game',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
              builder: (context, state) {
                final levelIdStr = state.pathParameters['levelId']!;
                final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                return PrepositionGameScreen(levelIndex: levelIndex);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/pronoun-game',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Pronouns (He/She/It)',
            assetPath: 'assets/data/pronouns.json',
            routePrefix: '/pronoun-game',
            progressKeyPrefix: 'pronoun-game',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
              builder: (context, state) {
                final levelIdStr = state.pathParameters['levelId']!;
                final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                return PronounGameScreen(levelIndex: levelIndex);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/present-perfect',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Present Perfect',
            assetPath: 'assets/data/present_perfect.json',
            routePrefix: '/present-perfect',
            progressKeyPrefix: 'present_perfect',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
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
          ],
        ),
        GoRoute(
          path: '/conditionals',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Conditionals',
            assetPath: 'assets/data/conditionals.json',
            routePrefix: '/conditionals',
            progressKeyPrefix: 'conditionals',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
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
          ],
        ),
        GoRoute(
          path: '/modals',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Modals',
            assetPath: 'assets/data/modals.json',
            routePrefix: '/modals',
            progressKeyPrefix: 'modals',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
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
          ],
        ),
        GoRoute(
          path: '/gerunds-infinitives',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Gerunds vs Infinitives',
            assetPath: 'assets/data/gerunds_infinitives.json',
            routePrefix: '/gerunds-infinitives',
            progressKeyPrefix: 'gerunds_infinitives',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
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
          ],
        ),
        GoRoute(
          path: '/phrasal-verbs',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Phrasal Verbs',
            assetPath: 'assets/data/phrasal_verbs.json',
            routePrefix: '/phrasal-verbs',
            progressKeyPrefix: 'phrasal_verbs',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
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
          ],
        ),
        GoRoute(
          path: '/passive-voice',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Passive Voice',
            assetPath: 'assets/data/passive_voice.json',
            routePrefix: '/passive-voice',
            progressKeyPrefix: 'passive_voice',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
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
          ],
        ),
        GoRoute(
          path: '/relative-clauses',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Relative Clauses',
            assetPath: 'assets/data/relative_clauses.json',
            routePrefix: '/relative-clauses',
            progressKeyPrefix: 'relative_clauses',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
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
          ],
        ),
        GoRoute(
          path: '/transitive-intransitive',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Transitive or Intransitive',
            assetPath: 'assets/data/transitive_intransitive.json',
            routePrefix: '/transitive-intransitive',
            progressKeyPrefix: 'transitive_intransitive',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
              builder: (context, state) {
                final levelIdStr = state.pathParameters['levelId']!;
                final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                return GenericGameScreen(
                  levelIndex: levelIndex,
                  assetPath: 'assets/data/transitive_intransitive.json',
                  routePrefix: '/transitive-intransitive',
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/countable-uncountable',
          builder: (context, state) => const StoryMenuScreen(
            title: 'Countable or Uncountable',
            assetPath: 'assets/data/countable_uncountable.json',
            routePrefix: '/countable-uncountable',
            progressKeyPrefix: 'countable_uncountable',
          ),
          routes: [
            GoRoute(
              path: ':levelId',
              builder: (context, state) {
                final levelIdStr = state.pathParameters['levelId']!;
                final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                return GenericGameScreen(
                  levelIndex: levelIndex,
                  assetPath: 'assets/data/countable_uncountable.json',
                  routePrefix: '/countable-uncountable',
                );
              },
            ),
          ],
        ),
      ],
    ),
    // ... add other game play routes later
  ],
);
