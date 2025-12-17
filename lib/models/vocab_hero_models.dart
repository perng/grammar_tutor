class VocabLevel {
  final String id;
  final String gameType;
  final String title;
  final String description;

  VocabLevel({
    required this.id,
    required this.gameType,
    required this.title,
    required this.description,
  });

  factory VocabLevel.fromJson(Map<String, dynamic> json) {
    return VocabLevel(
      id: json['id'] ?? '',
      gameType: json['game_type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class VocabQuestion {
  final String id;
  final String answer;
  final String wordTranslationZhTw;
  final String sentence;
  final String sentenceZhTw;
  final List<String> others;
  final List<String> othersZhTw;
  int score;

  VocabQuestion({
    required this.id,
    required this.answer,
    required this.wordTranslationZhTw,
    required this.sentence,
    required this.sentenceZhTw,
    required this.others,
    required this.othersZhTw,
    this.score = 0,
  });

  factory VocabQuestion.fromJson(Map<String, dynamic> json) {
    return VocabQuestion(
      id: json['id'] ?? '',
      answer: json['answer'] ?? '',
      wordTranslationZhTw: json['word_translation_zh_TW'] ?? '',
      sentence: json['sentence'] ?? '',
      sentenceZhTw: json['sentence_zh_TW'] ?? '',
      others: List<String>.from(json['others'] ?? []),
      othersZhTw: List<String>.from(json['others_zh_TW'] ?? []),
    );
  }
}
