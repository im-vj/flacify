import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import '../providers/navidrome_provider.dart';

class AlbumCard extends ConsumerWidget {
  final Album album;
  final VoidCallback onTap;
  /// If true, renders in a compact 3-column grid style (Chora style)
  final bool compact;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
    this.compact = false,
  });

  int get _coverSize => compact ? 128 : 256;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navidrome = ref.read(navidromeServiceProvider);
    final coverUrl = navidrome?.coverArtUrl(album.coverArtId, size: _coverSize) ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(compact ? 10 : 14),
                  child: coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          memCacheHeight: _coverSize,
                          memCacheWidth: _coverSize,
                          placeholder: (_, __) => Container(
                            color: Colors.white.withValues(alpha: 0.08),
                            child: const Icon(Icons.album_rounded, color: Colors.white24, size: 48),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.white.withValues(alpha: 0.08),
                            child: const Icon(Icons.album_rounded, color: Colors.white24, size: 48),
                          ),
                        )
                      : Container(
                          color: Colors.white.withValues(alpha: 0.08),
                          child: const Icon(Icons.album_rounded, color: Colors.white24, size: 48),
                        ),
                ),
                // Chora-style: semi-transparent play button overlay
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: compact ? 28 : 36,
                    height: compact ? 28 : 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: compact ? 18 : 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 13,
              color: Colors.white,
            ),
          ),
          Text(
            album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white38,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}
