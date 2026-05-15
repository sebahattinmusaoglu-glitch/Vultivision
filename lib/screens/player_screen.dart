import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../models/group.dart';
import '../models/video.dart';
import '../services/youtube_service.dart';
import '../widgets/youtube_webview_player.dart';
import 'group_selection_sheet.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerScreen extends StatefulWidget {
  final List<Group> groups;
  final VoidCallback onGroupsChanged;
  final Group? initialGroup;
  final String? defaultGroupId;

  const PlayerScreen({
    super.key,
    required this.groups,
    required this.onGroupsChanged,
    this.initialGroup, 
    this.defaultGroupId, // ekle
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final YouTubeService _youtube = YouTubeService();

  late Group _currentGroup;
  Video? _currentVideo;
  bool _isLoadingVideo = true;
  bool _controlsVisible = true;
  String? _error;
  Timer? _hideControlsTimer;


  @override
  void didUpdateWidget(PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultGroupId != widget.defaultGroupId ||
        oldWidget.groups != widget.groups) {
      _applyDefaultGroup();
    }
  }

  Future<void> _applyDefaultGroup() async {
    if (widget.defaultGroupId == null) return;
    final match = widget.groups
        .where((g) => g.id == widget.defaultGroupId)
        .firstOrNull;
    if (match != null && match.id != _currentGroup.id && mounted) {
      setState(() => _currentGroup = match);
      _loadRandomVideo();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRandomVideo() async {
    setState(() {
      _isLoadingVideo = true;
      _error = null;
    });

    try {
      final video = await _youtube.getRandomVideoFromChannels(
        _currentGroup.channels,
      );
      if (mounted) {
        setState(() {
          _currentVideo = video;
          _isLoadingVideo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load video. Tap to retry.';
          _isLoadingVideo = false;
        });
      }
    }
  }

  void _switchGroup(Group group) {
    setState(() => _currentGroup = group);
    _loadRandomVideo();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _onTap() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _startHideControlsTimer();
  }

  void _showGroupPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'My Groups',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.groups.map(
              (group) => ListTile(
                title: Text(
                  group.name,
                  style: TextStyle(
                    color: group.id == _currentGroup.id
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${group.channels.length} channel${group.channels.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                trailing: group.id == _currentGroup.id
                    ? const Icon(
                        Icons.circle,
                        color: AppColors.primary,
                        size: 10,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _switchGroup(group);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: _onTap,
    onVerticalDragEnd: (details) {
      if ((details.primaryVelocity ?? 0) < -400) {
        _loadRandomVideo();
      }
    },
    child: Stack(
      fit: StackFit.expand,
      children: [
        // ... geri kalan aynı
              // Video
              if (_isLoadingVideo)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else if (_error != null)
                GestureDetector(
                  onTap: _loadRandomVideo,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh,
                          color: AppColors.textSecondary,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_currentVideo != null)
                YoutubeWebViewPlayer(
                  videoId: _currentVideo!.id,
                  onVideoEnded: _loadRandomVideo,
                  onError: _loadRandomVideo,
                ),

              // Alt gradient
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 250,
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xCC000000),
                          Colors.black,
                        ],
                        stops: [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Üst gradient
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: IgnorePointer(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xAA000000), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),

              // Kontroller
              IgnorePointer(
                ignoring: !_controlsVisible,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Üst bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final selected =
                                      await showModalBottomSheet<Group>(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => GroupSelectionSheet(
                                      groups: widget.groups,
                                      currentGroup: _currentGroup,
                                    ),
                                  );
                                  if (selected != null) _switchGroup(selected);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentGroup.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: AppColors.textPrimary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.settings_outlined,
                                  color: AppColors.textPrimary,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Alt — video başlığı
                        if (_currentVideo != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentVideo!.title,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentVideo!.channelTitle,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

    );
  }
}