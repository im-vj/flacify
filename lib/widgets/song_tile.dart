import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/navidrome_provider.dart';
import '../providers/player_provider.dart';

class SongTile extends ConsumerWidget {
  final Song song;
  final VoidCallback onTap;
  final int? index;
  const SongTile({super.key, required this.song, required this.onTap, this.index});

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navidrome = ref.read(navidromeServiceProvider);
    final playerState = ref.watch(playerProvider);
    final player = ref.read(playerProvider.notifier);
    final coverUrl = navidrome.coverArtUrl(song.coverArtId, size: 128);
    final isCurrent = player.currentSong?.id == song.id;

    return ListTile(
      onTap: onTap,
      leading: index != null
          ? SizedBox(
              width: 40,
              child: isCurrent
                  ? Icon(
                      playerState.isPlaying
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: const Color(0xFF6C63FF),
                      size: 20,
                    )
                  : Text(
                      '$index',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white38),
                    ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFF1E1E2E),
                        child: const Icon(Icons.music_note_rounded,
                            color: Colors.white24, size: 20),
                      ),
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      color: const Color(0xFF1E1E2E),
                      child: const Icon(Icons.music_note_rounded,
                          color: Colors.white24, size: 20),
                    ),
            ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isCurrent ? const Color(0xFF6C63FF) : Colors.white,
        ),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (song.suffix?.toLowerCase() == 'flac')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6C63FF)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'FLAC',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(song.duration),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, size: 18),
            color: Colors.white38,
            onPressed: () => _showOptions(context, ref, player),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, PlayerNotifier player) {
    final navidrome = ref.read(navidromeServiceProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow_rounded),
            title: const Text('Play now'),
            onTap: () { Navigator.pop(context); player.playSong(song); },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border_rounded),
            title: const Text('Like'),
            onTap: () { Navigator.pop(context); navidrome.star(song.id); },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music_rounded),
            title: const Text('Add to queue'),
            onTap: () { Navigator.pop(context); },
          ),
        ],
      ),
    );
  }
}
