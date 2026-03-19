class Playlist {
  final String id;
  final String name;
  final int songCount;
  final int duration;

  Playlist({
    required this.id,
    required this.name,
    required this.songCount,
    required this.duration,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      songCount: json['songCount'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
    );
  }
}
