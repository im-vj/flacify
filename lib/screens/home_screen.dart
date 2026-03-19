import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/navidrome_provider.dart';
import '../providers/trending_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/album_card.dart';
import '../widgets/mini_player.dart';
import 'album_screen.dart';
import 'search_screen.dart';
import 'player_screen.dart';
import 'library_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  final _tabs = const [
    _HomeTab(),
    SearchScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final player = ref.read(playerProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
          _tabs[_tab],
          if (playerState.queue.isNotEmpty)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8, // Positioned just above the bottom nav bar
              child: MiniPlayer(
                song: player.currentSong!,
                isPlaying: playerState.isPlaying,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerScreen()),
                ),
                onToggle: () => player.togglePlay(),
                onNext: () => player.next(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0A001F),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.library_music_rounded), label: 'Library'),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  Widget _buildSectionTitle(BuildContext context, String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildHorizontalSongList(AsyncValue<List<Song>> songsAsync, WidgetRef ref) {
    final player = ref.read(playerProvider.notifier);
    return songsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: SizedBox(height: 120, child: Center(child: Text('Error: $e'))),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox(height: 120, child: Center(child: Text('No songs found'))),
          );
        }
        return SliverToBoxAdapter(
          child: SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final navidrome = ref.read(navidromeServiceProvider);
                final coverUrl = navidrome?.coverArtUrl(song.coverArtId) ?? '';
                
                return GestureDetector(
                   onTap: () => player.playQueue(songs, index: index),
                   child: Container(
                     width: 140,
                     margin: const EdgeInsets.only(right: 16),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         ClipRRect(
                           borderRadius: BorderRadius.circular(12),
                           child: AspectRatio(
                             aspectRatio: 1,
                             child: coverUrl.isNotEmpty
                                 ? Image.network(coverUrl, fit: BoxFit.cover)
                                 : Container(color: Colors.white12, child: const Icon(Icons.music_note)),
                           ),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           song.title,
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: const TextStyle(fontWeight: FontWeight.w600),
                         ),
                         Text(
                           song.artist,
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                           style: const TextStyle(color: Colors.white54, fontSize: 12),
                         ),
                       ],
                     ),
                   ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumsProvider);
    final recommended = ref.watch(recommendedSongsProvider);
    // Ideally we'd have dedicated providers for recently added/played from Navidrome
    // but for now, we'll reuse starredProvider as a placeholder for 'Recently Added'
    final recentlyAdded = ref.watch(starredProvider); 

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flacify',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00F0FF),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hi-Fi music from your server',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white38,
                        ),
                  ),
                ],
              ),
            ),
          ),
          
          _buildSectionTitle(context, 'Recommendations Matches'),
          _buildHorizontalSongList(recommended, ref),

          _buildSectionTitle(context, 'Recently Added / Starred'),
          _buildHorizontalSongList(recentlyAdded, ref),

          _buildSectionTitle(context, 'All Albums'),
          albums.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
            ),
            data: (list) => SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => AlbumCard(
                    album: list[i],
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => AlbumScreen(album: list[i]),
                      ),
                    ),
                  ),
                  childCount: list.length,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

