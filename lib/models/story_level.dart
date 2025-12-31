class StoryLevel {
  final String id;
  final String title;
  final String content;
  final String explanationZhTw;
  final String explanationZhCn;
  final String explanationEnUs;

  StoryLevel({
    required this.id,
    required this.title,
    required this.content,
    required this.explanationZhTw,
    required this.explanationZhCn,
    required this.explanationEnUs,
  });

  factory StoryLevel.fromJson(Map<String, dynamic> json) {
    return StoryLevel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      explanationZhTw:
          json['explanation-zh-TW'] ?? json['explanationZhTw'] ?? '',
      explanationZhCn:
          json['explanation-zh-CN'] ?? json['explanationZhCn'] ?? '',
      explanationEnUs:
          json['explanation-en-US'] ?? json['explanationEnUs'] ?? '',
    );
  }
}
