import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';
import '../providers/navidrome_provider.dart';
import '../utils/permission_handler.dart';
import 'navidrome_service.dart';
import 'storage_service.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final storage = ref.watch(storageProvider);
  final api = ref.watch(navidromeServiceProvider);
  return DownloadService(storage, api);
});

class DownloadService {
  final StorageService storage;
  final NavidromeService? api;
  final Dio _dio = Dio();

  DownloadService(this.storage, this.api);

  Future<void> downloadSong(Song song) async {
    if (api == null) return;

    // Check permissions before downloading
    final hasPermissions = await AppPermissions.hasDownloadPermissions();
    if (!hasPermissions) {
      final granted = await AppPermissions.requestStoragePermission();
      if (!granted) {
        throw Exception('Storage permission required for downloads');
      }
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${song.id}.mp3';

      // Always grab transcoded or highest quality available via streamUrl
      final url = api!.streamUrl(song.id);

      await _dio.download(url, savePath);
      await storage.saveDownloadedPath(song.id, savePath);
    } catch (e) {
      // Handle download error
      rethrow;
    }
  }

  Future<void> deleteSong(Song song) async {
    final path = storage.getDownloadedPath(song.id);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      storage.saveDownloadedPath(song.id, ''); // Clearing the mapping
    }
  }

  bool isDownloaded(String songId) {
    final path = storage.getDownloadedPath(songId);
    return path != null && path.isNotEmpty;
  }
}
