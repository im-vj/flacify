import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navidrome_provider.dart';
import '../widgets/album_card.dart';
import 'album_screen.dart';

class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('All Albums')),
      body: albumsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white38))),
        data: (albums) {
          if (albums.isEmpty) return const Center(child: Text('No albums found', style: TextStyle(color: Colors.white38)));
          return GridView.builder(
            padding: const EdgeInsets.all(16).copyWith(bottom: 120),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: albums.length,
            itemBuilder: (ctx, i) => AlbumCard(
              album: albums[i],
              compact: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AlbumScreen(album: albums[i])),
              ),
            ),
          );
        },
      ),
    );
  }
}
