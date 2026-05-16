import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    // Profile(2) → Groups(0) veya Watch(1) geçişinde reload
    final comingFromProfile = _currentIndex == 2 && index != 2;
    setState(() {
      _currentIndex = index;
      // Watch(1) dışına geçince immersive sıfırla
      if (index != 1) _isImmersive = false;
    });
    if (comingFromProfile) _loadGroups();
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
      bottomNavigationBar: _buildBottomNav(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Material(
            color: AppColors.background,
            child: GroupsScreen(
              groups: _groups,
              onGroupsChanged: _loadGroups,
              onSwitchToWatch: () => _onTabChanged(1),
            ),
          ),
          Material(
            color: Colors.black,
            child: PlayerScreen(
              groups: _groups,
              onGroupsChanged: _loadGroups,
              defaultGroupId: _defaultGroupId,
              onImmersiveChanged: _onImmersiveChanged,
              onOpenSettings: () => _onTabChanged(2),
            ),
          ),
          Material(
            color: AppColors.background,
            child: const ProfileScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isImmersive ? 0 : null,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: Material(
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
              height: 68,
              child: Row(
                children: [
                  _NavItem(
                    svgAsset: 'assets/icons/groups_icon.svg',
                    label: 'Groups',
                    isActive: _currentIndex == 0,
                    onTap: () => _onTabChanged(0),
                  ),
                  _NavItem(
                    svgAsset: 'assets/icons/watch_icon.svg',
                    label: 'Watch',
                    isActive: _currentIndex == 1,
                    onTap: () => _onTabChanged(1),
                  ),
                  _NavItem(
                    svgAsset: 'assets/icons/profile_icon.svg',
                    label: 'Profile',
                    isActive: _currentIndex == 2,
                    onTap: () => _onTabChanged(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String? svgAsset;   // SVG ikonlu sekmeler için
  final IconData? icon;     // Material ikonlu sekmeler için (Profile)
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    this.svgAsset,
    this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  }) : assert(svgAsset != null || icon != null);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textTertiary;

    Widget iconWidget;
    if (svgAsset != null) {
      iconWidget = SvgPicture.asset(
        svgAsset!,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    } else {
      iconWidget = Icon(icon, color: color, size: 24);
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
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