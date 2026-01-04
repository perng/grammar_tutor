class StoryLevel {
  final String id;
  final String title;
  final String content;
  final String explanationZhTw;
  final String explanationZhCn;
  final String explanationEnUs;
  final String type;

  StoryLevel({
    required this.id,
    required this.title,
    required this.content,
    required this.explanationZhTw,
    required this.explanationZhCn,
    required this.explanationEnUs,
    this.type = 'generic',
  });

  factory StoryLevel.fromJson(Map<String, dynamic> json) {
    return StoryLevel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      explanationZhTw:
          json['explanationZhTw'] ?? json['explanation-zh-TW'] ?? '',
      explanationZhCn:
          json['explanationZhCn'] ?? json['explanation-zh-CN'] ?? '',
      explanationEnUs:
          json['explanationEnUs'] ?? json['explanation-en-US'] ?? '',
      type: json['type'] ?? 'generic',
    );
  }
}
