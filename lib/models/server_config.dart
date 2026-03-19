import 'package:hive/hive.dart';

part 'server_config.g.dart';

@HiveType(typeId: 0)
class ServerConfig extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String url;

  @HiveField(3)
  String username;

  @HiveField(4)
  String password;

  @HiveField(5)
  String type; // e.g., 'navidrome', 'subsonic'

  ServerConfig({
    required this.id,
    required this.name,
    required this.url,
    required this.username,
    required this.password,
    this.type = 'navidrome',
  });
}
