class StoryLevel {
  final String id;
  final String title;
  final String content;
  final String explanationZhTw;
  final String explanationEnUs;

  StoryLevel({
    required this.id,
    required this.title,
    required this.content,
    required this.explanationZhTw,
    required this.explanationEnUs,
  });

  factory StoryLevel.fromJson(Map<String, dynamic> json) {
    return StoryLevel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      explanationZhTw: json['explanation-zh-TW'] ?? '',
      explanationEnUs: json['explanation-en-US'] ?? '',
    );
  }
}
