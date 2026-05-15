import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/channel.dart';
import '../models/group.dart';
import '../services/storage_service.dart';
import '../services/youtube_service.dart';

class ChannelSearchScreen extends StatefulWidget {
  final String groupName;
  final String? existingGroupId;
  final String? initialQuery; // Kategori preseti için otomatik arama

  const ChannelSearchScreen({
    super.key,
    required this.groupName,
    this.existingGroupId,
    this.initialQuery,
  });

  @override
  State<ChannelSearchScreen> createState() => _ChannelSearchScreenState();
}

class _ChannelSearchScreenState extends State<ChannelSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final YouTubeService _youtube = YouTubeService();
  final StorageService _storage = StorageService();

  List<Channel> _searchResults = [];
  List<Channel> _selectedChannels = [];
  bool _isSearching = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Kategori preseti varsa ekranı açar açmaz ara
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _search(widget.initialQuery!);
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await _youtube.searchChannels(query.trim());
      // Her kanal için detay çek (abone sayısı için)
      final detailed = await Future.wait(
        results.map((c) => _youtube.getChannelDetails(c.id)),
      );
      if (mounted) {
        setState(() {
          _searchResults = detailed;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Search failed. Check your connection.';
          _isSearching = false;
        });
      }
    }
  }

  void _toggleChannel(Channel channel) {
    setState(() {
      final exists = _selectedChannels.any((c) => c.id == channel.id);
      if (exists) {
        _selectedChannels.removeWhere((c) => c.id == channel.id);
      } else {
        _selectedChannels.add(channel);
      }
    });
  }

  bool _isSelected(Channel channel) {
    return _selectedChannels.any((c) => c.id == channel.id);
  }

  Future<void> _saveGroup() async {
    if (_selectedChannels.isEmpty) return;
    setState(() => _isSaving = true);

    if (widget.existingGroupId != null) {
      // Mevcut gruba kanal ekle
      final groups = await _storage.loadGroups();
      final existing = groups.firstWhere((g) => g.id == widget.existingGroupId);
      final merged = [...existing.channels, ..._selectedChannels];
      final unique = {for (var c in merged) c.id: c}.values.toList();
      await _storage.updateGroup(existing.copyWith(channels: unique));
    } else {
      // Yeni grup oluştur
      final group = Group(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: widget.groupName,
        channels: _selectedChannels,
      );
      await _storage.addGroup(group);
    }

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Add to '${widget.groupName}'",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Done butonu
                  TextButton(
                    onPressed:
                        _selectedChannels.isNotEmpty && !_isSaving
                            ? _saveGroup
                            : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Text(
                            'Done',
                            style: TextStyle(
                              color: _selectedChannels.isNotEmpty
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // Seçilen kanal sayısı
            if (_selectedChannels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_selectedChannels.length} channel${_selectedChannels.length > 1 ? 's' : ''} added',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

            // Arama input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchController,
                autofocus: widget.initialQuery == null,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search channels...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
              ),
            ),

            const SizedBox(height: 8),

            // İçerik
            Expanded(
              child: _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        )
                      : _searchResults.isEmpty
                          ? const Center(
                              child: Text(
                                'Search for a YouTube channel',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 15,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => const Divider(
                                indent: 72,
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final channel = _searchResults[index];
                                final selected = _isSelected(channel);
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundImage:
                                        channel.thumbnailUrl.isNotEmpty
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
                                  trailing: selected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                          size: 26,
                                        )
                                      : const Icon(
                                          Icons.add_circle_outline,
                                          color: AppColors.textTertiary,
                                          size: 26,
                                        ),
                                  onTap: () => _toggleChannel(channel),
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