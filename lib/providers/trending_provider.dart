import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../services/itunes_service.dart';
import 'navidrome_provider.dart';

class ChartCountry {
  final String code;
  final String name;

  const ChartCountry({required this.code, required this.name});
}

const topChartCountries = <ChartCountry>[
  ChartCountry(code: 'us', name: 'USA'),
  ChartCountry(code: 'gb', name: 'UK'),
  ChartCountry(code: 'in', name: 'India'),
  ChartCountry(code: 'ca', name: 'Canada'),
  ChartCountry(code: 'au', name: 'Australia'),
  ChartCountry(code: 'de', name: 'Germany'),
  ChartCountry(code: 'fr', name: 'France'),
  ChartCountry(code: 'jp', name: 'Japan'),
  ChartCountry(code: 'kr', name: 'South Korea'),
  ChartCountry(code: 'br', name: 'Brazil'),
];

final selectedChartCountryProvider = StateProvider<String>((ref) => 'us');

class _TimedCache<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  const _TimedCache({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

const _chartsTtl = Duration(hours: 24);
const _mappedSongsTtl = Duration(hours: 24);

final _chartCacheProvider =
    StateProvider<Map<String, _TimedCache<List<ItunesSong>>>>((ref) => {});
final _mappedCacheProvider =
    StateProvider<Map<String, _TimedCache<List<Song>>>>((ref) => {});

final itunesServiceProvider = Provider<ItunesService>((ref) {
  return ItunesService();
});

final trendingSongsProvider = FutureProvider.family<List<ItunesSong>, String>((ref, country) async {
  final key = country.toLowerCase();
  final cache = ref.watch(_chartCacheProvider)[key];
  if (cache != null && !cache.isExpired) {
    return cache.data;
  }

  final songs = await ref.watch(itunesServiceProvider).getTopSongs(limit: 10, country: key);
  ref.read(_chartCacheProvider.notifier).update((state) {
    return {
      ...state,
      key: _TimedCache<List<ItunesSong>>(
        data: songs,
        timestamp: DateTime.now(),
        ttl: _chartsTtl,
      ),
    };
  });
  return songs;
});

final recommendedSongsByCountryProvider = FutureProvider.family<List<Song>, String>((ref, country) async {
  final key = country.toLowerCase();
  final cache = ref.watch(_mappedCacheProvider)[key];
  if (cache != null && !cache.isExpired) {
    return cache.data;
  }

  final trending = await ref.watch(trendingSongsProvider(key).future);
  final naviService = ref.watch(navidromeServiceProvider);
  
  if (naviService == null || trending.isEmpty) return [];

  List<Song> matches = [];
  final toCheck = trending.take(10).toList();

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

  ref.read(_mappedCacheProvider.notifier).update((state) {
    return {
      ...state,
      key: _TimedCache<List<Song>>(
        data: matches,
        timestamp: DateTime.now(),
        ttl: _mappedSongsTtl,
      ),
    };
  });

  return matches;
});

final recommendedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final country = ref.watch(selectedChartCountryProvider);
  return ref.watch(recommendedSongsByCountryProvider(country).future);
});
