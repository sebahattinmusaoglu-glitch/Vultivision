class Channel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String subscriberCount;

  const Channel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.subscriberCount,
  });

  factory Channel.fromSearchJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>;
    return Channel(
      id: (json['id'] as Map<String, dynamic>)['channelId'] ?? '',
      title: snippet['title'] ?? '',
      thumbnailUrl: (snippet['thumbnails']?['medium']?['url']) ?? '',
      subscriberCount: '',
    );
  }

  factory Channel.fromDetailsJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>;
    final stats = json['statistics'] as Map<String, dynamic>? ?? {};
    final rawCount = int.tryParse(stats['subscriberCount'] ?? '0') ?? 0;
    return Channel(
      id: json['id'] ?? '',
      title: snippet['title'] ?? '',
      thumbnailUrl: (snippet['thumbnails']?['medium']?['url']) ?? '',
      subscriberCount: _formatCount(rawCount),
    );
  }

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      subscriberCount: json['subscriberCount'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'subscriberCount': subscriberCount,
      };

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M abone';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(0)}K abone';
    }
    return '$count abone';
  }
}