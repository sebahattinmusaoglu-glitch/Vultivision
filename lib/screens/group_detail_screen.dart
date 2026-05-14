import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/group.dart';
import '../models/channel.dart';
import '../services/storage_service.dart';
import 'channel_search_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  final VoidCallback onGroupChanged;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.onGroupChanged,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final StorageService _storage = StorageService();
  late Group _group;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  Future<void> _removeChannel(Channel channel) async {
    final updatedChannels =
        _group.channels.where((c) => c.id != channel.id).toList();
    final updatedGroup = _group.copyWith(channels: updatedChannels);
    await _storage.updateGroup(updatedGroup);
    setState(() => _group = updatedGroup);
    widget.onGroupChanged();
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Group',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${_group.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _storage.deleteGroup(_group.id);
      widget.onGroupChanged();
      Navigator.of(context).pop();
    }
  }

  Future<void> _addChannels() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChannelSearchScreen(
          groupName: _group.name,
          existingGroupId: _group.id,
        ),
      ),
    );
    // Grupları yeniden yükle
    final groups = await _storage.loadGroups();
    final updatedGroup = groups.firstWhere(
      (g) => g.id == _group.id,
      orElse: () => _group,
    );
    if (mounted) {
      setState(() => _group = updatedGroup);
      widget.onGroupChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Üst bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _isEditing = !_isEditing),
                    child: Text(
                      _isEditing ? 'Done' : 'Edit',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _group.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_group.channels.length} channel${_group.channels.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Kanal listesi
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: _group.channels.length + 1,
                separatorBuilder: (_, index) => index < _group.channels.length
                    ? const Divider(indent: 72, height: 1)
                    : const SizedBox.shrink(),
                itemBuilder: (context, index) {
                  // Son item: Kanal Ekle butonu
                  if (index == _group.channels.length) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Add Channel',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: _addChannels,
                    );
                  }

                  final channel = _group.channels[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: channel.thumbnailUrl.isNotEmpty
                          ? NetworkImage(channel.thumbnailUrl)
                          : null,
                      backgroundColor: AppColors.surfaceVariant,
                      child: channel.thumbnailUrl.isEmpty
                          ? const Icon(Icons.tv,
                              color: AppColors.textSecondary)
                          : null,
                    ),
                    title: Text(
                      channel.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      channel.subscriberCount,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    trailing: _isEditing
                        ? IconButton(
                            onPressed: () => _removeChannel(channel),
                            icon: const Icon(
                              Icons.remove_circle,
                              color: AppColors.error,
                              size: 24,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),

            // Grubu Sil butonu
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton(
                    onPressed: _deleteGroup,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete Group',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}