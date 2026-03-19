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

  Future<List<ItunesSong>> getTopSongs({int limit = 50}) async {
    try {
      final response = await _dio.get('https://itunes.apple.com/us/rss/topsongs/limit=$limit/json');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('feed') && data['feed'].containsKey('entry')) {
          final entries = data['feed']['entry'] as List;
          return entries.map((e) => ItunesSong.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching iTunes top songs: $e');
      return [];
    }
  }
}
