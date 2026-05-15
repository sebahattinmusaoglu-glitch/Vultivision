import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();

  bool _checkingScope = false;
  bool? _youtubeGranted; // null = henüz kontrol edilmedi

  @override
  void initState() {
    super.initState();
    _checkYouTubeScope();
  }

  Future<void> _checkYouTubeScope() async {
    final granted = await _authService.hasYouTubeScope();
    if (mounted) setState(() => _youtubeGranted = granted);
  }

  Future<void> _handleSignIn() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) await _checkYouTubeScope();
  }

  Future<void> _handleSignOut() async {
    await _authService.signOut();
    if (mounted) setState(() => _youtubeGranted = null);
  }

  Future<void> _handleRequestScope() async {
    setState(() => _checkingScope = true);
    final granted = await _authService.requestYouTubeScope();
    if (mounted) {
      setState(() {
        _youtubeGranted = granted;
        _checkingScope = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          final user = snapshot.data;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // ── Başlık ────────────────────────────────────────────────
              const Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 28),

              // ── Hesap bölümü ──────────────────────────────────────────
              _SectionHeader(label: 'Account'),
              const SizedBox(height: 12),

              if (user == null) ...[
                _SignInCard(onSignIn: _handleSignIn),
              ] else ...[
                _AccountCard(user: user, onSignOut: _handleSignOut),
                const SizedBox(height: 12),
                _YouTubeScopeCard(
                  granted: _youtubeGranted,
                  loading: _checkingScope,
                  onRequest: _handleRequestScope,
                ),
              ],

              const SizedBox(height: 32),

              // ── Varsayılan grup bölümü ────────────────────────────────
              _SectionHeader(label: 'Default Group'),
              const SizedBox(height: 12),
              _DefaultGroupCard(),

              const SizedBox(height: 32),

              // ── Uygulama bilgisi ──────────────────────────────────────
              _SectionHeader(label: 'About'),
              const SizedBox(height: 12),
              _InfoRow(label: 'App', value: 'Vultivision'),
              _InfoRow(label: 'Version', value: '1.0.0'),
              _InfoRow(label: 'Developer', value: 'ZennApp Studio'),
            ],
          );
        },
      ),
    );
  }
}

// ─── Hesap kartları ─────────────────────────────────────────────────────────

class _SignInCard extends StatelessWidget {
  final VoidCallback onSignIn;

  const _SignInCard({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          const Icon(Icons.account_circle_outlined,
              color: AppColors.primary, size: 32),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Not signed in',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('Sign in to sync your groups',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: onSignIn,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final User user;
  final VoidCallback onSignOut;

  const _AccountCard({required this.user, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? const Icon(Icons.person, color: AppColors.primary, size: 20)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Google User',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout, color: Colors.white38, size: 20),
            tooltip: 'Sign out',
          ),
        ],
      ),
    );
  }
}

class _YouTubeScopeCard extends StatelessWidget {
  final bool? granted;
  final bool loading;
  final VoidCallback onRequest;

  const _YouTubeScopeCard({
    required this.granted,
    required this.loading,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final isGranted = granted == true;

    return _Card(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isGranted ? Colors.green : Colors.white12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isGranted ? Icons.check_circle : Icons.youtube_searched_for,
              color: isGranted ? Colors.white : Colors.white54,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YouTube Access',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  isGranted
                      ? 'Subscriptions enabled'
                      : 'Required to load your channels',
                  style: TextStyle(
                    color: isGranted ? Colors.green.shade300 : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!isGranted)
            loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : TextButton(
                    onPressed: onRequest,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                    child: const Text('Allow'),
                  ),
        ],
      ),
    );
  }
}

// ─── Varsayılan grup kartı ──────────────────────────────────────────────────

class _DefaultGroupCard extends StatelessWidget {
  const _DefaultGroupCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          const Icon(Icons.group_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'None selected',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}

// ─── Yardımcı widget'lar ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}