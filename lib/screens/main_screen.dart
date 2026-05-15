import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/group.dart';
import '../services/storage_service.dart';
import 'player_screen.dart';
import 'groups_screen.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final StorageService _storage = StorageService();
  List<Group> _groups = [];
  bool _isLoading = true;
  int _currentIndex = 1; // Groups tab varsayılan
  String? _defaultGroupId;
  

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groups = await _storage.loadGroups();
    final prefs = await SharedPreferences.getInstance();
    final defaultId = prefs.getString('default_group_id');
    if (mounted) {
      setState(() {
        _groups = groups;
        _defaultGroupId = defaultId;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Grup yoksa Watch tab'ına erişim kapalı
    final canWatch = _groups.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildBottomNav(canWatch),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Watch
          Material(
            color: Colors.black,
            child: canWatch
                ? PlayerScreen(
                    groups: _groups,
                    onGroupsChanged: _loadGroups,
                    defaultGroupId: _defaultGroupId,
                  )
                : const SizedBox.shrink(),
          ),
          // Groups
          Material(
            color: AppColors.background,
            child: GroupsScreen(
              groups: _groups,
              onGroupsChanged: _loadGroups,
              onSwitchToWatch: () => setState(() => _currentIndex = 0),
            ),
          ),
          // Settings
          Material(
            color: AppColors.background,
            child: const SettingsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool canWatch) {
    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.tv_outlined,
                  activeIcon: Icons.tv,
                  label: 'Watch',
                  isActive: _currentIndex == 0,
                  // Grup yoksa Watch'a geçiş engeli yok ama içerik boş;
                  // daha iyi UX: Groups tab'ına yönlendir
                  onTap: () {
                    if (canWatch) {
                      _loadGroups(); // her geçişte default group'u tazele
                      setState(() => _currentIndex = 0);
                    } else {
                      setState(() => _currentIndex = 1);
                    }
                  },
                ),
                _NavItem(
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view,
                  label: 'Groups',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Settings',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textTertiary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}