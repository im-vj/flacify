import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navidrome_provider.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';
import 'mini_player.dart';

class MiniPlayerWrapper extends ConsumerWidget {
  final Widget child;

  const MiniPlayerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final activeServer = ref.watch(activeServerProvider);
    final player = ref.read(playerProvider.notifier);

    final showPlayer = activeServer != null && 
                       playerState.queue.isNotEmpty &&
                       player.currentSong != null;

    return Stack(
      children: [
        child,
        if (showPlayer)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: MiniPlayer(
                song: player.currentSong!,
                isPlaying: playerState.isPlaying,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                  );
                },
                onToggle: () => player.togglePlay(),
                onNext: () => player.next(),
              ),
            ),
          ),
      ],
    );
  }
}
