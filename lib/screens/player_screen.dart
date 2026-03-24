import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/song.dart';
import '../providers/navidrome_provider.dart';
import '../providers/player_provider.dart';
import '../providers/ai_provider.dart';
import '../services/cast_service.dart';
import '../services/lyrics_service.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_sheets/sleep_timer_sheet.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  final LyricsService _lyricsService = LyricsService();
  List<LyricLine>? _lyrics;
  bool _loadingLyrics = false;
  bool _showLyrics = false;
  String? _lastSongId;
  Color? _dominantColor;

  @override
  void deactivate() {
    super.deactivate();
  }

  Future<void> _extractDominantColor(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        maximumColorCount: 20,
      );
      if (mounted) {
        setState(() {
          _dominantColor = paletteGenerator.vibrantColor?.color ??
              paletteGenerator.dominantColor?.color;
        });
      }
    } catch (e) {
      debugPrint('Error extracting color: $e');
    }
  }

  Future<void> _loadLyrics(Song song) async {
    if (song.id == _lastSongId) return;
    _lastSongId = song.id;
    setState(() { _loadingLyrics = true; _lyrics = null; });
    final lines = await _lyricsService.getSyncedLyrics(
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
    );
    if (mounted) setState(() { _lyrics = lines; _loadingLyrics = false; });
  }

  int _currentLyricIndex(int posMs) {
    if (_lyrics == null || _lyrics!.isEmpty) return -1;
    int idx = 0;
    for (int i = 0; i < _lyrics!.length; i++) {
      if (_lyrics![i].timeMs <= posMs) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }

  void _showQueueSheet(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Consumer(
          builder: (context, sheetRef, _) {
            final playerState = sheetRef.watch(playerProvider);
            final navidrome = sheetRef.watch(navidromeServiceProvider);

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                    child: Row(
                      children: [
                        const Text(
                          'Queue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${playerState.queue.length} songs',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 22),
                      itemCount: playerState.queue.length,
                      itemBuilder: (ctx, i) {
                        final s = playerState.queue[i];
                        final isCurrent = i == playerState.currentIndex;
                        final coverUrl = navidrome?.coverArtUrl(s.coverArtId) ?? '';

                        return GestureDetector(
                          onTap: () {
                            player.playQueue(playerState.queue, index: i);
                            Navigator.pop(ctx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrent
                                    ? AppColors.sky.withValues(alpha: 0.45)
                                    : Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: coverUrl.isNotEmpty
                                        ? CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover)
                                        : Container(
                                            color: Colors.white10,
                                            child: const Icon(Icons.music_note_rounded, color: Colors.white30),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 22,
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: isCurrent ? Colors.white : Colors.white54,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isCurrent ? Colors.white : Colors.white70,
                                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        s.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isCurrent)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(Icons.graphic_eq_rounded, color: AppColors.sky),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.white38),
                                    onPressed: () => player.removeFromQueue(i),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider.select((s) => (position: s.position, duration: s.duration)));
    final player = ref.read(playerProvider.notifier);
    final navidrome = ref.read(navidromeServiceProvider);
    final song = player.currentSong;

    if (song == null) return const Scaffold(body: Center(child: Text('Nothing playing')));

    _loadLyrics(song);

    final coverUrl = navidrome?.highResCoverArtUrl(song.coverArtId) ?? '';
    final posMs = playerState.position.inMilliseconds;
    final lyricIdx = _currentLyricIndex(posMs);

    if (_dominantColor == null && coverUrl.isNotEmpty) {
       _extractDominantColor(coverUrl);
    }

    final bgColor = (_dominantColor ?? const Color(0xFF1A1A2E)).withValues(alpha: 0.95);
    final bgColorDark = Color.lerp(bgColor, Colors.black, 0.5) ?? Colors.black;

    return Scaffold(
      body: Stack(
        children: [
          // Blurred album art background — Chora style
          if (coverUrl.isNotEmpty)
            Positioned.fill(
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      memCacheHeight: 800,
                      errorWidget: (_, __, ___) => Container(color: bgColorDark),
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              bgColor.withValues(alpha: 0.55),
                              bgColorDark.withValues(alpha: 0.88),
                              Colors.black.withValues(alpha: 0.95),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Now Playing',
                                style: TextStyle(fontSize: 11, color: Colors.white60, letterSpacing: 1.2)),
                            Text(song.album,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _showLyrics ? Icons.music_note_rounded : Icons.lyrics_rounded,
                          color: _showLyrics ? Colors.white : Colors.white60,
                        ),
                        onPressed: () => setState(() => _showLyrics = !_showLyrics),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cast_rounded, color: Colors.white60),
                        onPressed: () async {
                          final service = ref.read(castServiceProvider);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Discovering cast devices...')));
                          final devices = await service.discoverDevices();
                          if (!context.mounted) return;
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: const Color(0xFF1A1A2E),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                            builder: (_) => ListView(
                              children: [
                                const ListTile(title: Text('Cast to Device', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                if (devices.isEmpty) const ListTile(title: Text('No devices found', style: TextStyle(color: Colors.white54))),
                                for (final d in devices)
                                  ListTile(
                                    leading: const Icon(Icons.tv_rounded, color: Colors.white70),
                                    title: Text(d.name, style: const TextStyle(color: Colors.white)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      service.connectAndPlay(d, song);
                                    },
                                  )
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Album art or Lyrics
                Expanded(
                  child: _showLyrics
                      ? _LyricsView(
                          lyrics: _lyrics,
                          loading: _loadingLyrics,
                          currentIdx: lyricIdx,
                          accentColor: _dominantColor,
                        )
                      : _buildAlbumArt(coverUrl),
                ),

                // Song metadata — Chora style
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${song.artist} • ${song.year ?? ''}',
                        style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (song.suffix != null)
                            _MetaChip(label: song.suffix!.toUpperCase()),
                          if (song.bitRate != null) ...[
                            const SizedBox(width: 6),
                            _MetaChip(label: '${song.bitRate}kbps'),
                          ],
                          const SizedBox(width: 6),
                          const _MetaChip(label: 'Navidrome'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress bar — Chora style
                _ChoraProgressBar(accentColor: _dominantColor),

                // Controls — Chora style
                _ChoraControls(song: song, accentColor: _dominantColor),

                // Bottom toolbar
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border_rounded, color: Colors.white70),
                        onPressed: () => navidrome?.star(song.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.timer_outlined, color: Colors.white70),
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const SleepTimerSheet(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music_rounded, color: Colors.white70),
                        onPressed: () => _showQueueSheet(context, ref),
                      ),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white70),
                        onPressed: () async {
                           final aiService = ref.read(aiServiceProvider);
                           if (aiService == null) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set Gemini API Key in Settings')));
                             return;
                           }
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI is analyzing... generating mix!')));
                           try {
                             final playerState = ref.read(playerProvider);
                             final player = ref.read(playerProvider.notifier);
                             final suggestions = await aiService.getNextSongSuggestions(playerState.queue);
                             if (suggestions.isEmpty) {
                               if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI could not find matching songs in your library.')));
                               return;
                             }
                             await player.queueLastAll(suggestions);
                             if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI added ${suggestions.length} songs to queue!')));
                           } catch (e) {
                             if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Error: $e')));
                           }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white70),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: const Color(0xFF1A1A2E),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                            builder: (ctx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: coverUrl.isNotEmpty 
                                             ? CachedNetworkImage(
                                              imageUrl: coverUrl,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => Container(color: Colors.white12, width: 48, height: 48),
                                            ) : Container(color: Colors.white12, width: 48, height: 48),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              Text(song.artist, style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(color: Colors.white12),
                                  ListTile(
                                    leading: const Icon(Icons.queue_music_rounded, color: Colors.white),
                                    title: const Text('Add to Queue', style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      player.queueLast(song);
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Queue')));
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.playlist_play_rounded, color: Colors.white),
                                    title: const Text('Play Next', style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      player.queueNext(song);
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Will play next')));
                                    },
                                  ),
                                  // Could add view artist / album if we had the context easily available
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(String coverUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (_dominantColor ?? Colors.black).withValues(alpha: 0.5),
                blurRadius: 40,
                offset: const Offset(0, 16),
                spreadRadius: 4,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: coverUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.black26,
                      child: const Icon(Icons.album_rounded, color: Colors.white24, size: 80),
                    ),
                  )
                : Container(
                    color: Colors.black26,
                    child: const Icon(Icons.album_rounded, color: Colors.white24, size: 80),
                  ),
          ),
        ),
      ).animate().fadeIn(duration: 250.ms).scale(begin: const Offset(0.96, 0.96)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
    );
  }
}

class _ChoraProgressBar extends ConsumerWidget {
  final Color? accentColor;
  const _ChoraProgressBar({this.accentColor});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playerProvider.select((s) => s.position));
    final duration = ref.watch(playerProvider.select((s) => s.duration));
    final player = ref.read(playerProvider.notifier);

    final posMs = position.inMilliseconds;
    final durMs = duration.inMilliseconds;
    final progress = durMs > 0 ? posMs / durMs : 0.0;
    final accent = accentColor ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              // Chora uses no thumb visible, just a transparent dot
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: accent.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (v) => player.seek(
                Duration(milliseconds: (v * durMs).toInt()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(position),
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(_fmt(duration),
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoraControls extends ConsumerWidget {
  final Song song;
  final Color? accentColor;
  const _ChoraControls({required this.song, this.accentColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShuffling = ref.watch(playerProvider.select((s) => s.isShuffling));
    final loopMode = ref.watch(playerProvider.select((s) => s.loopMode));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final isLoading = ref.watch(playerProvider.select((s) => s.isLoading));
    final player = ref.read(playerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.shuffle_rounded,
              color: isShuffling ? Colors.white : Colors.white38,
              size: 26,
            ),
            onPressed: () => player.setShuffling(!isShuffling),
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous_rounded, size: 44, color: Colors.white),
            onPressed: () => player.previous(),
          ),
          // Play/Pause — Chora pill shape
          GestureDetector(
            onTap: () => player.togglePlay(),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: (accentColor ?? Colors.white).withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 44,
                      color: Colors.black,
                    ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, size: 44, color: Colors.white),
            onPressed: () => player.next(),
          ),
          IconButton(
            icon: Icon(
              loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              color: loopMode != LoopMode.off ? Colors.white : Colors.white38,
              size: 26,
            ),
            onPressed: () {
              final next = loopMode == LoopMode.off
                  ? LoopMode.all
                  : loopMode == LoopMode.all
                      ? LoopMode.one
                      : LoopMode.off;
              player.setCycling(next);
            },
          ),
        ],
      ),
    );
  }
}

class _LyricsView extends StatefulWidget {
  final List<LyricLine>? lyrics;
  final bool loading;
  final int currentIdx;
  final Color? accentColor;

  const _LyricsView({
    required this.lyrics,
    required this.loading,
    required this.currentIdx,
    this.accentColor,
  });

  @override
  State<_LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<_LyricsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(_LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIdx != oldWidget.currentIdx && widget.currentIdx >= 0) {
      _scrollToLyric(widget.currentIdx);
    }
  }

  void _scrollToLyric(int index) {
    if (!_scrollController.hasClients) return;
    final offset = (index * 64.0) - 180;
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white54));
    }
    if (widget.lyrics == null || widget.lyrics!.isEmpty) {
      return const Center(
        child: Text('No lyrics available',
            style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 100),
      itemCount: widget.lyrics!.length,
      itemBuilder: (ctx, i) {
        final isActive = i == widget.currentIdx;
        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: isActive ? 24 : 17,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
            color: isActive ? Colors.white : Colors.white30,
            height: 1.5,
            fontFamily: 'Inter',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(widget.lyrics![i].text, textAlign: TextAlign.center),
          ),
        );
      },
    );
  }
}
