import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'navidrome_provider.dart';

final playlistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  return service.getPlaylists();
});

final playlistSongsProvider = FutureProvider.family<List<Song>, String>((ref, playlistId) async {
  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  return service.getPlaylistSongs(playlistId);
});
