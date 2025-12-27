class MenuItem {
  final String titleKey;
  final String path;
  final String assetPath;
  const MenuItem(this.titleKey, this.path, this.assetPath);
}

const Map<String, List<MenuItem>> menuItemsConfig = {
  'category_tenses': [
    MenuItem(
      'game_be_verb',
      '/be-verb-game',
      'assets/data/be_verb_adjectives.json',
    ),
    MenuItem('game_tenses', '/verb-game', 'assets/data/verbs.json'),
    MenuItem(
      'game_present_continuous',
      '/present-continuous',
      'assets/data/present_continuous.json',
    ),
    MenuItem(
      'game_present_perfect',
      '/present-perfect',
      'assets/data/present_perfect.json',
    ),
    MenuItem('game_past', '/past-tenses', 'assets/data/past_tenses.json'),
    MenuItem('game_future', '/future-tenses', 'assets/data/future_tenses.json'),
    MenuItem(
      'game_imperative',
      '/imperative-mood',
      'assets/data/imperative_mood.json',
    ),
    MenuItem(
      'game_subjunctive',
      '/subjunctive-mood',
      'assets/data/subjunctive_mood.json',
    ),
    MenuItem(
      'game_passive',
      '/passive-voice',
      'assets/data/passive_voice.json',
    ),
  ],
  'category_modals': [
    MenuItem('game_modals', '/modals', 'assets/data/modals.json'),
  ],
  'category_nouns_pronouns': [
    MenuItem('game_singular', '/singular-plural', 'assets/data/singular.json'),
    MenuItem(
      'game_countable',
      '/countable-uncountable',
      'assets/data/countable_uncountable.json',
    ),
    MenuItem('game_pronouns', '/pronoun-game', 'assets/data/pronouns.json'),
    MenuItem(
      'game_other_pronouns',
      '/other-pronouns',
      'assets/data/other_pronouns.json',
    ),
    MenuItem(
      'game_possessives',
      '/possessive-nouns',
      'assets/data/possessive_nouns.json',
    ),
    MenuItem('game_def_article', '/article-game', 'assets/data/articles.json'),
    MenuItem('game_all_articles', '/an-a-the', 'assets/data/an_a_the.json'),
    MenuItem(
      'game_determiners',
      '/determiners',
      'assets/data/determiners.json',
    ),
  ],
  'category_adjectives_adverbs': [
    MenuItem('game_adjectives', '/adjectives', 'assets/data/adjectives.json'),
    MenuItem(
      'game_adjective_order',
      '/adjective-order',
      'assets/data/adjective_order.json',
    ),
    MenuItem(
      'game_comparisons',
      '/comparisons',
      'assets/data/comparisons.json',
    ),
    MenuItem(
      'game_construction_patterns',
      '/construction-patterns',
      'assets/data/construction_patterns.json',
    ),
    MenuItem('game_adverbs', '/adverbs', 'assets/data/adverbs.json'),
  ],
  'category_structure': [
    MenuItem(
      'game_questions',
      '/question-game',
      'assets/data/question_formation.json',
    ),
    MenuItem(
      'game_tag_questions',
      '/tag-questions',
      'assets/data/tag_questions.json',
    ),
    MenuItem('game_negatives', '/negatives', 'assets/data/negatives.json'),
    MenuItem(
      'game_transitive',
      '/transitive-intransitive',
      'assets/data/transitive_intransitive.json',
    ),
    MenuItem(
      'game_conditionals',
      '/conditionals',
      'assets/data/conditionals.json',
    ),
    MenuItem(
      'game_relative',
      '/relative-clauses',
      'assets/data/relative_clauses.json',
    ),
    MenuItem(
      'game_conjunctions',
      '/conjunctions',
      'assets/data/conjunctions.json',
    ),
  ],
  'category_prepositions': [
    MenuItem(
      'game_prepositions',
      '/preposition-game',
      'assets/data/prepositions.json',
    ),
    MenuItem(
      'game_phrasal',
      '/phrasal-verbs',
      'assets/data/phrasal_verbs.json',
    ),
    MenuItem(
      'game_gerunds',
      '/gerunds-infinitives',
      'assets/data/gerunds_infinitives.json',
    ),
  ],
};
