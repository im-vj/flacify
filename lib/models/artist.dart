import 'package:equatable/equatable.dart';

class Artist extends Equatable {
  final String id;
  final String name;
  final String? coverArtId;
  final int albumCount;

  const Artist({
    required this.id,
    required this.name,
    this.coverArtId,
    required this.albumCount,
  });

  @override
  List<Object?> get props => [id, name, coverArtId, albumCount];

  factory Artist.fromJson(Map<String, dynamic> j) => Artist(
        id: j['id'],
        name: j['name'] ?? 'Unknown',
        coverArtId: j['coverArt'] ?? j['artistImageUrl'],
        albumCount: j['albumCount'] ?? 0,
      );
}
