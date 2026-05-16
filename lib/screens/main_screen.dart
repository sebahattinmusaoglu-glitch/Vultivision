import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/group.dart';
import '../services/storage_service.dart';
import 'player_screen.dart';
import 'groups_screen.dart';
import 'profile_screen.dart';
import 'empty_state_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final StorageService _storage = StorageService();
  List<Group> _groups = [];
  String? _defaultGroupId;
  bool _isLoading = true;
  int _currentIndex = 1;
  bool _isImmersive = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final results = await Future.wait([
      _storage.loadGroups(),
      _storage.getDefaultGroupId(),
    ]);

    if (mounted) {
      setState(() {
        _groups = results[0] as List<Group>;
        _defaultGroupId = results[1] as String?;
        _isLoading = false;
      });
    }
  }

  void _onTabChanged(int index) {
    final comingFromSettings = _currentIndex == 2 && index == 1; // Watch: 1
    setState(() {
      _currentIndex = index;
      if (index != 1) _isImmersive = false;
    });
    if (comingFromSettings) _loadGroups();
  }

  void _onImmersiveChanged(bool immersive) {
    if (_currentIndex == 1) setState(() => _isImmersive = immersive);
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
      bottomNavigationBar: AnimatedSlide(
        offset: _isImmersive ? const Offset(0, 1) : Offset.zero,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _buildBottomNav(),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Material(color: AppColors.background, child: GroupsScreen(groups: _groups, onGroupsChanged: _loadGroups, onSwitchToWatch: () => _onTabChanged(1),),),
          Material(color: Colors.black, child: PlayerScreen(groups: _groups, onGroupsChanged: _loadGroups, defaultGroupId: _defaultGroupId, onImmersiveChanged: _onImmersiveChanged, onOpenSettings: () => _onTabChanged(2),),),
          Material(color: AppColors.background, child: const ProfileScreen(),),
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
                  _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Groups', isActive: _currentIndex == 0, onTap: () => _onTabChanged(0)),
                  _NavItem(icon: Icons.tv_outlined, activeIcon: Icons.tv, label: 'Watch', isActive: _currentIndex == 1, onTap: () => _onTabChanged(1)),
                  _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', isActive: _currentIndex == 2, onTap: () => _onTabChanged(2)),
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