import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navidrome_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/song_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchProvider(_query));
    final player = ref.read(playerProvider.notifier);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              controller: _controller,
              hintText: 'Search songs, artists, albums...',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: results.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (songs) => songs.isEmpty
                  ? Center(
                      child: Text(
                        _query.isEmpty
                            ? 'Start typing to search'
                            : 'No results for "$_query"',
                        style: const TextStyle(color: Colors.white38),
                      ),
                    )
                  : ListView.builder(
                      itemCount: songs.length,
                      itemBuilder: (ctx, i) => SongTile(
                        song: songs[i],
                        onTap: () => player.playQueue(songs, index: i),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
