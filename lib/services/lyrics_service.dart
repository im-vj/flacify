import 'dart:convert';
import 'package:http/http.dart' as http;

class LyricLine {
  final int timeMs;
  final String text;
  const LyricLine({required this.timeMs, required this.text});
}

class LyricsService {
  Future<List<LyricLine>?> getSyncedLyrics({
    required String title,
    required String artist,
    required String album,
    required int duration,
  }) async {
    try {
      final uri = Uri.parse(
        'https://lrclib.net/api/get'
        '?artist_name=${Uri.encodeComponent(artist)}'
        '&track_name=${Uri.encodeComponent(title)}'
        '&album_name=${Uri.encodeComponent(album)}'
        '&duration=$duration',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
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
      final match = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)').firstMatch(line);
      if (match == null) continue;
      final minutes = int.parse(match.group(1)!);
      final seconds = double.parse(match.group(2)!);
      final ms = ((minutes * 60 + seconds) * 1000).toInt();
      lines.add(LyricLine(timeMs: ms, text: match.group(3)!.trim()));
    }
    return lines;
  }
}
