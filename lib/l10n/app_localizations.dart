import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Language Games',
      'settings': 'Settings',
      'select_language': 'Select Language',
      'category_articles': 'Articles',
      'category_nouns_pronouns': 'Nouns & Pronouns',
      'category_prepositions': 'Prepositions',
      'category_verbs': 'Verbs',
      'category_tenses': 'Tenses',
      'category_structure': 'Structure',
      'game_def_article': 'Definite Article',
      'game_all_articles': 'All Articles',
      'game_singular': 'Singular & Plural',
      'game_pronouns': 'Pronouns',
      'game_countable': 'Countable & Uncountable',
      'game_prepositions': 'Prepositions',
      'game_be_verb': 'Be Verbs',
      'game_transitive': 'Transitive',
      'game_modals': 'Modals',
      'game_gerunds': 'Gerunds & Infinitives',
      'game_phrasal': 'Phrasal Verbs',
      'game_tenses': 'Verb Tenses',
      'game_present_perfect': 'Present Perfect',
      'game_passive': 'Passive Voice',
      'game_questions': 'Questions',
      'game_conditionals': 'Conditionals',
      'game_relative': 'Relative Clauses',
      'try_again': 'Try Again',
      'next_level': 'Next Level',
      'check_answers': 'Check Answers',

      'score': 'Score',
    },
    'zh_CN': {
      'app_title': '语言游戏',
      'settings': '设置',
      'select_language': '选择语言',
      'category_articles': '冠词',
      'category_nouns_pronouns': '名词与代词',
      'category_prepositions': '介词',
      'category_verbs': '动词',
      'category_tenses': '时态',
      'category_structure': '句型与结构',
      'game_def_article': '定冠词',
      'game_all_articles': '所有冠词',
      'game_singular': '单复数',
      'game_pronouns': '代词阴阳性',
      'game_countable': '可数与不可数',
      'game_prepositions': '介系词',
      'game_be_verb': 'Be动词',
      'game_transitive': '及物与不及物',
      'game_modals': '语气助动词',
      'game_gerunds': '不定式与动名词',
      'game_phrasal': '短语动词',
      'game_tenses': '动词时態',
      'game_present_perfect': '现在完成式',
      'game_passive': '被动语态',
      'game_questions': '疑问句',
      'game_conditionals': '条件句',
      'game_relative': '关系从句',
      'try_again': '重试',
      'next_level': '下一关',
      'check_answers': '检查答案',

      'score': '分数',
    },
    'zh_TW': {
      'app_title': '語言遊戲',
      'settings': '設定',
      'select_language': '選擇語言',
      'category_articles': '冠詞',
      'category_nouns_pronouns': '名詞與代名詞',
      'category_prepositions': '介係詞',
      'category_verbs': '動詞',
      'category_tenses': '時態',
      'category_structure': '句型與結構',
      'game_def_article': '定冠詞',
      'game_all_articles': '所有冠詞',
      'game_singular': '單複數',
      'game_pronouns': '代名詞陰陽性',
      'game_countable': '可數與不可數',
      'game_prepositions': '介系詞',
      'game_be_verb': 'Be動詞',
      'game_transitive': '及物與不及物',
      'game_modals': '語氣助動詞',
      'game_gerunds': '不定詞與動名詞',
      'game_phrasal': '片語動詞',
      'game_tenses': '動詞時態',
      'game_present_perfect': '現在完成式',
      'game_passive': '被動語態',
      'game_questions': '疑問句',
      'game_conditionals': '條件句',
      'game_relative': '關係子句',
      'try_again': '重試',
      'next_level': '下一關',
      'check_answers': '檢查答案',

      'score': '分數',
    },
  };

  String get(String key) {
    String localeKey = locale.languageCode;
    if (locale.languageCode == 'zh') {
      if (locale.countryCode == 'TW' || locale.scriptCode == 'Hant') {
        localeKey = 'zh_TW';
      } else {
        localeKey = 'zh_CN';
      }
    }

    return _localizedValues[localeKey]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Convenient getters
  String get appTitle => get('app_title');
  String get settings => get('settings');
  String get selectLanguage => get('select_language');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
