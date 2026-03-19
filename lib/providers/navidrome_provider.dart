import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/navidrome_service.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/song.dart';

// --- Config (change these to your server) ---
const String kNavidromeUrl = 'https://music.imvj.in';
const String kNavidromeUser = 'YOUR_USERNAME';
const String kNavidromePass = 'YOUR_PASSWORD';

final navidromeServiceProvider = Provider<NavidromeService>((ref) {
  return NavidromeService(
    baseUrl: kNavidromeUrl,
    username: kNavidromeUser,
    password: kNavidromePass,
  );
});

final albumsProvider = FutureProvider<List<Album>>((ref) async {
  return ref.watch(navidromeServiceProvider).getAlbums();
});

final artistsProvider = FutureProvider<List<Artist>>((ref) async {
  return ref.watch(navidromeServiceProvider).getArtists();
});

final albumSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, albumId) async {
  return ref.watch(navidromeServiceProvider).getAlbumSongs(albumId);
});

final searchProvider =
    FutureProvider.family<List<Song>, String>((ref, query) async {
  if (query.isEmpty) return [];
  return ref.watch(navidromeServiceProvider).search(query);
});

final starredProvider = FutureProvider<List<Song>>((ref) async {
  return ref.watch(navidromeServiceProvider).getStarred();
});
