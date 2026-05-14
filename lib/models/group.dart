import 'channel.dart';

class Group {
  final String id;
  final String name;
  final List<Channel> channels;

  const Group({
    required this.id,
    required this.name,
    required this.channels,
  });

  Group copyWith({
    String? id,
    String? name,
    List<Channel>? channels,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      channels: channels ?? this.channels,
    );
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    final channelList = (json['channels'] as List<dynamic>? ?? [])
        .map((c) => Channel.fromJson(c as Map<String, dynamic>))
        .toList();
    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      channels: channelList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'channels': channels.map((c) => c.toJson()).toList(),
      };
}