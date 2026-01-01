import 'package:flutter/material.dart';

class MenuItem {
  final String titleKey;
  final String path;
  final String assetPath;
  final IconData icon;
  const MenuItem(
    this.titleKey,
    this.path,
    this.assetPath, {
    this.icon = Icons.gamepad,
  });
}

const Map<String, List<MenuItem>> menuItemsConfig = {
  'category_tenses': [
    MenuItem(
      'game_be_verb',
      '/be-verb-game',
      'assets/data/be_verb_adjectives.json',
      icon: Icons.person_outline,
    ),
    MenuItem(
      'game_tenses',
      '/verb-game',
      'assets/data/verbs.json',
      icon: Icons.access_time,
    ),
    MenuItem(
      'game_present_continuous',
      '/present-continuous',
      'assets/data/present_continuous.json',
      icon: Icons.run_circle_outlined,
    ),
    MenuItem(
      'game_present_perfect',
      '/present-perfect',
      'assets/data/present_perfect.json',
      icon: Icons.done_all,
    ),
    MenuItem(
      'game_past',
      '/past-tenses',
      'assets/data/past_tenses.json',
      icon: Icons.history,
    ),
    MenuItem(
      'game_future',
      '/future-tenses',
      'assets/data/future_tenses.json',
      icon: Icons.rocket_launch,
    ),
    MenuItem(
      'game_imperative',
      '/imperative-mood',
      'assets/data/imperative_mood.json',
      icon: Icons.campaign,
    ),
    MenuItem(
      'game_subjunctive',
      '/subjunctive-mood',
      'assets/data/subjunctive_mood.json',
      icon: Icons.lightbulb_outline,
    ),
    MenuItem(
      'game_passive',
      '/passive-voice',
      'assets/data/passive_voice.json',
      icon: Icons.build_circle_outlined,
    ),
  ],
  'category_modals': [
    MenuItem(
      'game_modals',
      '/modals',
      'assets/data/modals.json',
      icon: Icons.settings_suggest,
    ),
  ],
  'category_nouns_pronouns': [
    MenuItem(
      'game_singular',
      '/singular-plural',
      'assets/data/singular.json',
      icon: Icons.filter_1,
    ),
    MenuItem(
      'game_countable',
      '/countable-uncountable',
      'assets/data/countable_uncountable.json',
      icon: Icons.rice_bowl,
    ),
    MenuItem(
      'game_pronouns',
      '/pronoun-game',
      'assets/data/pronouns.json',
      icon: Icons.people_outline,
    ),
    MenuItem(
      'game_other_pronouns',
      '/other-pronouns',
      'assets/data/other_pronouns.json',
      icon: Icons.people_alt,
    ),
    MenuItem(
      'game_possessives',
      '/possessive-nouns',
      'assets/data/possessive_nouns.json',
      icon: Icons.lock_outline,
    ),
    MenuItem(
      'game_def_article',
      '/article-game',
      'assets/data/articles.json',
      icon: Icons.article_outlined,
    ),
    MenuItem(
      'game_all_articles',
      '/an-a-the',
      'assets/data/an_a_the.json',
      icon: Icons.abc,
    ),
    MenuItem(
      'game_determiners',
      '/determiners',
      'assets/data/determiners.json',
      icon: Icons.checklist,
    ),
  ],
  'category_adjectives_adverbs': [
    MenuItem(
      'game_adjectives',
      '/adjectives',
      'assets/data/adjectives.json',
      icon: Icons.auto_fix_high,
    ),
    MenuItem(
      'game_adjective_order',
      '/adjective-order',
      'assets/data/adjective_order.json',
      icon: Icons.sort,
    ),
    MenuItem(
      'game_comparisons',
      '/comparisons',
      'assets/data/comparisons.json',
      icon: Icons.compare_arrows,
    ),
    MenuItem(
      'game_construction_patterns',
      '/construction-patterns',
      'assets/data/construction_patterns.json',
      icon: Icons.architecture,
    ),
    MenuItem(
      'game_adverbs',
      '/adverbs',
      'assets/data/adverbs.json',
      icon: Icons.speed,
    ),
  ],
  'category_structure': [
    MenuItem(
      'game_questions',
      '/question-game',
      'assets/data/question_formation.json',
      icon: Icons.help_outline,
    ),
    MenuItem(
      'game_tag_questions',
      '/tag-questions',
      'assets/data/tag_questions.json',
      icon: Icons.quiz,
    ),
    MenuItem(
      'game_negatives',
      '/negatives',
      'assets/data/negatives.json',
      icon: Icons.do_not_disturb_on,
    ),
    MenuItem(
      'game_transitive',
      '/transitive-intransitive',
      'assets/data/transitive_intransitive.json',
      icon: Icons.sync_alt,
    ),
    MenuItem(
      'game_conditionals',
      '/conditionals',
      'assets/data/conditionals.json',
      icon: Icons.call_split,
    ),
    MenuItem(
      'game_relative',
      '/relative-clauses',
      'assets/data/relative_clauses.json',
      icon: Icons.link,
    ),
    MenuItem(
      'game_conjunctions',
      '/conjunctions',
      'assets/data/conjunctions.json',
      icon: Icons.join_inner,
    ),
  ],
  'category_prepositions': [
    MenuItem(
      'game_prepositions',
      '/preposition-game',
      'assets/data/prepositions.json',
      icon: Icons.place,
    ),
    MenuItem(
      'game_phrasal',
      '/phrasal-verbs',
      'assets/data/phrasal_verbs.json',
      icon: Icons.call_merge,
    ),
    MenuItem(
      'game_gerunds',
      '/gerunds-infinitives',
      'assets/data/gerunds_infinitives.json',
      icon: Icons.directions_run,
    ),
  ],
};
