import 'package:dio/dio.dart';

class LyricLine {
  final int timeMs;
  final String text;
  const LyricLine({required this.timeMs, required this.text});
}

class LyricsService {
  final Dio _dio = Dio();

  Future<List<LyricLine>?> getSyncedLyrics({
    required String title,
    required String artist,
    required String album,
    required int duration,
  }) async {
    try {
      final res = await _dio.get(
        'https://lrclib.net/api/get',
        queryParameters: {
          'artist_name': artist,
          'track_name': title,
          'album_name': album,
          'duration': duration,
        },
      );
      if (res.statusCode != 200) return null;
      final data = res.data;
      final synced = data['syncedLyrics'] as String?;
      if (synced == null || synced.isEmpty) return null;
      return _parseLrc(synced);
    } catch (_) {
      return null;
    }
  }

  List<LyricLine> _parseLrc(String lrc) {
    final lines = <LyricLine>[];
    for (final line in lrc.split('\n')) {
      final match = RegExp(r'\[(\d+):([\d\.:]+)\](.*)').firstMatch(line);
      if (match == null) continue;
      final minutes = int.parse(match.group(1)!);
      final secStr = match.group(2)!.replaceAll(':', '.');
      final seconds = double.parse(secStr);
      final ms = ((minutes * 60 + seconds) * 1000).toInt();
      lines.add(LyricLine(timeMs: ms, text: match.group(3)!.trim()));
    }
    return lines;
  }
}
