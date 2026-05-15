import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/group.dart';
import '../services/storage_service.dart';
import 'player_screen.dart';
import 'groups_screen.dart';
import 'settings_screen.dart';
import 'empty_state_screen.dart';



class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final StorageService _storage = StorageService();
  List<Group> _groups = [];
  bool _isLoading = true;
  int _currentIndex = 0; // 0 = Groups, 1 = Settings

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groups = await _storage.loadGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    }
  }

  void _openPlayer() async {
    final defaultGroupId = await _storage.getDefaultGroupId();
    Group? defaultGroup;
    if (defaultGroupId != null) {
      try {
        defaultGroup = _groups.firstWhere((g) => g.id == defaultGroupId);
      } catch (_) {
        // Silinmiş bir grup kaydedilmişse ignore
      }
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PlayerScreen(
          groups: _groups,
          initialGroup: defaultGroup,
          onGroupsChanged: _loadGroups,
        ),
      ),
    );
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

    if (_groups.isEmpty) {
      return EmptyStateScreen(onGroupCreated: _loadGroups);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildBottomNav(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Material(
            color: AppColors.background,
            child: GroupsScreen(
              groups: _groups,
              onGroupsChanged: _loadGroups,
            ),
          ),
          Material(
            color: AppColors.background,
            child: const SettingsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.12),
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
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view,
                  label: 'Groups',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.tv_outlined,
                  activeIcon: Icons.tv,
                  label: 'Watch',
                  isActive: false, // Watch her zaman route olarak açılır
                  onTap: _openPlayer,
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Settings',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
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
              color: isActive ? AppColors.primary : Colors.white54,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : Colors.white54,
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