import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Settings — coming soon',
          style: TextStyle(color: AppColors.primary),
        ),
      ),
    );
  }
}