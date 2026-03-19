import 'package:cached_network_image/cached_network_image.dart';
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
import 'settings_screen.dart';
import 'radio_screen.dart';

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
    RadioScreen(),
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
              left: 12,
              right: 12,
              bottom: 12,
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
      bottomNavigationBar: _ChoraBottomNav(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
      ),
    );
  }
}

/// Chora-style bottom nav with indicator pill
class _ChoraBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _ChoraBottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.search_rounded, label: 'Search'),
      (icon: Icons.library_music_rounded, label: 'Library'),
      (icon: Icons.radio_rounded, label: 'Radio'),
    ];

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isSelected = i == selectedIndex;
              return GestureDetector(
                onTap: () => onDestinationSelected(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 16 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        items[i].icon,
                        color: isSelected ? Colors.white : Colors.white38,
                        size: 24,
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          items[i].label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSongList(AsyncValue<List<Song>> songsAsync, WidgetRef ref) {
    final player = ref.read(playerProvider.notifier);
    return songsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: Colors.white38))),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: SizedBox(height: 100, child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white38)))),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox(height: 100, child: Center(child: Text('No songs', style: TextStyle(color: Colors.white38)))),
          );
        }
        return SliverToBoxAdapter(
          child: SizedBox(
            height: 210,
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
                    width: 148,
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Album art with play overlay
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: coverUrl.isNotEmpty
                                    ? CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover)
                                    : Container(
                                        color: Colors.white10,
                                        child: const Icon(Icons.music_note_rounded, color: Colors.white24, size: 40)),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                        ),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
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
    final recentlyAdded = ref.watch(starredProvider);
    final server = ref.watch(activeServerProvider);
    final username = server?.username ?? 'Music Lover';

    return CustomScrollView(
      slivers: [
        // Chora-style greeting header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome,',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white54, size: 26),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),

        _buildSectionTitle(context, 'Recommended for you'),
        _buildHorizontalSongList(recommended, ref),

        _buildSectionTitle(context, 'Recently Added'),
        _buildHorizontalSongList(recentlyAdded, ref),

        _buildSectionTitle(context, 'Albums'),
        albums.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: Colors.white38)),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white38))),
          ),
          data: (list) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverGrid(
              // Chora-style 3-column grid
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => AlbumCard(
                  album: list[i],
                  compact: true,
                  onTap: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(builder: (_) => AlbumScreen(album: list[i])),
                  ),
                ),
                childCount: list.length,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
