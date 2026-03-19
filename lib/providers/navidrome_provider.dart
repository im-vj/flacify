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

final navidromeServiceProvider = Provider<NavidromeService?>((ref) {
  final server = ref.watch(activeServerProvider);
  if (server == null) return null;
  return NavidromeService(
    baseUrl: server.url,
    username: server.username,
    password: server.password,
  );
});

final albumsProvider = FutureProvider<List<Album>>((ref) async {
  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  return service.getAlbums();
});

final artistsProvider = FutureProvider<List<Artist>>((ref) async {
  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  return service.getArtists();
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

final starredProvider = FutureProvider<List<Song>>((ref) async {
  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  return service.getStarred();
});
