import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/group.dart';

class GroupSelectionSheet extends StatelessWidget {
  final List<Group> groups;
  final Group currentGroup;

  const GroupSelectionSheet({
    super.key,
    required this.groups,
    required this.currentGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'My Groups',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final group = groups[index];
              final isActive = group.id == currentGroup.id;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                title: Text(
                  group.name,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${group.channels.length} channel${group.channels.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                trailing: isActive
                    ? const Icon(Icons.circle,
                        color: AppColors.primary, size: 10)
                    : null,
                onTap: () => Navigator.of(context).pop(group),
              );
            },
          ),
        ],
      ),
    );
  }
}