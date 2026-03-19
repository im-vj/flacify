import 'package:hive_flutter/hive_flutter.dart';
import '../models/server_config.dart';

class StorageService {
  static const String _serverBoxName = 'servers';
  static const String _activeServerKey = 'activeServerId';

  late Box<ServerConfig> _serverBox;
  late Box _settingsBox;

  Future<void> init() async {
    Hive.registerAdapter(ServerConfigAdapter());
    _serverBox = await Hive.openBox<ServerConfig>(_serverBoxName);
    _settingsBox = await Hive.openBox('settings');
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
}
