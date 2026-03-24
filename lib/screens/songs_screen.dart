import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navidrome_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';

class SongsScreen extends ConsumerWidget {
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsProvider);
    final player = ref.read(playerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('All Songs')),
      body: songsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white38))),
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(child: Text('No songs found', style: TextStyle(color: Colors.white38)));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: songs.length,
            itemBuilder: (ctx, i) => SongTile(
              song: songs[i],
              onTap: () => player.playQueue(songs, index: i),
            ),
          );
        },
      ),
    );
  }
}
