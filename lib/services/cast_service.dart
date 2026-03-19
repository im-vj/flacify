import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../providers/navidrome_provider.dart';
import '../services/navidrome_service.dart';

/// A stub cast device — name is displayed in the picker UI.
class CastDevice {
  final String name;
  final String host;
  final int port;
  const CastDevice({required this.name, required this.host, required this.port});
}

/// A stub cast session — sends DIAL / HTTP requests to a Chromecast.
class CastSession {
  static const String kNamespaceMedia = 'urn:x-cast:com.google.cast.media';
  static const String kNamespaceReceiver = 'urn:x-cast:com.google.cast.tp.receiver';

  void sendMessage(String namespace, Map<String, dynamic> message) {
    // No-op stub — real implementation would use TCP to communicate with the cast device.
  }

  void close() {}
}

final castServiceProvider = Provider<CastService>((ref) {
  final api = ref.watch(navidromeServiceProvider);
  return CastService(api);
});

/// Chromecast discovery + playback service.
/// Currently a graceful stub — discovery always returns an empty list
/// because the `cast` package is incompatible with bonsoir ≥ 6.x.
/// Kept in the codebase so the Cast button in PlayerScreen compiles and
/// can be wired to a working implementation once a compatible package is
/// available (e.g. flutter_cast_framework or a direct TCP implementation).
class CastService {
  final NavidromeService? api;
  CastSession? _session;

  CastService(this.api);

  /// Discovers Chromecast devices on the local network via mDNS.
  /// Returns empty list in this stub implementation.
  Future<List<CastDevice>> discoverDevices() async {
    // TODO: Replace with a working mDNS discovery implementation
    // once a package compatible with bonsoir 6.x is available.
    return [];
  }

  Future<void> connectAndPlay(CastDevice device, Song song) async {
    if (api == null) return;
    _session = CastSession();

    final url = api!.streamUrl(song.id);
    final coverUrl = api!.coverArtUrl(song.coverArtId);

    final message = {
      'type': 'LOAD',
      'media': {
        'contentId': url,
        'streamType': 'BUFFERED',
        'contentType': 'audio/mp3',
        'metadata': {
          'metadataType': 3,
          'title': song.title,
          'images': [{'url': coverUrl}],
        }
      }
    };

    _session?.sendMessage(CastSession.kNamespaceMedia, message);
  }

  void disconnect() {
    _session?.sendMessage(CastSession.kNamespaceReceiver, {'type': 'STOP'});
    _session?.close();
    _session = null;
  }
}
