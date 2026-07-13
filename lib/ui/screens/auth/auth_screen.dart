import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/glassmorphic_container.dart';
import '../../../core/constants/api_constants.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _appIdController = TextEditingController(text: ApiConstants.defaultAppId);
  final _appSecretController = TextEditingController(text: ApiConstants.defaultAppSecret);
  final _tokenController = TextEditingController();

  bool _isLoading = false;
  bool _obscureSecret = true;
  bool _obscureToken = true;
  String? _errorMessage;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _appIdController.dispose();
    _appSecretController.dispose();
    _tokenController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_appIdController.text.isEmpty ||
        _appSecretController.text.isEmpty ||
        _tokenController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authProvider.notifier)
        .login(
          _appIdController.text.trim(),
          _appSecretController.text.trim(),
          _tokenController.text.trim(),
        );

    if (!success && mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            ref.read(authProvider).error ?? 'Login failed. Check credentials.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient back-glow
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.12 : 0.06,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [cs.primary, cs.secondary, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? 'assets/images/ganne_logo_dark.png'
                            : 'assets/images/ganne_logo_light.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),

                    GlassmorphicContainer(
                      borderRadius: 24,
                      blur: 20,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'API Credentials',
                            style: tt.titleSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _appIdController,
                            decoration: InputDecoration(
                              labelText: 'App ID',
                              prefixIcon: Icon(
                                Icons.key_outlined,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _appSecretController,
                            obscureText: _obscureSecret,
                            decoration: InputDecoration(
                              labelText: 'App Secret',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: cs.onSurfaceVariant,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureSecret
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: cs.onSurfaceVariant,
                                ),
                                onPressed: () => setState(
                                  () => _obscureSecret = !_obscureSecret,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _tokenController,
                            obscureText: _obscureToken,
                            decoration: InputDecoration(
                              labelText: 'User Auth Token',
                              prefixIcon: Icon(
                                Icons.token_outlined,
                                color: cs.onSurfaceVariant,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureToken
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: cs.onSurfaceVariant,
                                ),
                                onPressed: () => setState(
                                  () => _obscureToken = !_obscureToken,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: cs.onErrorContainer,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          FilledButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: cs.onPrimary,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
