import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../models/group.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'profile_screen.dart';

// SharedPreferences key — StorageService ile tutarlı olsun diye burada sabit
const _kDefaultGroupKey = 'default_group_id';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _storage = StorageService();

  List<Group> _groups = [];
  String? _defaultGroupId;
  bool _excludeShorts = false;
  bool _checkingScope = false;
  bool? _youtubeGranted;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groups = await _storage.loadGroups();
    final prefs = await SharedPreferences.getInstance();
    final defaultId = prefs.getString(_kDefaultGroupKey);
    final youtubeGranted = await _authService.hasYouTubeScope();
    final excludeShorts = await _storage.getExcludeShorts();
    if (mounted) {
      setState(() {
        _groups = groups;
        _defaultGroupId = defaultId;
        _youtubeGranted = youtubeGranted;
        _excludeShorts = excludeShorts;
      });
    }
  }

  // ─── Varsayılan grup ────────────────────────────────────────────────

  Group? get _defaultGroup {
    if (_defaultGroupId == null) return null;
    try {
      return _groups.firstWhere((g) => g.id == _defaultGroupId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDefaultGroup() async {
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a group first.'),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    

    final picked = await showModalBottomSheet<Group>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GroupPickerSheet(
        groups: _groups,
        selectedId: _defaultGroupId,
      ),
    );

    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDefaultGroupKey, picked.id);
      if (mounted) setState(() => _defaultGroupId = picked.id);
    }
  }

  


  // ─── Auth ───────────────────────────────────────────────────────────

  Future<void> _handleSignIn() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      final granted = await _authService.hasYouTubeScope();
      if (mounted) setState(() => _youtubeGranted = granted);
    }
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

  // ─── Build ──────────────────────────────────────────────────────────

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
              // Başlık
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

              // ── Hesap ──────────────────────────────────────────────
              const _SectionHeader(label: 'Account'),
              const SizedBox(height: 12),
              if (user == null)
                _SignInCard(onSignIn: _handleSignIn)
              else ...[
                _AccountCard(user: user, onSignOut: _handleSignOut),
                const SizedBox(height: 10),
                _YouTubeScopeCard(
                  granted: _youtubeGranted,
                  loading: _checkingScope,
                  onRequest: _handleRequestScope,
                ),
              ],

              const SizedBox(height: 28),

// ── Varsayılan grup ────────────────────────────────────
              const _SectionHeader(label: 'Default Group'),
              const SizedBox(height: 12),
              _DefaultGroupCard(
                group: _defaultGroup,
                hasGroups: _groups.isNotEmpty,
                onTap: _pickDefaultGroup,
              ),

              const SizedBox(height: 24),

              // ── Video tercihleri ───────────────────────────────────
              const _SectionHeader(label: 'Video Preferences'),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _excludeShorts,
                onChanged: (val) async {
                  setState(() => _excludeShorts = val);
                  await _storage.saveExcludeShorts(val);
                },
                title: const Text(
                  'Exclude Shorts',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Hide videos shorter than 60 seconds',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 28),

              // ── Hakkında ───────────────────────────────────────────
              const _SectionHeader(label: 'About'),
              const SizedBox(height: 12),
              const _InfoRow(label: 'App', value: 'Vultivision'),
              const _InfoRow(label: 'Version', value: '1.0.0'),
              const _InfoRow(label: 'Developer', value: 'ZennApp Studio'),
            ],
          );
        },
      ),
    );
  }
}

// ─── Default group kartı ─────────────────────────────────────────────────────

class _DefaultGroupCard extends StatelessWidget {
  final Group? group;
  final bool hasGroups;
  final VoidCallback onTap;

  const _DefaultGroupCard({
    required this.group,
    required this.hasGroups,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            Icons.grid_view_outlined,
            color: group != null ? AppColors.primary : Colors.white38,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group?.name ?? 'None selected',
                  style: TextStyle(
                    color: group != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: group != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                if (!hasGroups)
                  const Text(
                    'Create a group first',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}

// ─── Grup seçici sheet ───────────────────────────────────────────────────────

class _GroupPickerSheet extends StatelessWidget {
  final List<Group> groups;
  final String? selectedId;

  const _GroupPickerSheet({
    required this.groups,
    required this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutaç
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Default Group',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'This group opens when you launch Watch',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...groups.map((group) {
            final isSelected = group.id == selectedId;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                group.name,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '${group.channels.length} channel${group.channels.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 22)
                  : const Icon(Icons.radio_button_unchecked,
                      color: Colors.white24, size: 22),
              onTap: () => Navigator.pop(context, group),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Hesap kartları ──────────────────────────────────────────────────────────

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
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? const Icon(Icons.person,
                    color: AppColors.primary, size: 20)
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
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout,
                color: Colors.white38, size: 20),
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
              color: isGranted ? Colors.green : Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isGranted
                  ? Icons.check_circle
                  : Icons.youtube_searched_for,
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
                      : 'Required to import subscriptions',
                  style: TextStyle(
                    color: isGranted
                        ? Colors.green.shade300
                        : Colors.white38,
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

// ─── Yardımcı widget'lar ─────────────────────────────────────────────────────

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
  final VoidCallback? onTap;
  const _Card({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: child,
      ),
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
              style: const TextStyle(
                  color: Colors.white54, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}