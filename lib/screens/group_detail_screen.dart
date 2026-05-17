import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/channel.dart';
import '../models/group.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/youtube_service.dart';
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
  late Group _group;

  final _storage = StorageService();
  final _authService = AuthService();
  late final _youtube = YouTubeService(authService: _authService);

  bool _loadingSubscriptions = false;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
  }

  // ─── Kanal kaldır ─────────────────────────────────────────────────────

  Future<void> _removeChannel(Channel channel) async {
    final updated = _group.copyWith(
      channels: _group.channels.where((c) => c.id != channel.id).toList(),
    );
    setState(() => _group = updated);
    await _storage.updateGroup(updated);
    widget.onGroupChanged();
  }

  // ─── Grup sil ─────────────────────────────────────────────────────────

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete group?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '"${_group.name}" will be permanently deleted.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
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

    Future<void> _renameGroup() async {
    final controller = TextEditingController(text: _group.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Rename group',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Group name'),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _group.name) {
      final updated = _group.copyWith(name: newName);
      setState(() => _group = updated);
      await _storage.updateGroup(updated);
      widget.onGroupChanged();
    }
  }

  // ─── Abonelik import ──────────────────────────────────────────────────

  Future<void> _importFromSubscriptions() async {
    if (!_authService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in with Google to import subscriptions.'),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    setState(() => _loadingSubscriptions = true);

    try {
      final subs = await _youtube.getSubscriptions(maxResults: 50);
      final existingIds = {for (final c in _group.channels) c.id};
      final available = subs.where((c) => !existingIds.contains(c.id)).toList();

      if (!mounted) return;
      setState(() => _loadingSubscriptions = false);

      if (available.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All your subscriptions are already in this group.'),
            backgroundColor: AppColors.surface,
          ),
        );
        return;
      }

      _showSubscriptionPicker(available);
    } on YouTubeAuthException {
      if (mounted) {
        setState(() => _loadingSubscriptions = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('YouTube access required. Allow it in Settings.'),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSubscriptions = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load subscriptions. Try again.'),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    }
  }

  void _showSubscriptionPicker(List<Channel> available) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubscriptionPickerSheet(
        available: available,
        onImport: (selected) async {
          final merged = [..._group.channels, ...selected];
          final unique = {for (final c in merged) c.id: c}.values.toList();
          final updated = _group.copyWith(channels: unique);
          setState(() => _group = updated);
          await _storage.updateGroup(updated);
          widget.onGroupChanged();
        },
      ),
    );
  }

  // ─── Kanal ekle (arama) ───────────────────────────────────────────────

  Future<void> _addChannels() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChannelSearchScreen(
          groupName: _group.name,
          existingGroupId: _group.id,
        ),
      ),
    );
    // Ekran dönünce storage'dan taze veriyi oku
    final groups = await _storage.loadGroups();
    final refreshed = groups.firstWhere(
      (g) => g.id == _group.id,
      orElse: () => _group,
    );
    if (mounted) setState(() => _group = refreshed);
    widget.onGroupChanged();
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Üst bar ────────────────────────────────────────────────
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
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: _renameGroup,
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _group.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.edit_outlined,
                                  color: AppColors.textTertiary, size: 16),
                            ],
                          ),
                          Text(
                            '${_group.channels.length} channel${_group.channels.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _deleteGroup,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                    tooltip: 'Delete group',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Kanal listesi ──────────────────────────────────────────
            Expanded(
              child: _group.channels.isEmpty
                  ? _EmptyState(onAddChannels: _addChannels)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _group.channels.length,
                      separatorBuilder: (_, __) => const Divider(
                        indent: 72,
                        endIndent: 20,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final channel = _group.channels[index];
                        return _ChannelTile(
                          channel: channel,
                          onRemove: () => _removeChannel(channel),
                        );
                      },
                    ),
            ),

            // ── Alt aksiyonlar ─────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(
                children: [
                  // Kanal ara
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.search,
                      label: 'Add Channels',
                      onTap: _addChannels,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Abonelik import
                  Expanded(
                    child: _loadingSubscriptions
                        ? const Center(
                            child: SizedBox(
                              height: 44,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : _ActionButton(
                            icon: Icons.subscriptions_outlined,
                            label: 'From Subscriptions',
                            onTap: _importFromSubscriptions,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Kanal satırı ────────────────────────────────────────────────────────────

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onRemove;

  const _ChannelTile({required this.channel, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.surfaceVariant,
        backgroundImage: channel.thumbnailUrl.isNotEmpty
            ? NetworkImage(channel.thumbnailUrl)
            : null,
        child: channel.thumbnailUrl.isEmpty
            ? const Icon(Icons.tv, color: AppColors.textSecondary, size: 20)
            : null,
      ),
      title: Text(
        channel.title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: channel.subscriberCount.isNotEmpty
          ? Text(
              channel.subscriberCount,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: IconButton(
        onPressed: onRemove,
        icon: const Icon(Icons.remove_circle_outline,
            color: Colors.white24, size: 22),
        tooltip: 'Remove',
      ),
    );
  }
}

// ─── Boş durum ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddChannels;

  const _EmptyState({required this.onAddChannels});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tv_off_outlined,
              color: AppColors.textTertiary, size: 48),
          const SizedBox(height: 16),
          const Text(
            'No channels yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add channels to start watching',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onAddChannels,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Add Channels'),
          ),
        ],
      ),
    );
  }
}

