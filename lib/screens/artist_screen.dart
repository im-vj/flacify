import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist.dart';
import '../services/navidrome_service.dart';
import '../providers/navidrome_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';
import '../widgets/mini_player_wrapper.dart';
import 'album_screen.dart';

class ArtistScreen extends ConsumerWidget {
  final Artist artist;
  const ArtistScreen({super.key, required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(artistAlbumsProvider(artist.id));
    final songsAsync = ref.watch(artistTopSongsProvider(artist.name));
    final player = ref.read(playerProvider.notifier);
    final navidrome = ref.read(navidromeServiceProvider);

    return MiniPlayerWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: CustomScrollView(
          slivers: [
            _ArtistHeader(artist: artist, navidrome: navidrome),
            _buildTopSongsSection(songsAsync, player),
            _buildAlbumsSection(albumsAsync),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSongsSection(AsyncValue songsAsync, PlayerNotifier player) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Color(0xFF00F0FF), size: 20),
                SizedBox(width: 8),
                Text(
                  'Top Songs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          songsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
            ),
            data: (songs) {
              if (songs.isEmpty) return const SizedBox();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _PlayAllButton(
                      songs: songs,
                      player: player,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    songs.length > 6 ? 6 : songs.length,
                    (i) => SongTile(
                      song: songs[i],
                      index: i + 1,
                      onTap: () => player.playQueue(songs, index: i),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsSection(AsyncValue albumsAsync) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(
              children: [
                Icon(Icons.album, color: Color(0xFF00F0FF), size: 20),
                SizedBox(width: 8),
                Text(
                  'Albums',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          albumsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
            ),
            data: (albums) {
              if (albums.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No albums found',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: albums.length,
                  itemBuilder: (ctx, i) => _AlbumGridItem(
                    album: albums[i],
                    index: i,
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms);
            },
          ),
        ],
      ),
    );
  }
}

class _ArtistHeader extends StatelessWidget {
  final Artist artist;
  final NavidromeService? navidrome;

  const _ArtistHeader({required this.artist, this.navidrome});

  @override
  Widget build(BuildContext context) {
    final coverUrl = navidrome?.coverArtUrl(artist.coverArtId, size: 512) ?? '';

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF0A0A0F),
      leading: _BackButton(),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          artist.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: coverUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _ArtistPlaceholder(name: artist.name),
              )
            else
              _ArtistPlaceholder(name: artist.name),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0A0A0F).withValues(alpha: 0.5),
                    const Color(0xFF0A0A0F),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'artist-${artist.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 3),
                      ),
                      child: ClipOval(
                        child: coverUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: navidrome?.coverArtUrl(artist.coverArtId, size: 256) ?? '',
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _ArtistAvatar(name: artist.name),
                              )
                            : _ArtistAvatar(name: artist.name),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistPlaceholder extends StatelessWidget {
  final String name;

  const _ArtistPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF0A0A0F),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 80,
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}

class _ArtistAvatar extends StatelessWidget {
  final String name;

  const _ArtistAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

class _PlayAllButton extends StatelessWidget {
  final List songs;
  final PlayerNotifier player;

  const _PlayAllButton({required this.songs, required this.player});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => player.playQueue(songs.cast(), index: 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00F0FF), Color(0xFF00B4D8)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
            const SizedBox(width: 6),
            const Text(
              'Play All',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${songs.length}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

class _AlbumGridItem extends StatelessWidget {
  final dynamic album;
  final int index;

  const _AlbumGridItem({required this.album, required this.index});

  @override
  Widget build(BuildContext context) {
    final navidrome = ProviderScope.containerOf(context).read(navidromeServiceProvider);
    final coverUrl = navidrome?.coverArtUrl(album.coverArtId, size: 256) ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AlbumScreen(album: album)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: coverUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _AlbumPlaceholder(),
                          )
                        : _AlbumPlaceholder(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    album.year?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).scale(
          begin: const Offset(0.95, 0.95),
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }
}

class _AlbumPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF252535),
      child: const Center(
        child: Icon(Icons.album_rounded, color: Colors.white24, size: 40),
      ),
    );
  }
}
