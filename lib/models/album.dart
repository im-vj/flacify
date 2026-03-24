import 'package:equatable/equatable.dart';

class Album extends Equatable {
  final String id;
  final String name;
  final String artist;
  final String artistId;
  final String? coverArtId;
  final int? year;
  final int songCount;
  final String? genre;

  const Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.artistId,
    this.coverArtId,
    this.year,
    required this.songCount,
    this.genre,
  });

  @override
  List<Object?> get props => [id, name, artist, artistId, coverArtId, year, songCount, genre];

  factory Album.fromJson(Map<String, dynamic> j) => Album(
        id: j['id'],
        name: j['name'] ?? 'Unknown',
        artist: j['artist'] ?? 'Unknown',
        artistId: j['artistId'] ?? '',
        coverArtId: j['coverArt'],
        year: j['year'],
        songCount: j['songCount'] ?? 0,
        genre: j['genre'],
      );
}
