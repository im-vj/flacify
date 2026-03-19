import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navidrome_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starred = ref.watch(starredProvider);
    final player = ref.read(playerProvider.notifier);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Liked Songs',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          starred.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (songs) => songs.isEmpty
                ? const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No liked songs yet.\nTap ♥ on any song!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => SongTile(
                        song: songs[i],
                        onTap: () => player.playQueue(songs, index: i),
                      ),
                      childCount: songs.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
