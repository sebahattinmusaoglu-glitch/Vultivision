import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/group.dart';
import 'group_detail_screen.dart';
import 'new_group_screen.dart';

class GroupsScreen extends StatelessWidget {
  final List<Group> groups;
  final VoidCallback onGroupsChanged;

  const GroupsScreen({
    super.key,
    required this.groups,
    required this.onGroupsChanged,
  });

@override
Widget build(BuildContext context) {
  return SafeArea(
    child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Groups',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NewGroupScreen(),
                        ),
                      );
                      onGroupsChanged();
                    },
                    icon: const Icon(
                      Icons.add,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Grup listesi
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const Divider(
                  indent: 24,
                  endIndent: 24,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    title: Text(
                      group.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${group.channels.length} channel${group.channels.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(
                            group: group,
                            onGroupChanged: onGroupsChanged,
                          ),
                        ),
                      );
                      onGroupsChanged();
                    },
                  );
                },
              ),
            ),

            // Yeni grup oluştur
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NewGroupScreen(),
                    ),
                  );
                  onGroupsChanged();
                },
                child: const Row(
                  children: [
                    Icon(Icons.add, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'New group',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}