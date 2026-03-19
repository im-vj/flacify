import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';
import 'navidrome_provider.dart';

class PlayerNotifier extends StateNotifier<PlayerState> {
  final NavidromeService _navidrome;
  final AudioPlayer _player = AudioPlayer();

  PlayerNotifier(this._navidrome) : super(PlayerState()) {
    _player.playerStateStream.listen((s) {
      state = state.copyWith(
        isPlaying: s.playing,
        isLoading: s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering,
      );
    });
    _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _player.durationStream.listen((dur) {
      state = state.copyWith(duration: dur ?? Duration.zero);
    });
    _player.currentIndexStream.listen((index) {
      if (index != null && index < state.queue.length) {
        state = state.copyWith(currentIndex: index);
      }
    });
  }

  AudioPlayer get player => _player;

  Future<void> playQueue(List<Song> songs, {int index = 0}) async {
    state = state.copyWith(queue: songs, currentIndex: index);
    final sources = songs
        .map((s) => AudioSource.uri(Uri.parse(_navidrome.streamUrl(s.id))))
        .toList();
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: index,
    );
    await _player.play();
  }

  Future<void> playSong(Song song) async {
    await playQueue([song]);
  }

  Future<void> togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> next() async => await _player.seekToNext();
  Future<void> previous() async => await _player.seekToPrevious();

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void setShuffling(bool value) {
    _player.setShuffleModeEnabled(value);
    state = state.copyWith(isShuffling: value);
  }

  void setCycling(LoopMode mode) {
    _player.setLoopMode(mode);
    state = state.copyWith(loopMode: mode);
  }

  Song? get currentSong {
    if (state.queue.isEmpty) return null;
    return state.queue[state.currentIndex];
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

class PlayerState {
  final List<Song> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool isLoading;
  final bool isShuffling;
  final LoopMode loopMode;
  final Duration position;
  final Duration duration;

  PlayerState({
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.isLoading = false,
    this.isShuffling = false,
    this.loopMode = LoopMode.off,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  PlayerState copyWith({
    List<Song>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? isLoading,
    bool? isShuffling,
    LoopMode? loopMode,
    Duration? position,
    Duration? duration,
  }) =>
      PlayerState(
        queue: queue ?? this.queue,
        currentIndex: currentIndex ?? this.currentIndex,
        isPlaying: isPlaying ?? this.isPlaying,
        isLoading: isLoading ?? this.isLoading,
        isShuffling: isShuffling ?? this.isShuffling,
        loopMode: loopMode ?? this.loopMode,
        position: position ?? this.position,
        duration: duration ?? this.duration,
      );
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref.watch(navidromeServiceProvider));
});
