import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';
import '../services/storage_service.dart';
import 'navidrome_provider.dart';

final miniPlayerVisibilityProvider = StateProvider<bool>((ref) => true);

class PlayerNotifier extends StateNotifier<PlayerState> {
  final Ref _ref;
  final AudioPlayer _player = AudioPlayer();
  Timer? _sleepTimer;
  final List<StreamSubscription<dynamic>> _playerSubscriptions = [];

  PlayerNotifier(this._ref) : super(const PlayerState()) {
    _playerSubscriptions.add(_player.playerStateStream.listen((s) {
      state = state.copyWith(
        isPlaying: s.playing,
        isLoading: s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering,
      );
    }));
    _playerSubscriptions.add(_player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    }));
    _playerSubscriptions.add(_player.durationStream.listen((dur) {
      state = state.copyWith(duration: dur ?? Duration.zero);
    }));
    _playerSubscriptions.add(_player.currentIndexStream.listen((index) {
      if (index != null && index < state.queue.length) {
        state = state.copyWith(currentIndex: index);
      }
    }));
  }

  AudioPlayer get player => _player;
  NavidromeService? get _navidrome => _ref.read(navidromeServiceProvider);
  StorageService get _storage => _ref.read(storageProvider);

  Future<void> playQueue(List<Song> songs, {int index = 0}) async {
    if (_navidrome == null) return;
    state = state.copyWith(queue: songs, currentIndex: index);
    
    final sources = <AudioSource>[];
    for (final s in songs) {
      sources.add(_createSource(s));
    }
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: index,
    );
    await _player.play();
  }

  Future<void> playSong(Song song) async {
    await playQueue([song]);
  }

  Future<void> queueNext(Song song) async {
    if (_navidrome == null || state.queue.isEmpty) {
      await playSong(song);
      return;
    }
    final newQueue = List<Song>.from(state.queue);
    final insertIndex = state.currentIndex + 1;
    newQueue.insert(insertIndex, song);
    state = state.copyWith(queue: newQueue);

    if (_player.audioSource is ConcatenatingAudioSource) {
      final concat = _player.audioSource as ConcatenatingAudioSource;
      await concat.insert(insertIndex, _createSource(song));
    }
  }

  Future<void> queueLast(Song song) async {
    if (_navidrome == null || state.queue.isEmpty) {
      await playSong(song);
      return;
    }
    final newQueue = List<Song>.from(state.queue);
    newQueue.add(song);
    state = state.copyWith(queue: newQueue);

    if (_player.audioSource is ConcatenatingAudioSource) {
      final concat = _player.audioSource as ConcatenatingAudioSource;
      await concat.add(_createSource(song));
    }
  }

  Future<void> queueLastAll(List<Song> songs) async {
    if (songs.isEmpty) return;
    if (_navidrome == null || state.queue.isEmpty) {
      // Play the first one, then queue the rest
      await playSong(songs.first);
      if (songs.length > 1) {
        await queueLastAll(songs.sublist(1));
      }
      return;
    }
    final newQueue = List<Song>.from(state.queue);
    newQueue.addAll(songs);
    state = state.copyWith(queue: newQueue);

    if (_player.audioSource is ConcatenatingAudioSource) {
      final concat = _player.audioSource as ConcatenatingAudioSource;
      final sources = songs.map((s) => _createSource(s)).toList();
      await concat.addAll(sources);
    }
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= state.queue.length) return;

    final newQueue = List<Song>.from(state.queue)..removeAt(index);

    if (newQueue.isEmpty) {
      await _player.stop();
      state = state.copyWith(
        queue: const [],
        currentIndex: 0,
        position: Duration.zero,
        duration: Duration.zero,
        isPlaying: false,
      );
      return;
    }

    final oldCurrent = state.currentIndex;
    int newCurrent = oldCurrent;
    if (index < oldCurrent) {
      newCurrent = oldCurrent - 1;
    } else if (index == oldCurrent) {
      newCurrent = oldCurrent >= newQueue.length ? newQueue.length - 1 : oldCurrent;
    }

    state = state.copyWith(queue: newQueue, currentIndex: newCurrent);

    final source = _player.audioSource;
    if (source is ConcatenatingAudioSource) {
      try {
        await source.removeAt(index);
      } catch (_) {
        // Fallback to a full reload if source state diverged from app state.
        await playQueue(newQueue, index: newCurrent);
      }
    } else {
      await playQueue(newQueue, index: newCurrent);
    }
  }

  AudioSource _createSource(Song s) {
    final localPath = _storage.getDownloadedPath(s.id);
    final uri = (localPath != null && localPath.isNotEmpty)
        ? Uri.file(localPath)
        : Uri.parse(_navidrome!.streamUrl(s.id));
    return AudioSource.uri(
      uri,
      tag: MediaItem(
        id: s.id,
        album: s.album,
        title: s.title,
        artist: s.artist,
        genre: s.genre,
        duration: Duration(seconds: s.duration),
        artUri: Uri.parse(_navidrome!.highResCoverArtUrl(s.coverArtId)),
        extras: {
          'isOffline': localPath != null && localPath.isNotEmpty,
          'albumId': s.albumId,
          'artistId': s.artistId,
          'year': s.year,
          'bitRate': s.bitRate,
          'suffix': s.suffix,
        },
      ),
    );
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

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    state = state.copyWith(sleepTimerEnd: DateTime.now().add(duration));
    _sleepTimer = Timer(duration, () {
      _player.pause();
      state = state.copyWith(clearSleepTimer: true);
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    state = state.copyWith(clearSleepTimer: true);
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    for (final sub in _playerSubscriptions) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}

class PlayerState extends Equatable {
  final List<Song> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool isLoading;
  final bool isShuffling;
  final LoopMode loopMode;
  final Duration position;
  final Duration duration;
  final DateTime? sleepTimerEnd;

  const PlayerState({
    this.queue = const [],
    this.currentIndex = 0,
    this.isPlaying = false,
    this.isLoading = false,
    this.isShuffling = false,
    this.loopMode = LoopMode.off,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.sleepTimerEnd,
  });

  @override
  List<Object?> get props => [queue, currentIndex, isPlaying, isLoading, isShuffling, loopMode, position, duration, sleepTimerEnd];

  PlayerState copyWith({
    List<Song>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? isLoading,
    bool? isShuffling,
    LoopMode? loopMode,
    Duration? position,
    Duration? duration,
    DateTime? sleepTimerEnd,
    bool clearSleepTimer = false,
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
        sleepTimerEnd: clearSleepTimer ? null : (sleepTimerEnd ?? this.sleepTimerEnd),
      );
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref);
});
