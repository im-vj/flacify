import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_provider.dart';

class FormattedTimer {
  final String label;
  final Duration? duration;

  FormattedTimer(this.label, this.duration);
}

class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerProvider.notifier);
    
    final timers = [
      FormattedTimer('Off', null),
      FormattedTimer('5 Minutes', const Duration(minutes: 5)),
      FormattedTimer('15 Minutes', const Duration(minutes: 15)),
      FormattedTimer('30 Minutes', const Duration(minutes: 30)),
      FormattedTimer('1 Hour', const Duration(hours: 1)),
      // 'End of Track' would require watching the remaining duration, which is more complex in a static list
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF160033),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sleep Timer',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          ...timers.map((t) => ListTile(
                title: Text(t.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                onTap: () {
                  if (t.duration == null) {
                    player.cancelSleepTimer();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sleep Timer Disabled')),
                    );
                  } else {
                    player.setSleepTimer(t.duration!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sleep Timer set for ${t.label}')),
                    );
                  }
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
