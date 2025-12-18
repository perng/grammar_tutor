
class Level {
  final String id;
  final String title;
  final String description;
  final String gameType;
  final String wordFile;

  Level({
    required this.id,
    required this.title,
    required this.description,
    required this.gameType,
    required this.wordFile,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      gameType: json['game_type'] ?? '',
      wordFile: json['wordFile'] ?? '',
    );
  }
}

class Example {
  final String sentence;
  final String translationZhTw;

  Example({required this.sentence, required this.translationZhTw});

  factory Example.fromJson(Map<String, dynamic> json) {
    return Example(
      sentence: json['sentence'] ?? '',
      translationZhTw: json['translation_zh_TW'] ?? '',
    );
  }
}

class WordMeaning {
  final String type;
  final String meaningEnUs;
  final String meaningZhTw;
  final List<String> wrongMeaningZhTw;
  final int meaningIndex;
  final List<Example> examples;
  final List<String> synonyms;

  WordMeaning({
    required this.type,
    required this.meaningEnUs,
    required this.meaningZhTw,
    required this.wrongMeaningZhTw,
    required this.meaningIndex,
    required this.examples,
    required this.synonyms,
  });

  factory WordMeaning.fromJson(Map<String, dynamic> json, int index) {
    return WordMeaning(
      type: json['type'] ?? '',
      meaningEnUs: json['meaning_en_US'] ?? '',
      meaningZhTw: json['meaning_zh_TW'] ?? '',
      wrongMeaningZhTw: List<String>.from(json['wrong_meaning_zh_TW'] ?? []),
      meaningIndex: index,
      examples:
          (json['examples'] as List<dynamic>?)
              ?.map((e) => Example.fromJson(e))
              .toList() ??
          [],
      synonyms: List<String>.from(json['synonyms'] ?? []),
    );
  }
}

class WordData {
  final String word;
  final List<WordMeaning> meanings;
  final List<String> confusion;

  WordData({
    required this.word,
    required this.meanings,
    required this.confusion,
  });

  factory WordData.fromJson(Map<String, dynamic> json) {
    var meaningsList =
        (json['meanings'] as List<dynamic>?)
            ?.asMap()
            .entries
            .map((e) => WordMeaning.fromJson(e.value, e.key))
            .toList() ??
        [];
    return WordData(
      word: json['word'] ?? '',
      meanings: meaningsList,
      confusion: List<String>.from(json['confusion'] ?? []),
    );
  }
}

class WordWithScore {
  final String word;
  final WordMeaning meaning;
  int score;

  WordWithScore({required this.word, required this.meaning, this.score = 0});
}
