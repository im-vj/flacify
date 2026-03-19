import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album.dart';
import '../providers/navidrome_provider.dart';

class AlbumCard extends ConsumerWidget {
  final Album album;
  final VoidCallback onTap;
  const AlbumCard({super.key, required this.album, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navidrome = ref.read(navidromeServiceProvider);
    final coverUrl = navidrome.coverArtUrl(album.coverArtId);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF1E1E2E),
                        child: const Icon(Icons.album_rounded,
                            color: Colors.white24, size: 48),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF1E1E2E),
                        child: const Icon(Icons.album_rounded,
                            color: Colors.white24, size: 48),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF1E1E2E),
                      child: const Icon(Icons.album_rounded,
                          color: Colors.white24, size: 48),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
