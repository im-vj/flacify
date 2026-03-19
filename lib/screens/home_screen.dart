import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navidrome_provider.dart';
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
              bottom: 80,
              left: 8,
              right: 8,
              child: MiniPlayer(
                song: player.currentSong!,
                isPlaying: playerState.isPlaying,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlayerScreen(),
                  ),
                ),
                onToggle: () => player.togglePlay(),
                onNext: () => player.next(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF12121A),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumsProvider);

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
                          color: const Color(0xFF6C63FF),
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Albums',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
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

