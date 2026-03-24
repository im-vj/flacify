import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/song.dart';
import 'navidrome_service.dart';

enum AiProviderType {
  gemini,
  anthropic,
  openai,
  litellm,
}

class AiService {
  final AiProviderType providerType;
  final String apiKey;
  final String? baseUrl; // For LiteLLM proxy
  final String? customModel;
  final NavidromeService? navidrome;
  final Dio _dio = Dio();

  static const Map<AiProviderType, AiProviderMetadata> providerMetadata = {
    AiProviderType.gemini: AiProviderMetadata(
      displayName: 'Gemini',
      vendor: 'Google',
      defaultModel: 'gemini-2.0-flash',
    ),
    AiProviderType.anthropic: AiProviderMetadata(
      displayName: 'Claude',
      vendor: 'Anthropic',
      defaultModel: 'claude-3-5-haiku-20241022',
    ),
    AiProviderType.openai: AiProviderMetadata(
      displayName: 'GPT',
      vendor: 'OpenAI',
      defaultModel: 'gpt-4o-mini',
    ),
    AiProviderType.litellm: AiProviderMetadata(
      displayName: 'LiteLLM',
      vendor: 'Proxy',
      defaultModel: 'gpt-4o-mini',
      requiresBaseUrl: true,
      supportsModelOverride: true,
    ),
  };

  AiService({
    required this.providerType,
    required this.apiKey,
    this.baseUrl,
    this.customModel,
    this.navidrome,
  });

  Future<void> testConnection() async {
    if (apiKey.trim().isEmpty) {
      throw AiServiceException(
        'API key is required.',
        AiServiceErrorType.missingApiKey,
      );
    }
    if (providerMetadata[providerType]?.requiresBaseUrl == true &&
        (baseUrl == null || baseUrl!.trim().isEmpty)) {
      throw AiServiceException(
        'Base URL is required for this provider.',
        AiServiceErrorType.apiError,
      );
    }

    try {
      final res = await _callProvider('Reply with the single word: OK');
      if (res.statusCode != 200) {
        throw AiServiceException(
          'AI API returned status ${res.statusCode}',
          AiServiceErrorType.apiError,
        );
      }
      _extractText(res);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      throw AiServiceException(
        status != null ? 'Provider returned status $status' : 'Network error: ${e.message}',
        status == 429 ? AiServiceErrorType.apiError : AiServiceErrorType.networkError,
        originalError: e,
      );
    }
  }

  String get model {
    final override = customModel?.trim();
    if (override != null && override.isNotEmpty) return override;
    return providerMetadata[providerType]!.defaultModel;
  }

  Future<List<Song>> getNextSongSuggestions(List<Song> currentQueue) async {
    if (apiKey.isEmpty) {
      throw AiServiceException(
        'AI API Key is missing. Please set it in Settings.',
        AiServiceErrorType.missingApiKey,
      );
    }
    if (currentQueue.isEmpty) {
      throw AiServiceException(
        'No songs in queue to analyze.',
        AiServiceErrorType.emptyQueue,
      );
    }

    final recentSongs = currentQueue.reversed.take(5).toList();
    final names = recentSongs.map((s) => "'${s.title}' by ${s.artist}").join(', ');

    final prompt = '''
Based on these recently played songs: $names
Suggest 5 similar songs that would flow well next in a playlist.
Return ONLY a strictly valid JSON array of objects with "title" and "artist" string keys. Do not include markdown formatting or backticks.
Example: [{"title": "Song 1", "artist": "Artist 1"}]
''';

    Response res;
    try {
      res = await _callProvider(prompt);
    } on DioException catch (e) {
      throw AiServiceException(
        'Network error: ${e.message}',
        AiServiceErrorType.networkError,
        originalError: e,
      );
    }

    final text = _extractText(res);
    final foundSongs = await _parseAndFindSongs(text);

    if (foundSongs.isEmpty) {
      throw AiServiceException(
        'AI suggested songs were not found in your library.',
        AiServiceErrorType.noMatches,
      );
    }

    return foundSongs;
  }

  Future<Response> _callProvider(String prompt) {
    final callHandlers = <AiProviderType, Future<Response> Function(String)>{
      AiProviderType.gemini: _callGemini,
      AiProviderType.anthropic: _callAnthropic,
      AiProviderType.openai: _callOpenAI,
      AiProviderType.litellm: _callLiteLLM,
    };

    final handler = callHandlers[providerType];
    if (handler == null) {
      throw AiServiceException(
        'Provider is not supported yet.',
        AiServiceErrorType.apiError,
      );
    }
    return handler(prompt);
  }

