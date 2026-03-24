import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../models/radio_station.dart';

class NavidromeException implements Exception {
  final String message;
  final int? statusCode;
  NavidromeException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NavidromeService {
  final String baseUrl;
  final String username;
  final String password;
  final int? maxBitrate;
  late final Dio _dio;
  // Cache auth for 5 minutes to ensure URLs remain valid
  DateTime? _authCacheTime;
  Map<String, String>? _cachedAuth;

  NavidromeService({
    required this.baseUrl,
    required this.username,
    required this.password,
    this.maxBitrate,
  }) {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
    ));
    
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          // Custom error message for offline or timeout that bubbles up cleanly
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            return handler.reject(DioException(
                requestOptions: e.requestOptions,
                error: NavidromeException('Connection timed out. Please check your internet.')));
          } else if (e.type == DioExceptionType.connectionError ||
                     e.error.toString().contains('SocketException')) {
            return handler.reject(DioException(
                requestOptions: e.requestOptions,
                error: NavidromeException('Failed to connect. You might be offline.')));
          }
          final serverError = e.response?.data?['subsonic-response']?['error']?['message'];
          if (serverError != null) {
            return handler.reject(DioException(
                requestOptions: e.requestOptions,
                error: NavidromeException(serverError.toString(), statusCode: e.response?.statusCode)));
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> ping() async {
    final response = await _dio.get(
      '$baseUrl/rest/ping',
      queryParameters: _auth,
    );
    if (response.statusCode != 200 ||
        response.data['subsonic-response']?['status'] == 'failed') {
      throw NavidromeException(response.data['subsonic-response']?['error']?['message'] ??
          'Connection failed');
    }
  }

  Map<String, String> get _auth {
    // Use timestamp-based auth valid for 5 minutes
    final now = DateTime.now();
    if (_authCacheTime == null ||
        now.difference(_authCacheTime!) > const Duration(minutes: 5)) {
      // Generate new auth with timestamp salt
      final salt = now.millisecondsSinceEpoch.toString();
      final token = md5.convert(utf8.encode(password + salt)).toString();
      _cachedAuth = {
        'u': username,
        't': token,
        's': salt,
        'v': '1.16.1',
        'c': 'flacify',
        'f': 'json',
      };
      _authCacheTime = now;
    }
    return _cachedAuth!;
  }

  Future<List<Album>> getAlbums({
    String type = 'alphabeticalByName',
    int size = 500,
    int page = 0,
  }) async {
    // Subsonic supports pagination via 'offset' (page * size).
    final offset = page * size;
    final res = await _dio.get(
      '$baseUrl/rest/getAlbumList2',
      queryParameters: {..._auth, 'type': type, 'size': size, 'offset': offset},
    );
    final data = res.data['subsonic-response'];
    if (data['status'] != 'ok') throw Exception(data['error']['message']);
    final raw = data['albumList2']['album'] as List? ?? [];
    final albums = await compute(_parseAlbums, raw);
    return albums;
  }

  Future<List<Song>> getRandomSongs({int size = 100, int page = 0}) async {
    // Subsonic pagination uses 'offset' (page * size).
    final offset = page * size;
    final res = await _dio.get(
      '$baseUrl/rest/getRandomSongs',
      queryParameters: {..._auth, 'size': size, 'offset': offset},
    );
    final data = res.data['subsonic-response'];
    if (data['status'] != 'ok') throw Exception(data['error']['message']);
    final raw = data['randomSongs']['song'] as List? ?? [];
    final songs = await compute(_parseSongs, raw);
    return songs;
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

  Future<List<Album>> getArtistAlbums(String artistId) async {
    final res = await _dio.get(
      '$baseUrl/rest/getArtist',
      queryParameters: {..._auth, 'id': artistId},
    );
    final data = res.data['subsonic-response'];
    if (data['status'] != 'ok') throw Exception(data['error']['message']);
    final list = data['artist']['album'] as List? ?? [];
    return list.map((a) => Album.fromJson(a)).toList();
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

  Future<List<Playlist>> getPlaylists() async {
    final res = await _dio.get(
      '$baseUrl/rest/getPlaylists',
      queryParameters: _auth,
    );
    final data = res.data['subsonic-response'];
    if (data['status'] != 'ok') throw Exception(data['error']['message']);
    final playlists = data['playlists']['playlist'] as List? ?? [];
    return playlists.map((p) => Playlist.fromJson(p)).toList();
  }

  Future<List<RadioStation>> getInternetRadioStations() async {
    final res = await _dio.get(
      '$baseUrl/rest/getInternetRadioStations',
      queryParameters: _auth,
    );
    final data = res.data['subsonic-response'];
    if (data['status'] != 'ok') throw Exception(data['error']['message']);
    final stations =
        data['internetRadioStations']['internetRadioStation'] as List? ?? [];
    return stations.map((s) => RadioStation.fromJson(s)).toList();
  }

  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    final res = await _dio.get(
      '$baseUrl/rest/getPlaylist',
      queryParameters: {..._auth, 'id': playlistId},
    );
    final data = res.data['subsonic-response'];
    if (data['status'] != 'ok') throw Exception(data['error']['message']);
    final songs = data['playlist']['entry'] as List? ?? [];
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
    final p = {
      ..._auth,
      'id': songId,
      'format': maxBitrate != null ? 'mp3' : 'raw'
    };
    if (maxBitrate != null) {
      p['maxBitRate'] = maxBitrate.toString();
    }
    return '$baseUrl/rest/stream?${_encode(p)}';
  }

  String coverArtUrl(String? coverArtId, {int size = 256}) {
    if (coverArtId == null) return '';
    final p = {..._auth, 'id': coverArtId, 'size': '$size'};
    return '$baseUrl/rest/getCoverArt?${_encode(p)}';
  }

  // Explicit method for high-res album art (detail screens)
  String highResCoverArtUrl(String? coverArtId) =>
      coverArtUrl(coverArtId, size: 512);

  String _encode(Map<String, String> p) => p.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
}

// Isolate helpers for heavy JSON parsing
List<Album> _parseAlbums(List<dynamic> raw) {
  return raw.map((a) => Album.fromJson(a as Map<String, dynamic>)).toList();
}

List<Song> _parseSongs(List<dynamic> raw) {
  return raw.map((s) => Song.fromJson(s as Map<String, dynamic>)).toList();
}
