import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../providers/radio_provider.dart';

class RadioScreen extends ConsumerWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(radioStationsProvider);
    final player = ref.read(playerProvider.notifier);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Internet Radio',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          stationsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (stations) => stations.isEmpty
                ? const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No stations found on this Navidrome server.',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final st = stations[i];
                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF160033),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.radio_rounded, color: Color(0xFF00F0FF)),
                          ),
                          title: Text(st.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(st.homePageUrl.isNotEmpty ? st.homePageUrl : st.streamUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            final dummySong = Song(
                              id: st.id,
                              title: st.name,
                              artist: 'Internet Radio',
                              artistId: '',
                              album: 'Live Stream',
                              albumId: '',
                              duration: 0,
                              coverArtId: '',
                            );
                            player.playSong(dummySong);
                          },
                        );
                      },
                      childCount: stations.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
