import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/group.dart';
import '../models/video.dart';
import '../services/youtube_service.dart';
import '../widgets/youtube_webview_player.dart';
import 'group_selection_sheet.dart';
import 'settings_screen.dart';

class PlayerScreen extends StatefulWidget {
  final List<Group> groups;
  final VoidCallback onGroupsChanged;
  final String? defaultGroupId;
  final ValueChanged<bool>? onImmersiveChanged;
  final VoidCallback? onOpenSettings;

  const PlayerScreen({
    super.key,
    required this.groups,
    required this.onGroupsChanged,
    this.defaultGroupId,
    this.onImmersiveChanged,
    this.onOpenSettings,
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

  // Her video değişiminde animasyonu tetiklemek için key
  Key _videoInfoKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _currentGroup = widget.groups.firstWhere(
      (g) => g.id == widget.defaultGroupId,
      orElse: () => widget.groups.first,
    );
    _loadRandomVideo();
    _startHideControlsTimer();
  }

  @override
  void didUpdateWidget(PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // defaultGroupId değiştiyse aktif grubu güncelle ve yeni video yükle
    if (oldWidget.defaultGroupId != widget.defaultGroupId) {
      final newGroup = widget.groups.firstWhere(
        (g) => g.id == widget.defaultGroupId,
        orElse: () => widget.groups.first,
      );
      if (newGroup.id != _currentGroup.id) {
        setState(() => _currentGroup = newGroup);
        _loadRandomVideo();
      }
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
          _videoInfoKey = UniqueKey();
        });
        _setControlsVisible(true); // Yeni video yüklendiğinde kontrolleri göster
        _startHideControlsTimer(); // Ve gizleme zamanlayıcısını başlat
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

  void _setControlsVisible(bool visible) {
    setState(() => _controlsVisible = visible);
    widget.onImmersiveChanged?.call(!visible);
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) _setControlsVisible(false);
    });
  }

  void _onTap() {
    _setControlsVisible(!_controlsVisible);
    if (_controlsVisible) _startHideControlsTimer();
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
          // ── 1. Siyah arka plan ──────────────────────────────────────────
          const ColoredBox(color: Colors.black),

          // ── 2. Video / Yükleniyor / Hata ────────────────────────────────
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

          // ── 3. Alt gradient ─────────────────────────────────────────────
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 250,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
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

          // ── 4. Üst gradient ─────────────────────────────────────────────
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xAA000000), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // ── 5. Üst kontroller (tap ile göster/gizle) ────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: SafeArea(
                child: Padding(
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
                          widget.onOpenSettings?.call(); // ← bunu yaz
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
              ),
            ),
            ),
          ),

          // ── 6. Alt — başlık / kanal adı (kontroller ile birlikte) ──────
          if (_currentVideo != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 350),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.12),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _VideoInfoPanel(
                          key: _videoInfoKey,
                          title: _currentVideo!.title,
                          channelTitle: _currentVideo!.channelTitle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── 7. Immersive tap yakalayıcı ──────────────────────────────────
             if (!_controlsVisible)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _onTap,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox.expand(),
                ),
            ),

        ],  
      ),
    );
  }
}



// ── Video başlık / kanal adı paneli ─────────────────────────────────────────

class _VideoInfoPanel extends StatelessWidget {
  final String title;
  final String channelTitle;

  const _VideoInfoPanel({
    super.key,
    required this.title,
    required this.channelTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Başlık
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        if (channelTitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          // Kanal adı — küçük nokta ayraçlı
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  channelTitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}