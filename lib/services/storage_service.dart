import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/ai_service.dart';
import '../models/server_config.dart';

class StorageService {
  static const String _serverBoxName = 'servers';
  static const String _activeServerKey = 'activeServerId';
  static const String _aiProviderKey = 'aiProvider';
  static const String _aiApiKeyKey = 'aiApiKey';
  static const String _aiBaseUrlKey = 'aiBaseUrl';
  static const String _aiModelKey = 'aiModel';
  static const String _secureAiApiKeyKey = 'secure_ai_api_key';

  late Box<ServerConfig> _serverBox;
  late Box _settingsBox;
  late Box<String> _downloadsBox;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _cachedAiApiKey;

  Future<void> init() async {
    Hive.registerAdapter(ServerConfigAdapter());
    _serverBox = await Hive.openBox<ServerConfig>(_serverBoxName);
    _settingsBox = await Hive.openBox('settings');
    _downloadsBox = await Hive.openBox<String>('downloads');
    await _migrateAiApiKeyToSecureStorage();
    _cachedAiApiKey = await _secureStorage.read(key: _secureAiApiKeyKey);
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

  Future<void> deleteAll() async {
    await _serverBox.clear();
    await _settingsBox.delete(_activeServerKey);
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

  String? getAiApiKey() {
    return _cachedAiApiKey;
  }

  Future<void> setAiApiKey(String? key) async {
    if (key == null || key.isEmpty) {
      _cachedAiApiKey = null;
      await _secureStorage.delete(key: _secureAiApiKeyKey);
      await _settingsBox.delete(_aiApiKeyKey);
    } else {
      _cachedAiApiKey = key;
      await _secureStorage.write(key: _secureAiApiKeyKey, value: key);
      await _settingsBox.delete(_aiApiKeyKey);
    }
  }

  AiProviderType getAiProvider() {
    final index = _settingsBox.get(_aiProviderKey) as int?;
    if (index == null || index < 0 || index >= AiProviderType.values.length) {
      return AiProviderType.gemini;
    }
    return AiProviderType.values[index];
  }

  Future<void> setAiProvider(AiProviderType provider) async {
    await _settingsBox.put(_aiProviderKey, provider.index);
  }

  String? getAiBaseUrl() {
    return _settingsBox.get(_aiBaseUrlKey) as String?;
  }

  Future<void> setAiBaseUrl(String? url) async {
    if (url == null || url.isEmpty) {
      await _settingsBox.delete(_aiBaseUrlKey);
    } else {
      await _settingsBox.put(_aiBaseUrlKey, url);
    }
  }

  String? getAiModel() {
    return _settingsBox.get(_aiModelKey) as String?;
  }

  Future<void> setAiModel(String? model) async {
    if (model == null || model.isEmpty) {
      await _settingsBox.delete(_aiModelKey);
    } else {
      await _settingsBox.put(_aiModelKey, model);
    }
  }

  String? getDownloadedPath(String songId) {
    return _downloadsBox.get(songId);
  }

  Future<void> saveDownloadedPath(String songId, String path) async {
    await _downloadsBox.put(songId, path);
  }

  Future<void> _migrateAiApiKeyToSecureStorage() async {
    final legacyKey = _settingsBox.get(_aiApiKeyKey) as String?;
    if (legacyKey == null || legacyKey.isEmpty) return;

    final secureKey = await _secureStorage.read(key: _secureAiApiKeyKey);
    if (secureKey == null || secureKey.isEmpty) {
      await _secureStorage.write(key: _secureAiApiKeyKey, value: legacyKey);
    }

    await _settingsBox.delete(_aiApiKeyKey);
  }
}
