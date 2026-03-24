import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/navidrome_service.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/song.dart';

import '../services/storage_service.dart';
import '../models/server_config.dart';

final storageProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageProvider not initialized');
});

final activeServerProvider = Provider<ServerConfig?>((ref) {
  final storage = ref.watch(storageProvider);
  return storage.getActiveServer();
});

// Simple bitrate provider backed by StorageService
final bitrateProvider = StateProvider<int?>((ref) {
  final storage = ref.watch(storageProvider);
  return storage.getMaxBitrate();
});

final navidromeServiceProvider = Provider<NavidromeService?>((ref) {
  final server = ref.watch(activeServerProvider);
  final bitrate = ref.watch(bitrateProvider);
  if (server == null) return null;
  return NavidromeService(
    baseUrl: server.url,
    username: server.username,
    password: server.password,
    maxBitrate: bitrate,
  );
});

// Track if service is ready (authenticated and working)
final serviceReadyProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return false;

  try {
    // Try to ping the server to verify it's working
    await service.ping();
    return true;
  } catch (e) {
    // Service exists but connection failed
    return false;
  }
});

// Cache duration for data providers (5 minutes)
const _cacheDuration = Duration(minutes: 5);

// Cached data holder
class CachedData<T> {
  final T data;
  final DateTime timestamp;
  CachedData(this.data) : timestamp = DateTime.now();
  bool get isExpired => DateTime.now().difference(timestamp) > _cacheDuration;
}

// Force refresh provider - can be used to trigger data reload
final forceRefreshProvider = StateProvider<bool>((ref) => false);

// Albums provider with caching
final _albumsCacheProvider = StateProvider<CachedData<List<Album>>?>((ref) => null);

final albumsProvider = FutureProvider<List<Album>>((ref) async {
  // Watch for force refresh triggers
  ref.watch(forceRefreshProvider);

  final cache = ref.watch(_albumsCacheProvider);
  if (cache != null && !cache.isExpired) return cache.data;

  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  final data = await service.getAlbums(size: 50, page: 0);
  ref.read(_albumsCacheProvider.notifier).state = CachedData(data);
  return data;
});

// Songs provider with caching (optimized count for better performance)
final _songsCacheProvider = StateProvider<CachedData<List<Song>>?>((ref) => null);

final songsProvider = FutureProvider<List<Song>>((ref) async {
  // Watch for force refresh triggers
  ref.watch(forceRefreshProvider);

  final cache = ref.watch(_songsCacheProvider);
  if (cache != null && !cache.isExpired) return cache.data;

  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];

  final data = await service.getRandomSongs(size: 50, page: 0); // Optimized from 1000
  ref.read(_songsCacheProvider.notifier).state = CachedData(data);
  return data;
});

// Provider to load additional songs and merge with existing cache
final loadMoreSongsProvider = FutureProvider<List<Song>>((ref) async {
  final cache = ref.watch(_songsCacheProvider);
  final currentList = cache?.data ?? [];
  final nextPage = (currentList.length ~/ 50);

  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  final more = await service.getRandomSongs(size: 50, page: nextPage);
  final combined = [...currentList, ...more];
  ref.read(_songsCacheProvider.notifier).state = CachedData(combined);
  return combined;
});

// Artists provider with caching
final _artistsCacheProvider = StateProvider<CachedData<List<Artist>>?>((ref) => null);

final artistsProvider = FutureProvider<List<Artist>>((ref) async {
  // Watch for force refresh triggers
  ref.watch(forceRefreshProvider);

  final cache = ref.watch(_artistsCacheProvider);
  if (cache != null && !cache.isExpired) return cache.data;

  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  final data = await service.getArtists();
  ref.read(_artistsCacheProvider.notifier).state = CachedData(data);
  return data;
});

final artistTopSongsProvider = FutureProvider.family<List<Song>, String>((ref, artistName) async {
  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  final songs = await service.search(artistName);
  return songs.where((s) => s.artist.toLowerCase().contains(artistName.toLowerCase())).take(10).toList();
});

final artistAlbumsProvider = FutureProvider.family<List<Album>, String>((ref, artistId) async {
  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  return service.getArtistAlbums(artistId);
});

final albumSongsProvider = FutureProvider.family<List<Song>, String>((ref, albumId) async {
  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  return service.getAlbumSongs(albumId);
});

final searchProvider = FutureProvider.family<List<Song>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  return service.search(query);
});

// Starred provider with caching
final _starredCacheProvider = StateProvider<CachedData<List<Song>>?>((ref) => null);

final starredProvider = FutureProvider<List<Song>>((ref) async {
  final cache = ref.watch(_starredCacheProvider);
  if (cache != null && !cache.isExpired) return cache.data;

  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  final data = await service.getStarred();
  ref.read(_starredCacheProvider.notifier).state = CachedData(data);
  return data;
});

// Helper to invalidate all data caches
void invalidateAllCaches(WidgetRef ref) {
  ref.invalidate(_albumsCacheProvider);
  ref.invalidate(_songsCacheProvider);
  ref.invalidate(_artistsCacheProvider);
  ref.invalidate(_starredCacheProvider);
}
