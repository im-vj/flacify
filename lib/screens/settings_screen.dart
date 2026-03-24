import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/navidrome_provider.dart';
import '../services/ai_service.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  bool _obscureApiKey = true;
  bool _isTestingConnection = false;
  AiProviderType _selectedProvider = AiProviderType.gemini;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final storage = ref.read(storageProvider);
    _selectedProvider = storage.getAiProvider();
    _apiKeyController.text = storage.getAiApiKey() ?? '';
    _baseUrlController.text = storage.getAiBaseUrl() ?? '';
    _modelController.text = storage.getAiModel() ?? '';
  }

  Future<void> _testAndSaveAiConfig() async {
    if (_isTestingConnection) return;

    final storage = ref.read(storageProvider);
    final navidrome = ref.read(navidromeServiceProvider);
    final meta = AiService.providerMetadata[_selectedProvider]!;

    final apiKey = _apiKeyController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    final model = _modelController.text.trim();

    if (apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key is required'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    if (meta.requiresBaseUrl && baseUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Base URL is required'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() => _isTestingConnection = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          color: Color(0xFF1A1A2E),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF00F0FF)),
                SizedBox(height: 16),
                Text('Testing connection...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final aiService = AiService(
        providerType: _selectedProvider,
        apiKey: apiKey,
        baseUrl: baseUrl.isEmpty ? null : baseUrl,
        customModel: model.isEmpty ? null : model,
        navidrome: navidrome,
      );
      await aiService.testConnection();

      await storage.setAiProvider(_selectedProvider);
      await storage.setAiApiKey(apiKey);
      await storage.setAiBaseUrl(baseUrl.isEmpty ? null : baseUrl);
      await storage.setAiModel(model.isEmpty ? null : model);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection successful. Settings saved.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildAudioSection(),
                const SizedBox(height: 24),
                _buildAISection(),
                const SizedBox(height: 24),
                _buildAboutSection(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A0A0F),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A1A2E).withValues(alpha: 0.8),
                const Color(0xFF0A0A0F),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.cloud_done,
              label: 'Connected',
              color: Colors.green,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.smart_toy,
              label: 'AI Ready',
              color: const Color(0xFF00F0FF),
              onTap: () => _scrollToSection('ai'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1);
  }

  Widget _buildAudioSection() {
    final currentBitrate = ref.watch(bitrateProvider);
    final storage = ref.read(storageProvider);

    void setBitrate(int? bitrate) async {
      await storage.setMaxBitrate(bitrate);
      ref.read(bitrateProvider.notifier).state = bitrate;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.high_quality,
          title: 'Audio Quality',
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Column(
              children: [
                _AudioOption(
                  title: 'FLAC / Original',
                  subtitle: 'Lossless quality',
                  icon: Icons.audiotrack,
                  isSelected: currentBitrate == null,
                  onTap: () => setBitrate(null),
                ),
                _Divider(),
                _AudioOption(
                  title: '320 kbps',
                  subtitle: 'High quality MP3',
                  icon: Icons.music_note,
                  isSelected: currentBitrate == 320,
                  onTap: () => setBitrate(320),
                ),
                _Divider(),
                _AudioOption(
                  title: '128 kbps',
                  subtitle: 'Data saver',
                  icon: Icons.data_usage,
                  isSelected: currentBitrate == 128,
                  onTap: () => setBitrate(128),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildAISection() {
    final selectedMeta = AiService.providerMetadata[_selectedProvider];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.smart_toy,
          title: 'AI Provider',
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AiProviderType.values.indexed.expand((entry) {
                    final index = entry.$1;
                    final providerType = entry.$2;
                    final meta = AiService.providerMetadata[providerType]!;
                    final ui = _providerUiConfig[providerType] ?? _fallbackProviderUi;

                    final card = _ProviderCard(
                      name: meta.displayName,
                      subtitle: meta.vendor,
                      icon: ui.icon,
                      color: ui.color,
                      isSelected: _selectedProvider == providerType,
                      onTap: () => setState(() => _selectedProvider = providerType),
                    );

                    if (index == AiProviderType.values.length - 1) {
                      return [card];
                    }
                    return [card, const SizedBox(width: 12)];
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _ApiKeyInput(
                controller: _apiKeyController,
                obscure: _obscureApiKey,
                onToggleObscure: () => setState(() => _obscureApiKey = !_obscureApiKey),
                showBaseUrl: selectedMeta?.requiresBaseUrl ?? false,
                baseUrlController: _baseUrlController,
                showModel: selectedMeta?.supportsModelOverride ?? false,
                modelController: _modelController,
                modelHintText: selectedMeta?.defaultModel ?? 'gpt-4o-mini',
                onTestConnection: _testAndSaveAiConfig,
                isTestingConnection: _isTestingConnection,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildAboutSection() {
    final storage = ref.watch(storageProvider);
    final server = storage.getActiveServer();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(icon: Icons.info_outline, title: 'About'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.dns,
                  iconColor: const Color(0xFF00F0FF),
                  title: 'Server',
                  value: server?.name ?? 'Not connected',
                  subtitle: server?.url ?? '',
                ),
                _Divider(),
                _ActionTile(
                  icon: Icons.swap_horiz,
                  title: 'Switch Server',
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                _Divider(),
                const _InfoTile(
                  icon: Icons.music_note,
                  iconColor: Colors.orange,
                  title: 'Flacify',
                  value: 'v1.0.0',
                  subtitle: 'Self-hosted music streaming',
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  void _scrollToSection(String id) {
    // Simple scroll to section - in production you'd use Scrollable
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00F0FF), size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AudioOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00F0FF).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFF00F0FF) : Colors.white54,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00F0FF) : Colors.white38,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00F0FF),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 85,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0x14FFFFFF),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyInput extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool showBaseUrl;
  final TextEditingController baseUrlController;
  final bool showModel;
  final TextEditingController modelController;
  final String modelHintText;
  final Future<void> Function() onTestConnection;
  final bool isTestingConnection;

  const _ApiKeyInput({
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.showBaseUrl,
    required this.baseUrlController,
    required this.showModel,
    required this.modelController,
    required this.modelHintText,
    required this.onTestConnection,
    required this.isTestingConnection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API Key',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your API key',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white54,
                ),
                onPressed: onToggleObscure,
              ),
            ),
          ),
          if (showBaseUrl) ...[
            const SizedBox(height: 12),
            const Text(
              'Base URL',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: baseUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'http://localhost:4000',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
          if (showModel) ...[
            const SizedBox(height: 12),
            const Text(
              'Model Name',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: modelController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: modelHintText,
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _TestConnectionButton(
            onTap: onTestConnection,
            isEnabled: !isTestingConnection,
          ),
        ],
      ),
    );
  }
}

class _TestConnectionButton extends StatelessWidget {
  final Future<void> Function() onTap;
  final bool isEnabled;

  const _TestConnectionButton({
    required this.onTap,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isEnabled
              ? const Color(0xFF00F0FF)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow,
              color: isEnabled ? Colors.black : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isEnabled ? 'Test Connection & Save' : 'Testing...',
              style: TextStyle(
                color: isEnabled ? Colors.black : Colors.white38,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white54, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 74,
      color: Color(0x14FFFFFF),
    );
  }
}

const _fallbackProviderUi = _ProviderUiConfig(
  icon: Icons.smart_toy,
  color: Color(0xFF00F0FF),
);

const Map<AiProviderType, _ProviderUiConfig> _providerUiConfig = {
  AiProviderType.gemini: _ProviderUiConfig(
    icon: Icons.psychology,
    color: Color(0xFF4285F4),
  ),
  AiProviderType.anthropic: _ProviderUiConfig(
    icon: Icons.bolt,
    color: Color(0xFFFF6B35),
  ),
  AiProviderType.openai: _ProviderUiConfig(
    icon: Icons.auto_awesome,
    color: Color(0xFF10A37F),
  ),
  AiProviderType.litellm: _ProviderUiConfig(
    icon: Icons.cloud,
    color: Color(0xFF9B59B6),
  ),
};

class _ProviderUiConfig {
  final IconData icon;
  final Color color;

  const _ProviderUiConfig({
    required this.icon,
    required this.color,
  });
}
