class Video {
  final String id;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final String duration;

  const Video({
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    this.duration = '',
  });

  factory Video.fromPlaylistJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>;
    final resourceId = snippet['resourceId'] as Map<String, dynamic>? ?? {};
    return Video(
      id: resourceId['videoId'] ?? '',
      title: snippet['title'] ?? '',
      channelTitle:
          snippet['videoOwnerChannelTitle'] ?? snippet['channelTitle'] ?? '',
      thumbnailUrl: (snippet['thumbnails']?['medium']?['url'] ??
              snippet['thumbnails']?['default']?['url']) ??
          '',
    );
  }
}