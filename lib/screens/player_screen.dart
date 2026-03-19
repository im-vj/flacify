import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/song.dart';
import '../providers/navidrome_provider.dart';
import '../providers/player_provider.dart';
import '../services/lyrics_service.dart';
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

  Future<void> _extractDominantColor(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
      );
      if (mounted) {
        setState(() {
          _dominantColor = paletteGenerator.dominantColor?.color;
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


  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider.select((s) => (position: s.position, duration: s.duration)));
    final player = ref.read(playerProvider.notifier);
    final navidrome = ref.read(navidromeServiceProvider);
    final song = player.currentSong;

    if (song == null) return const Scaffold(body: Center(child: Text('Nothing playing')));

    _loadLyrics(song);

    final coverUrl = navidrome?.coverArtUrl(song.coverArtId) ?? '';
    final posMs = playerState.position.inMilliseconds;
    final lyricIdx = _currentLyricIndex(posMs);

    if (_dominantColor == null && coverUrl.isNotEmpty && song.id != _lastSongId) {
       _extractDominantColor(coverUrl);
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _dominantColor?.withValues(alpha: 0.8) ?? const Color(0xFF050014),
              const Color(0xFF050014),
            ],
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  _AppBarTitle(song: song),
                  IconButton(
                    icon: Icon(
                      _showLyrics ? Icons.music_note_rounded : Icons.lyrics_rounded,
                      color: _showLyrics ? const Color(0xFF00F0FF) : Colors.white54,
                    ),
                    onPressed: () => setState(() => _showLyrics = !_showLyrics),
                  ),
                ],
              ),
              // Album art or lyrics
              Expanded(
                child: _showLyrics
                    ? _LyricsView(
                        lyrics: _lyrics,
                        loading: _loadingLyrics,
                        currentIdx: lyricIdx,
                      )
                    : _buildAlbumArt(coverUrl, song),
              ),

              // Song info
              _SongInfo(song: song),

              // Progress bar
              const _PlayerProgressBar(),

              // Controls
              const _PlayerControls(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(String coverUrl, Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: coverUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: const Color(0xFF160033),
                    child: const Icon(Icons.album_rounded,
                        color: Colors.white24, size: 80),
                  ),
                )
              : Container(
                  color: const Color(0xFF160033),
                  child: const Icon(Icons.album_rounded,
                      color: Colors.white24, size: 80),
                ),
        ),
      ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95)),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  final Song song;
  const _AppBarTitle({required this.song});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Now Playing',
            style: TextStyle(fontSize: 12, color: Colors.white38)),
        Text(song.album,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _SongInfo extends StatelessWidget {
  final Song song;
  const _SongInfo({required this.song});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (song.suffix?.toLowerCase() == 'flac')
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00F0FF)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('FLAC',
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF00F0FF),
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _PlayerProgressBar extends ConsumerWidget {
  const _PlayerProgressBar();

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: const Color(0xFF00F0FF),
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: const Color(0x226C63FF),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (v) => player.seek(
                Duration(milliseconds: (v * durMs).toInt()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(position),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
                Text(_fmt(duration),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerControls extends ConsumerWidget {
  const _PlayerControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShuffling = ref.watch(playerProvider.select((s) => s.isShuffling));
    final loopMode = ref.watch(playerProvider.select((s) => s.loopMode));
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final isLoading = ref.watch(playerProvider.select((s) => s.isLoading));
    final player = ref.read(playerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.favorite_border_rounded,
                  color: Colors.white,
                ),
                onPressed: () {}, // Future: Toggle favorite
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const SleepTimerSheet(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shuffle_rounded,
                  color: isShuffling ? const Color(0xFF00F0FF) : Colors.white38,
                ),
                onPressed: () => player.setShuffling(!isShuffling),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 40),
                onPressed: () => player.previous(),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00F0FF),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(22),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                        onPressed: () => player.togglePlay(),
                      ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 40),
                onPressed: () => player.next(),
              ),
              IconButton(
                icon: Icon(
                  loopMode == LoopMode.off
                      ? Icons.repeat_rounded
                      : loopMode == LoopMode.all
                          ? Icons.repeat_rounded
                          : Icons.repeat_one_rounded,
                  color: loopMode != LoopMode.off
                      ? const Color(0xFF00F0FF)
                      : Colors.white38,
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
        ],
      ),
    );
  }

}

class _LyricsView extends StatefulWidget {
  final List<LyricLine>? lyrics;
  final bool loading;
  final int currentIdx;

  const _LyricsView({
    required this.lyrics,
    required this.loading,
    required this.currentIdx,
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
    final offset = (index * 52.0) - 160;
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
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.lyrics == null || widget.lyrics!.isEmpty) {
      return const Center(
        child: Text('No lyrics available',
            style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      itemCount: widget.lyrics!.length,
      itemBuilder: (ctx, i) {
        final isActive = i == widget.currentIdx;
        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: isActive ? 22 : 16,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
            color: isActive ? Colors.white : Colors.white24,
            height: 1.6,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(widget.lyrics![i].text, textAlign: TextAlign.center),
          ),
        );
      },
    );
  }
}
