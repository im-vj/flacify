import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String album;
  final String albumId;
  final String? coverArtId;
  final int duration; // seconds
  final int? year;
  final String? genre;
  final int? bitRate;
  final String? suffix; // flac, mp3, etc

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.album,
    required this.albumId,
    this.coverArtId,
    required this.duration,
    this.year,
    this.genre,
    this.bitRate,
    this.suffix,
  });

  @override
  List<Object?> get props => [id, title, artist, artistId, album, albumId, coverArtId, duration, year, genre, bitRate, suffix];

  factory Song.fromJson(Map<String, dynamic> j) => Song(
        id: j['id'],
        title: j['title'] ?? 'Unknown',
        artist: j['artist'] ?? 'Unknown',
        artistId: j['artistId'] ?? '',
        album: j['album'] ?? 'Unknown',
        albumId: j['albumId'] ?? '',
        coverArtId: j['coverArt'],
        duration: j['duration'] ?? 0,
        year: j['year'],
        genre: j['genre'],
        bitRate: j['bitRate'],
        suffix: j['suffix'],
      );
}