  Future<Response> _callGemini(String prompt) async {
    return _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
      data: {
        'contents': [{'parts': [{'text': prompt}]}],
        'generationConfig': {'temperature': 0.7},
      },
    );
  }

  Future<Response> _callAnthropic(String prompt) async {
    return _dio.post(
      'https://api.anthropic.com/v1/messages',
      data: {
        'model': model,
        'max_tokens': 1024,
        'messages': [{'role': 'user', 'content': prompt}],
      },
      options: Options(headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      }),
    );
  }

  Future<Response> _callOpenAI(String prompt) async {
    return _dio.post(
      'https://api.openai.com/v1/chat/completions',
      data: {
        'model': model,
        'messages': [
          {'role': 'system', 'content': 'You are a music recommendation assistant.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      },
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'content-type': 'application/json',
      }),
    );
  }

  Future<Response> _callLiteLLM(String prompt) async {
    final url = _buildLiteLlmChatCompletionsUrl();
    return _dio.post(
      url,
      data: {
        'model': model,
        'messages': [
          {'role': 'system', 'content': 'You are a music recommendation assistant.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      },
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'content-type': 'application/json',
      }),
    );
  }

  String _buildLiteLlmChatCompletionsUrl() {
    final raw = (baseUrl ?? 'http://localhost:4000').trim();
    final normalized = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;

    if (normalized.endsWith('/chat/completions')) {
      return normalized;
    }
    if (normalized.endsWith('/v1')) {
      return '$normalized/chat/completions';
    }
    return '$normalized/v1/chat/completions';
  }

  String _extractText(Response res) {
    if (res.statusCode != 200) {
      throw AiServiceException(
        'AI API returned status ${res.statusCode}',
        AiServiceErrorType.apiError,
      );
    }

    try {
      final extractors = <AiProviderType, String Function(dynamic)>{
        AiProviderType.gemini: _extractGeminiText,
        AiProviderType.anthropic: _extractAnthropicText,
        AiProviderType.openai: _extractChatCompletionText,
        AiProviderType.litellm: _extractChatCompletionText,
      };
      final extractor = extractors[providerType];
      if (extractor == null) {
        throw AiServiceException(
          'Invalid provider response parser.',
          AiServiceErrorType.invalidResponse,
        );
      }
      final text = extractor(res.data);

      if (text.isEmpty) {
        throw AiServiceException('AI returned empty text', AiServiceErrorType.emptyResponse);
      }

      // Clean markdown formatting
      var cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      } else if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }

      return cleanText.trim();
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException(
        'Invalid AI response structure',
        AiServiceErrorType.invalidResponse,
        originalError: e,
      );
    }
  }

  String _extractGeminiText(dynamic data) {
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw AiServiceException('AI response was empty', AiServiceErrorType.emptyResponse);
    }
    final parts = candidates[0]['content']?['parts'] as List?;
    return parts?.firstOrNull?['text'] as String? ?? '';
  }

  String _extractAnthropicText(dynamic data) {
    return data['content']?[0]?['text'] as String? ?? '';
  }

  String _extractChatCompletionText(dynamic data) {
    return data['choices']?[0]?['message']?['content'] as String? ?? '';
  }

  Future<List<Song>> _parseAndFindSongs(String text) async {
    final currentNavidrome = navidrome;
    if (currentNavidrome == null) {
      throw AiServiceException(
        'Music library service unavailable.',
        AiServiceErrorType.unknown,
      );
    }
    try {
      final List<dynamic> jsonList = jsonDecode(text);
      final List<Song> foundSongs = [];

      for (var item in jsonList) {
        if (item is! Map) continue;
        final title = item['title'] as String?;
        final artist = item['artist'] as String?;
        if (title != null && artist != null) {
          try {
            // First try strict exact match
            var searchResult = await currentNavidrome.search('$title $artist');
            
            // Fallback 1: Just the title
            if (searchResult.isEmpty) {
              searchResult = await currentNavidrome.search(title);
            }
            
            // Fallback 2: Just the artist (to at least get the same vibe)
            if (searchResult.isEmpty) {
              searchResult = await currentNavidrome.search(artist);
              if (searchResult.isNotEmpty) {
                 searchResult.shuffle(); // Pick a random song from them
              }
            }

            if (searchResult.isNotEmpty) {
              // Avoid duplicates
              if (!foundSongs.any((s) => s.id == searchResult.first.id)) {
                foundSongs.add(searchResult.first);
              }
            }
          } catch (_) {
            continue;
          }
        }
      }
      return foundSongs;
    } on FormatException catch (e) {
      throw AiServiceException(
        'Invalid JSON from AI: ${e.message}',
        AiServiceErrorType.parseError,
        originalError: e,
      );
    }
  }
}

enum AiServiceErrorType {
  missingApiKey,
  emptyQueue,
  networkError,
  apiError,
  emptyResponse,
  invalidResponse,
  parseError,
  noMatches,
  unknown,
}

class AiServiceException implements Exception {
  final String message;
  final AiServiceErrorType type;
  final Object? originalError;

  AiServiceException(this.message, this.type, {this.originalError});

  @override
  String toString() => message;
}

class AiProviderMetadata {
  final String displayName;
  final String vendor;
  final String defaultModel;
  final bool requiresBaseUrl;
  final bool supportsModelOverride;

  const AiProviderMetadata({
    required this.displayName,
    required this.vendor,
    required this.defaultModel,
    this.requiresBaseUrl = false,
    this.supportsModelOverride = false,
  });
}
