import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navidrome_provider.dart';
import 'artist_screen.dart';

class ArtistsScreen extends ConsumerWidget {
  const ArtistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Artists')),
      body: artistsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white38))),
        data: (artists) {
          if (artists.isEmpty) {
            return const Center(child: Text('No artists found', style: TextStyle(color: Colors.white38)));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: artists.length,
            itemBuilder: (ctx, i) {
              final artist = artists[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Text(artist.name.isNotEmpty ? artist.name[0].toUpperCase() : '?', 
                              style: const TextStyle(color: Colors.white70)),
                ),
                title: Text(artist.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                subtitle: Text('${artist.albumCount} albums', style: const TextStyle(color: Colors.white54)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ArtistScreen(artist: artist)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
