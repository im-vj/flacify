import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../services/itunes_service.dart';
import 'navidrome_provider.dart';

final itunesServiceProvider = Provider<ItunesService>((ref) {
  return ItunesService();
});

final trendingSongsProvider = FutureProvider<List<ItunesSong>>((ref) async {
  return ref.watch(itunesServiceProvider).getTopSongs();
});

final recommendedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final trending = await ref.watch(trendingSongsProvider.future);
  final naviService = ref.watch(navidromeServiceProvider);
  
  if (naviService == null || trending.isEmpty) return [];

  List<Song> matches = [];
  // To avoid hammering the server, we'll only check the top 20
  final toCheck = trending.take(20).toList();

  // We perform searches sequentially to avoid overwhelming the Navidrome instance
  for (var t in toCheck) {
    try {
      // Search by title and artist for precision
      final query = '${t.title} ${t.artist}';
      final results = await naviService.search(query);
      if (results.isNotEmpty) {
        // Just take the first match
        matches.add(results.first);
      }
    } catch (e) {
      // Ignore individual search failures
      continue;
    }
  }

  return matches;
});
