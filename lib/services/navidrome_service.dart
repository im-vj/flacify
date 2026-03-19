import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';

class NavidromeService {
  final String baseUrl;
  final String username;
  final String password;
  final Dio _dio = Dio();

  NavidromeService({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  Future<void> ping() async {
    final response = await _dio.get(
      '$baseUrl/rest/ping',
      queryParameters: _auth,
    );
    if (response.statusCode != 200 || response.data['subsonic-response']['status'] == 'failed') {
      throw Exception(response.data['subsonic-response']['error']?['message'] ?? 'Connection failed');
    }
  }

  Map<String, String> get _auth {
    const salt = 'flacify2024';
    final token = md5.convert(utf8.encode(password + salt)).toString();
    return {
      'u': username,
      't': token,
      's': salt,
      'v': '1.16.1',
      'c': 'flacify',
      'f': 'json',
    };
  }

  Future<List<Album>> getAlbums({
    String type = 'alphabeticalByName',
    int size = 500,
  }) async {
    final res = await _dio.get(
      '$baseUrl/rest/getAlbumList2',
      queryParameters: {..._auth, 'type': type, 'size': size},
    );
    final data = res.data['subsonic-response'];
    if (data['status'] != 'ok') throw Exception(data['error']['message']);
    final list = data['albumList2']['album'] as List? ?? [];
    return list.map((a) => Album.fromJson(a)).toList();
  }

  Future<List<Artist>> getArtists() async {
    final res = await _dio.get(
      '$baseUrl/rest/getArtists',
      queryParameters: _auth,
    );
    final data = res.data['subsonic-response'];
    if (data['status'] != 'ok') throw Exception(data['error']['message']);
    final indices = data['artists']['index'] as List? ?? [];
    final artists = <Artist>[];
    for (final index in indices) {
      final list = index['artist'] as List? ?? [];
      artists.addAll(list.map((a) => Artist.fromJson(a)));
    }
    return artists;
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    final res = await _dio.get(
      '$baseUrl/rest/getAlbum',
      queryParameters: {..._auth, 'id': albumId},
    );
    final data = res.data['subsonic-response'];
    if (data['status'] != 'ok') throw Exception(data['error']['message']);
    final songs = data['album']['song'] as List? ?? [];
    return songs.map((s) => Song.fromJson(s)).toList();
  }

  Future<List<Song>> search(String query) async {
    final res = await _dio.get(
      '$baseUrl/rest/search3',
      queryParameters: {
        ..._auth,
        'query': query,
        'songCount': 50,
        'albumCount': 20,
        'artistCount': 10,
      },
    );
    final data = res.data['subsonic-response'];
    if (data['status'] != 'ok') throw Exception(data['error']['message']);
    final songs = data['searchResult3']['song'] as List? ?? [];
    return songs.map((s) => Song.fromJson(s)).toList();
  }

  Future<List<Song>> getStarred() async {
    final res = await _dio.get(
      '$baseUrl/rest/getStarred2',
      queryParameters: _auth,
    );
    final data = res.data['subsonic-response'];
    if (data['status'] != 'ok') throw Exception(data['error']['message']);
    final songs = data['starred2']['song'] as List? ?? [];
    return songs.map((s) => Song.fromJson(s)).toList();
  }

  Future<void> star(String id) async {
    await _dio.get(
      '$baseUrl/rest/star',
      queryParameters: {..._auth, 'id': id},
    );
  }

  Future<void> unstar(String id) async {
    await _dio.get(
      '$baseUrl/rest/unstar',
      queryParameters: {..._auth, 'id': id},
    );
  }

  String streamUrl(String songId) {
    final p = {..._auth, 'id': songId, 'format': 'raw'};
    return '$baseUrl/rest/stream?${_encode(p)}';
  }

  String coverArtUrl(String? coverArtId, {int size = 512}) {
    if (coverArtId == null) return '';
    final p = {..._auth, 'id': coverArtId, 'size': '$size'};
    return '$baseUrl/rest/getCoverArt?${_encode(p)}';
  }

  String _encode(Map<String, String> p) =>
      p.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
}
