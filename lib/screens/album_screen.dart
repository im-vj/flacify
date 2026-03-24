import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import '../providers/navidrome_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player_wrapper.dart';

class AlbumScreen extends ConsumerWidget {
  final Album album;
  const AlbumScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(albumSongsProvider(album.id));
    final navidrome = ref.read(navidromeServiceProvider);
    final player = ref.read(playerProvider.notifier);
    final coverUrl = navidrome?.highResCoverArtUrl(album.coverArtId) ?? '';

    return MiniPlayerWrapper(
      child: Scaffold(
        body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF050014),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (coverUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF050014).withValues(alpha: 0.8),
                          const Color(0xFF050014),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          album.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${album.artist} • ${album.year ?? ''}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: songs.maybeWhen(
                data: (list) => Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => player.playQueue(list),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play All'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00F0FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        final shuffled = [...list]..shuffle();
                        player.playQueue(shuffled);
                      },
                      icon: const Icon(Icons.shuffle_rounded),
                      label: const Text('Shuffle'),
                    ),
                  ],
                ),
                orElse: () => const SizedBox(),
              ),
            ),
          ),
          songs.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (list) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => SongTile(
                  song: list[i],
                  index: i + 1,
                  onTap: () => player.playQueue(list, index: i),
                ),
                childCount: list.length,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
