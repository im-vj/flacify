import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/playlist.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player_wrapper.dart';

class PlaylistScreen extends ConsumerWidget {
  final Playlist playlist;
  const PlaylistScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(playlistSongsProvider(playlist.id));
    final player = ref.read(playerProvider.notifier);

    return MiniPlayerWrapper(
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF00F0FF), Color(0xFF050014)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.queue_music_rounded, size: 80, color: Colors.white54),
                  ),
                ),
              ),
            ),
            songsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
              data: (songs) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => SongTile(
                    song: songs[i],
                    index: i + 1,
                    onTap: () => player.playQueue(songs, index: i),
                  ),
                  childCount: songs.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
