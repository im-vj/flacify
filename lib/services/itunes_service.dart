import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ItunesSong {
  final String title;
  final String artist;
  final String imageUrl;

  ItunesSong({required this.title, required this.artist, required this.imageUrl});

  factory ItunesSong.fromJson(Map<String, dynamic> json) {
    return ItunesSong(
      title: json['im:name']?['label'] ?? 'Unknown Title',
      artist: json['im:artist']?['label'] ?? 'Unknown Artist',
      imageUrl: json['im:image']?.last?['label'] ?? '',
    );
  }
}

class ItunesService {
  final Dio _dio = Dio();

  Future<List<ItunesSong>> getTopSongs({int limit = 50, String country = 'us'}) async {
    final normalizedCountry = country.toLowerCase();
    final safeLimit = limit.clamp(1, 100);
    final urlV2 =
        'https://rss.applemarketingtools.com/api/v2/$normalizedCountry/music/most-played/$safeLimit/songs.json';
    final urlLegacy =
        'https://itunes.apple.com/$normalizedCountry/rss/topsongs/limit=$safeLimit/json';

    try {
      debugPrint('[CHARTS] Fetch v2 country=$normalizedCountry limit=$safeLimit');
      final response = await _dio.get(
        urlV2,
        options: Options(headers: {
          'Accept': 'application/json',
          'User-Agent': 'flacify/1.0',
        }),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['feed']?['results'] is List) {
          final results = data['feed']['results'] as List;
          final songs = results.map((e) => _fromV2Json(e as Map<String, dynamic>)).toList();
          debugPrint('[CHARTS] v2 success count=${songs.length}');
          return songs;
        }
        debugPrint('[CHARTS] v2 unexpected schema');
      }
    } catch (e) {
      debugPrint('[CHARTS] v2 failed: $e');
    }

    try {
      debugPrint('[CHARTS] Fetch legacy country=$normalizedCountry limit=$safeLimit');
      final response = await _dio.get(
        urlLegacy,
        options: Options(headers: {
          'Accept': 'application/json',
          'User-Agent': 'flacify/1.0',
        }),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('feed') && data['feed'].containsKey('entry')) {
          final entries = data['feed']['entry'] as List;
          final songs = entries.map((e) => ItunesSong.fromJson(e)).toList();
          debugPrint('[CHARTS] legacy success count=${songs.length}');
          return songs;
        }
        debugPrint('[CHARTS] legacy unexpected schema');
      }
    } catch (e) {
      debugPrint('[CHARTS] legacy failed: $e');
    }

    debugPrint('[CHARTS] all chart sources failed country=$normalizedCountry');
    return [];
  }

  ItunesSong _fromV2Json(Map<String, dynamic> json) {
    final artwork = json['artworkUrl100'] as String? ?? '';
    final highResArtwork = artwork.replaceAll('100x100', '300x300');
    return ItunesSong(
      title: json['name'] as String? ?? 'Unknown Title',
      artist: json['artistName'] as String? ?? 'Unknown Artist',
      imageUrl: highResArtwork,
    );
  }
}
