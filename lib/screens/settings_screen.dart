import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_colors.dart';
import '../models/group.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _appVersion = '1.0.0';

  final _storage = StorageService();
  final _auth = AuthService();
  final _sync = SyncService();

  List<Group> _groups = [];
  String? _defaultGroupId;
  User? _currentUser;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _auth.authStateChanges.listen((user) {
      if (mounted) setState(() => _currentUser = user);
    });
  }

  Future<void> _loadData() async {
    final groups = await _storage.loadGroups();
    final defaultId = await _storage.getDefaultGroupId();
    if (mounted) {
      setState(() {
        _groups = groups;
        _defaultGroupId = defaultId;
        _currentUser = _auth.currentUser;
      });
    }
  }

  String get _defaultGroupName {
    if (_defaultGroupId == null) return 'First group';
    try {
      return _groups.firstWhere((g) => g.id == _defaultGroupId).name;
    } catch (_) {
      return 'First group';
    }
  }

  Future<void> _handleSync() async {
    if (_currentUser == null) {
      // Giriş yap
      setState(() => _isSyncing = true);
      final user = await _auth.signInWithGoogle();
      if (!mounted) return;

      if (user == null) {
        setState(() => _isSyncing = false);
        _showSnackBar('Sign-in cancelled');
        return;
      }

      // Giriş başarılı → cloud'da veri var mı kontrol et
      final downloaded = await _sync.downloadFromCloud();
      if (!mounted) return;

      if (downloaded) {
        await _loadData();
        _showSnackBar('Data restored from cloud ☁️');
      } else {
        // İlk kez giriş → lokali yükle
        await _sync.uploadToCloud();
        _showSnackBar('Groups backed up to cloud ✓');
      }
      setState(() => _isSyncing = false);
    } else {
      // Zaten giriş yapılmış → seçenek sun
      _showSyncOptions();
    }
  }

  void _showSyncOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _currentUser!.displayName ?? 'Account',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _currentUser!.email ?? '',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            _SheetButton(
              icon: Icons.upload_rounded,
              label: 'Upload to cloud',
              subtitle: 'Overwrite cloud with local data',
              onTap: () async {
                Navigator.pop(context);
                setState(() => _isSyncing = true);
                final ok = await _sync.uploadToCloud();
                if (mounted) {
                  setState(() => _isSyncing = false);
                  _showSnackBar(ok ? 'Uploaded ✓' : 'Upload failed');
                }
              },
            ),
            const SizedBox(height: 8),
            _SheetButton(
              icon: Icons.download_rounded,
              label: 'Download from cloud',
              subtitle: 'Overwrite local data with cloud',
              onTap: () async {
                Navigator.pop(context);
                setState(() => _isSyncing = true);
                final ok = await _sync.downloadFromCloud();
                if (mounted) {
                  if (ok) await _loadData();
                  setState(() => _isSyncing = false);
                  _showSnackBar(ok ? 'Downloaded ✓' : 'No cloud data found');
                }
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _auth.signOut();
                if (mounted) _showSnackBar('Signed out');
              },
              child: const Text(
                'Sign out',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Default Group',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._groups.map((group) => ListTile(
              title: Text(
                group.name,
                style: TextStyle(
                  color: group.id == _defaultGroupId
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '${group.channels.length} channel${group.channels.length != 1 ? 's' : ''}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: group.id == _defaultGroupId
                  ? const Icon(Icons.circle, color: AppColors.primary, size: 10)
                  : null,
              onTap: () async {
                await _storage.setDefaultGroupId(group.id);
                if (mounted) {
                  setState(() => _defaultGroupId = group.id);
                  Navigator.pop(context);
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String get _syncSubtitle {
    if (_isSyncing) return 'Syncing...';
    if (_currentUser != null) return _currentUser!.email ?? 'Signed in';
    return 'Back up your groups across devices';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),

          _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: _currentUser != null
                ? Icons.cloud_done_outlined
                : Icons.sync_rounded,
            title: 'Sync with Google',
            subtitle: _syncSubtitle,
            isLoading: _isSyncing,
            onTap: _isSyncing ? null : _handleSync,
          ),
          const SizedBox(height: 8),

          _SectionHeader(title: 'App'),
          _SettingsTile(
            icon: Icons.play_circle_outline,
            title: 'Default group',
            subtitle: _defaultGroupName,
            onTap: _groups.isEmpty ? null : _showGroupPicker,
          ),
          const SizedBox(height: 8),

          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: 'Privacy Policy',
            onTap: () => _showSnackBar('Coming soon'),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _showSnackBar('Coming soon'),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: _appVersion,
            showChevron: false,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Bileşenler ──

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool isLoading;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.showChevron = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.white.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else if (showChevron && onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}