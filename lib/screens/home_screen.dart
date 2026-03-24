import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/navidrome_provider.dart';
import '../providers/trending_provider.dart';
import '../providers/player_provider.dart';
import '../services/itunes_service.dart';
import '../widgets/common_widgets.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'songs_screen.dart';
import 'artists_screen.dart';
import 'albums_screen.dart';
import '../widgets/mini_player_wrapper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  final _tabs = const [
    _HomeTab(),
    SongsScreen(),
    ArtistsScreen(),
    AlbumsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MiniPlayerWrapper(child: _tabs[_tab]),
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
      (icon: Icons.music_note_rounded, label: 'Songs'),
      (icon: Icons.person_rounded, label: 'Artists'),
      (icon: Icons.album_rounded, label: 'Albums'),
      (icon: Icons.settings_rounded, label: 'Settings'),
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

  Future<void> _refresh(WidgetRef ref) async {
    invalidateAllCaches(ref);
    final country = ref.read(selectedChartCountryProvider);
    ref.invalidate(trendingSongsProvider(country));
    ref.invalidate(recommendedSongsByCountryProvider(country));
    ref.invalidate(recommendedSongsProvider);
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return SectionTitle(title);
  }

  Widget _buildCountrySelector(WidgetRef ref) {
    final selectedCountry = ref.watch(selectedChartCountryProvider);
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: topChartCountries.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final country = topChartCountries[index];
            final isSelected = selectedCountry == country.code;
            return GestureDetector(
              onTap: () => ref.read(selectedChartCountryProvider.notifier).state = country.code,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00F0FF).withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00F0FF).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  country.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHorizontalSongList(AsyncValue<List<Song>> songsAsync, WidgetRef ref) {
    final player = ref.read(playerProvider.notifier);
    return songsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(height: 180, child: LoadingIndicator()),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: SizedBox(height: 100, child: ErrorDisplay(e)),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox(height: 100, child: EmptyState(message: 'No songs')),
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
                                    ? CachedNetworkImage(
                                        imageUrl: coverUrl,
                                        fit: BoxFit.cover,
                                        memCacheHeight: 300,
                                        memCacheWidth: 300,
                                      )
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

  Widget _buildTopSongsList(AsyncValue<List<ItunesSong>> songsAsync, WidgetRef ref) {
    final player = ref.read(playerProvider.notifier);
    return songsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(height: 240, child: LoadingIndicator()),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: SizedBox(height: 120, child: ErrorDisplay(e)),
      ),
      data: (songs) {
        if (songs.isEmpty) {
          return const SliverToBoxAdapter(
            child: SizedBox(height: 120, child: EmptyState(message: 'No Apple chart songs available')),
          );
        }

        final topSongs = songs.take(10).toList();
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = topSongs[index];
                final rank = (index + 1).toString().padLeft(2, '0');

                return GestureDetector(
                  onTap: () async {
                    final navidrome = ref.read(navidromeServiceProvider);
                    if (navidrome == null) return;

                    try {
                      final query = '${song.title} ${song.artist}';
                      final results = await navidrome.search(query);
                      if (results.isNotEmpty) {
                        await player.playSong(results.first);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Song not found in your library'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not search your library'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121226),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            rank,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 54,
                            height: 54,
                            child: song.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: song.imageUrl,
                                    fit: BoxFit.cover,
                                    memCacheHeight: 150,
                                    memCacheWidth: 150,
                                  )
                                : Container(
                                    color: Colors.white10,
                                    child: const Icon(Icons.music_note_rounded, color: Colors.white24),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final navidrome = ref.read(navidromeServiceProvider);
                            if (navidrome == null) return;

                            try {
                              final query = '${song.title} ${song.artist}';
                              final results = await navidrome.search(query);
                              if (results.isNotEmpty) {
                                await player.queueLast(results.first);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Added to queue'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Song not found in your library'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not add song to queue'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: topSongs.length,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommended = ref.watch(recommendedSongsProvider);
    final recentlyAdded = ref.watch(starredProvider);
    final selectedCountry = ref.watch(selectedChartCountryProvider);
    final topSongs = ref.watch(trendingSongsProvider(selectedCountry));
    final countryName = topChartCountries
        .firstWhere(
          (c) => c.code == selectedCountry,
          orElse: () => const ChartCountry(code: 'us', name: 'USA'),
        )
        .name;
    final server = ref.watch(activeServerProvider);
    final username = server?.username ?? 'Music Lover';

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      color: Colors.white,
      backgroundColor: Colors.white12,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  icon: const Icon(Icons.search_rounded, color: Colors.white54, size: 26),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
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

        _buildSectionTitle(context, 'Top Songs - $countryName'),
        _buildCountrySelector(ref),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        _buildTopSongsList(topSongs, ref),
      ],
      ),
    );
  }
}