// ─── Alt aksiyon butonu ──────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Abonelik seçici sheet ───────────────────────────────────────────────────

class _SubscriptionPickerSheet extends StatefulWidget {
  final List<Channel> available;
  final Future<void> Function(List<Channel> selected) onImport;

  const _SubscriptionPickerSheet({
    required this.available,
    required this.onImport,
  });

  @override
  State<_SubscriptionPickerSheet> createState() =>
      _SubscriptionPickerSheetState();
}

class _SubscriptionPickerSheetState extends State<_SubscriptionPickerSheet> {
  final Set<String> _selected = {};
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _saving = false;

  List<Channel> get _filtered {
    if (_query.isEmpty) return widget.available;
    return widget.available
        .where((c) => c.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  bool get _allSelected =>
      _filtered.isNotEmpty &&
      _filtered.every((c) => _selected.contains(c.id));

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        for (final c in _filtered) {
          _selected.remove(c.id);
        }
      } else {
        for (final c in _filtered) {
          _selected.add(c.id);
        }
      }
    });
  }

  Future<void> _import() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);

    final toImport =
        widget.available.where((c) => _selected.contains(c.id)).toList();
    await widget.onImport(toImport);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Tutaç ──────────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // ── Başlık + Done ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your Subscriptions',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : TextButton(
                            onPressed: _import,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'Add ${_selected.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Arama ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Filter channels...',
                  prefixIcon: Icon(Icons.search,
                      color: AppColors.textTertiary, size: 20),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),

            const SizedBox(height: 8),

            // ── Tümünü seç ─────────────────────────────────────────────
            if (filtered.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: GestureDetector(
                  onTap: _toggleAll,
                  child: Row(
                    children: [
                      Icon(
                        _allSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: _allSelected
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _allSelected ? 'Deselect all' : 'Select all',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const Divider(height: 1),

            // ── Liste ──────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No subscriptions found',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                        indent: 72,
                        endIndent: 16,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final channel = filtered[index];
                        final isSelected = _selected.contains(channel.id);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.surfaceVariant,
                            backgroundImage: channel.thumbnailUrl.isNotEmpty
                                ? NetworkImage(channel.thumbnailUrl)
                                : null,
                            child: channel.thumbnailUrl.isEmpty
                                ? const Icon(Icons.tv,
                                    color: AppColors.textSecondary, size: 20)
                                : null,
                          ),
                          title: Text(
                            channel.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            size: 24,
                          ),
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selected.remove(channel.id);
                            } else {
                              _selected.add(channel.id);
                            }
                          }),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}