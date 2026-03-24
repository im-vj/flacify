import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server_config.dart';
import '../providers/navidrome_provider.dart';
import '../services/navidrome_service.dart';
import 'home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _urlController.text = 'https://';
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = _normalizeUrl(_urlController.text.trim());
      final user = _userController.text.trim();
      final pass = _passController.text.trim();

      // Test Connection
      final testService = NavidromeService(baseUrl: url, username: user, password: pass);
      await testService.ping(); // Assuming ping() exists or getAlbums() works for testing

      // Save to Hive
      final storage = ref.read(storageProvider);
      final newServer = ServerConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: Uri.parse(url).host,
        url: url,
        username: user,
        password: pass,
      );
      await storage.saveServer(newServer);

      // Force UI to reload correctly by invalidating all related providers
      // First invalidate the active server provider to trigger rebuild
      ref.invalidate(activeServerProvider);
      ref.invalidate(navidromeServiceProvider);

      // Use the new force refresh mechanism
      invalidateAllCaches(ref);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final msg = e.toString();
          if (msg.contains('SocketException') || msg.contains('Failed host lookup') || msg.contains('connection errored')) {
            _error = 'You appear to be offline or the server is unreachable.';
          } else if (msg.contains('timeout')) {
            _error = 'Connection timed out. Please try again.';
          } else if (msg.contains('Unauthenticated') || msg.contains('401') || msg.contains('wrong username or password')) {
            _error = 'Incorrect username or password.';
          } else {
            // If we wrapped it in NavidromeException it will print nicely
            _error = msg.replaceAll('Exception:', '').trim();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0B13), Color(0xFF05050A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141425),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 30,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 4),
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.dns_rounded, size: 38, color: Color(0xFF00F0FF)),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Center(
                          child: Text(
                            'Connect your Navidrome',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'Securely sign in to start streaming your library',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        TextFormField(
                          controller: _urlController,
                          decoration: _inputDecoration(
                            label: 'Server URL',
                            hint: 'https://navidrome.example.com',
                            prefixIcon: Icons.link_rounded,
                          ),
                          keyboardType: TextInputType.url,
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty || value == 'https://') return 'URL is required';
                            final normalized = _normalizeUrl(value);
                            final uri = Uri.tryParse(normalized);
                            if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                              return 'Enter a valid URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _userController,
                          decoration: _inputDecoration(
                            label: 'Username',
                            hint: 'Your username',
                            prefixIcon: Icons.person_rounded,
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Username is required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passController,
                          decoration: _inputDecoration(
                            label: 'Password',
                            hint: 'Your password',
                            prefixIcon: Icons.lock_rounded,
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _isLoading ? null : _login,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF00F0FF),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Text(
                                  'Connect',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      prefixIcon: Icon(prefixIcon, color: Colors.white54),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
