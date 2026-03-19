import 'package:cast/cast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../services/navidrome_service.dart';
import '../providers/navidrome_provider.dart';

final castServiceProvider = Provider<CastService>((ref) {
  final api = ref.watch(navidromeServiceProvider);
  return CastService(api);
});

class CastService {
  final NavidromeService? api;
  CastSession? _session;

  CastService(this.api);

  Future<List<CastDevice>> discoverDevices() async {
    return await CastDiscoveryService().search();
  }

  Future<void> connectAndPlay(CastDevice device, Song song) async {
    if (api == null) return;
    _session = await CastSessionManager().startSession(device);

    final url = api!.streamUrl(song.id);
    final coverUrl = api!.coverArtUrl(song.coverArtId);
  
    final message = {
      'type': 'LOAD',
      'media': {
        'contentId': url,
        'streamType': 'BUFFERED',
        'contentType': 'audio/mp3',
        'metadata': {
          'musicTrackData': {
            'title': song.title,
            'artist': song.artist,
            'albumName': song.album,
          },
          'metadataType': 3,
          'title': song.title,
          'images': [{'url': coverUrl}]
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
