import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import 'navidrome_provider.dart';

final aiServiceProvider = Provider<AiService?>((ref) {
  final storage = ref.watch(storageProvider);
  final navidrome = ref.watch(navidromeServiceProvider);
  final apiKey = storage.getAiApiKey();

  if (apiKey == null || apiKey.isEmpty || navidrome == null) return null;

  return AiService(
    providerType: storage.getAiProvider(),
    apiKey: apiKey,
    baseUrl: storage.getAiBaseUrl(),
    customModel: storage.getAiModel(),
    navidrome: navidrome,
  );
});
