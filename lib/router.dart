import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home/home_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/game_list_screen.dart';

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

GoRouter createRouter(String initialLocation, SharedPreferences prefs) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return HomeScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const CategoryListScreen(),
          ),
          GoRoute(
            path: '/categories/:categoryId',
            builder: (context, state) {
              final categoryId = state.pathParameters['categoryId']!;
              return GameListScreen(categoryId: categoryId);
            },
          ),
          GoRoute(
            path: '/singular-plural',
            builder: (context, state) => const StoryMenuScreen(
              title: 'One or Many',
              assetPath: 'assets/data/singular.json',
              routePrefix: '/singular-plural',
              progressKeyPrefix: 'singular',
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
              progressKeyPrefix: 'articles',
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
              progressKeyPrefix: 'an_a_the',
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
              progressKeyPrefix: 'verbs',
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
              progressKeyPrefix: 'be_verb_adjectives',
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
              progressKeyPrefix: 'question_formation',
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
              progressKeyPrefix: 'prepositions',
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
              progressKeyPrefix: 'pronouns',
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

          GoRoute(
            path: '/future-tenses',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Future Tenses',
              assetPath: 'assets/data/future_tenses.json',
              routePrefix: '/future-tenses',
              progressKeyPrefix: 'future_tenses',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/future_tenses.json',
                    routePrefix: '/future-tenses',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/past-tenses',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Past Tenses',
              assetPath: 'assets/data/past_tenses.json',
              routePrefix: '/past-tenses',
              progressKeyPrefix: 'past_tenses',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/past_tenses.json',
                    routePrefix: '/past-tenses',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/subjunctive-mood',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Subjunctive Mood',
              assetPath: 'assets/data/subjunctive_mood.json',
              routePrefix: '/subjunctive-mood',
              progressKeyPrefix: 'subjunctive_mood',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/subjunctive_mood.json',
                    routePrefix: '/subjunctive-mood',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/imperative-mood',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Imperative Mood',
              assetPath: 'assets/data/imperative_mood.json',
              routePrefix: '/imperative-mood',
              progressKeyPrefix: 'imperative_mood',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/imperative_mood.json',
                    routePrefix: '/imperative-mood',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/possessive-nouns',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Possessive Nouns',
              assetPath: 'assets/data/possessive_nouns.json',
              routePrefix: '/possessive-nouns',
              progressKeyPrefix: 'possessive_nouns',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/possessive_nouns.json',
                    routePrefix: '/possessive-nouns',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/adjectives',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Adjectives',
              assetPath: 'assets/data/adjectives.json',
              routePrefix: '/adjectives',
              progressKeyPrefix: 'adjectives',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/adjectives.json',
                    routePrefix: '/adjectives',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/comparisons',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Comparisons',
              assetPath: 'assets/data/comparisons.json',
              routePrefix: '/comparisons',
              progressKeyPrefix: 'comparisons',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/comparisons.json',
                    routePrefix: '/comparisons',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/adverbs',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Adverbs',
              assetPath: 'assets/data/adverbs.json',
              routePrefix: '/adverbs',
              progressKeyPrefix: 'adverbs',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/adverbs.json',
                    routePrefix: '/adverbs',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/conjunctions',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Conjunctions',
              assetPath: 'assets/data/conjunctions.json',
              routePrefix: '/conjunctions',
              progressKeyPrefix: 'conjunctions',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/conjunctions.json',
                    routePrefix: '/conjunctions',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/tag-questions',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Tag Questions',
              assetPath: 'assets/data/tag_questions.json',
              routePrefix: '/tag-questions',
              progressKeyPrefix: 'tag_questions',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/tag_questions.json',
                    routePrefix: '/tag-questions',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/negatives',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Negatives',
              assetPath: 'assets/data/negatives.json',
              routePrefix: '/negatives',
              progressKeyPrefix: 'negatives',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/negatives.json',
                    routePrefix: '/negatives',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/present-continuous',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Present Continuous',
              assetPath: 'assets/data/present_continuous.json',
              routePrefix: '/present-continuous',
              progressKeyPrefix: 'present_continuous',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/present_continuous.json',
                    routePrefix: '/present-continuous',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/other-pronouns',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Other Pronouns',
              assetPath: 'assets/data/other_pronouns.json',
              routePrefix: '/other-pronouns',
              progressKeyPrefix: 'other_pronouns',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/other_pronouns.json',
                    routePrefix: '/other-pronouns',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/determiners',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Determiners',
              assetPath: 'assets/data/determiners.json',
              routePrefix: '/determiners',
              progressKeyPrefix: 'determiners',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/determiners.json',
                    routePrefix: '/determiners',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/adjective-order',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Adjective Order',
              assetPath: 'assets/data/adjective_order.json',
              routePrefix: '/adjective-order',
              progressKeyPrefix: 'adjective_order',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/adjective_order.json',
                    routePrefix: '/adjective-order',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/construction-patterns',
            builder: (context, state) => const StoryMenuScreen(
              title: 'Construction Patterns',
              assetPath: 'assets/data/construction_patterns.json',
              routePrefix: '/construction-patterns',
              progressKeyPrefix: 'construction_patterns',
            ),
            routes: [
              GoRoute(
                path: ':levelId',
                builder: (context, state) {
                  final levelIdStr = state.pathParameters['levelId']!;
                  final int levelIndex = int.tryParse(levelIdStr) ?? 0;
                  return GenericGameScreen(
                    levelIndex: levelIndex,
                    assetPath: 'assets/data/construction_patterns.json',
                    routePrefix: '/construction-patterns',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );

  router.routerDelegate.addListener(() {
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    prefs.setString('last_route', location);
  });

  return router;
}
