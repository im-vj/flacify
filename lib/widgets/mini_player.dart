import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/navidrome_provider.dart';
import '../providers/player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onNext;

  const MiniPlayer({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    required this.onToggle,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navidrome = ref.read(navidromeServiceProvider);
    final playerState = ref.watch(playerProvider);
    final coverUrl = navidrome?.coverArtUrl(song.coverArtId, size: 128) ?? '';

    final progress = playerState.duration.inMilliseconds > 0
        ? playerState.position.inMilliseconds /
            playerState.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      // Album art
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: coverUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: coverUrl,
                                width: 46,
                                height: 46,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 46,
                                height: 46,
                                color: Colors.white12,
                                child: const Icon(Icons.music_note_rounded, color: Colors.white24),
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
                                  fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                            ),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                        onPressed: onToggle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 30, color: Colors.white70),
                        onPressed: onNext,
                      ),
                    ],
                  ),
                ),
                // Progress bar
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 2,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
