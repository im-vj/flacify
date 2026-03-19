import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/navidrome_service.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/song.dart';

const String kNavidromeUrl = String.fromEnvironment('NAVIDROME_URL', defaultValue: 'https://navidrome.imvj.in');
const String kNavidromeUser = String.fromEnvironment('NAVIDROME_USER', defaultValue: '');
const String kNavidromePass = String.fromEnvironment('NAVIDROME_PASS', defaultValue: '');

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
