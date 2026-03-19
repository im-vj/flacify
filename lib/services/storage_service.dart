import 'package:hive_flutter/hive_flutter.dart';
import '../models/server_config.dart';

class StorageService {
  static const String _serverBoxName = 'servers';
  static const String _activeServerKey = 'activeServerId';

  late Box<ServerConfig> _serverBox;
  late Box _settingsBox;
  late Box<String> _downloadsBox;

  Future<void> init() async {
    Hive.registerAdapter(ServerConfigAdapter());
    _serverBox = await Hive.openBox<ServerConfig>(_serverBoxName);
    _settingsBox = await Hive.openBox('settings');
    _downloadsBox = await Hive.openBox<String>('downloads');
  }

  List<ServerConfig> getServers() {
    return _serverBox.values.toList();
  }

  ServerConfig? getActiveServer() {
    final activeId = _settingsBox.get(_activeServerKey);
    if (activeId == null) return null;
    return _serverBox.get(activeId);
  }

  Future<void> saveServer(ServerConfig server) async {
    await _serverBox.put(server.id, server);
    // Auto-set as active if it's the first one
    if (getActiveServer() == null) {
      await setActiveServer(server.id);
    }
  }

  Future<void> setActiveServer(String id) async {
    await _settingsBox.put(_activeServerKey, id);
  }

  Future<void> deleteServer(String id) async {
    await _serverBox.delete(id);
    if (getActiveServer()?.id == id) {
      await _settingsBox.delete(_activeServerKey);
    }
  }

  int? getMaxBitrate() {
    return _settingsBox.get('maxBitrate') as int?;
  }

  Future<void> setMaxBitrate(int? bitrate) async {
    if (bitrate == null) {
      await _settingsBox.delete('maxBitrate');
    } else {
      await _settingsBox.put('maxBitrate', bitrate);
    }
  }

  String? getDownloadedPath(String songId) {
    return _downloadsBox.get(songId);
  }

  Future<void> saveDownloadedPath(String songId, String path) async {
    await _downloadsBox.put(songId, path);
  }
}
