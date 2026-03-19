import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navidrome_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBitrate = ref.watch(bitrateProvider);
    final notifier = ref.read(bitrateProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Transcoding & Quality',
              style: TextStyle(fontSize: 14, color: Color(0xFF00F0FF), fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int?>(
              segments: const [
                ButtonSegment(value: null, label: Text('FLAC/Raw')),
                ButtonSegment(value: 320, label: Text('320 kbps')),
                ButtonSegment(value: 128, label: Text('128 kbps')),
              ],
              selected: {currentBitrate},
              onSelectionChanged: (Set<int?> newSelection) {
                notifier.setBitrate(newSelection.first);
              },
            ),
          ),
          
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white54),
            title: const Text('Switch Server'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
