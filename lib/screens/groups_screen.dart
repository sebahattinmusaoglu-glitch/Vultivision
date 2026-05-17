import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/group.dart';
import 'channel_search_screen.dart';
import 'group_detail_screen.dart';
import 'new_group_screen.dart';

class GroupsScreen extends StatelessWidget {
  final List<Group> groups;
  final VoidCallback onGroupsChanged;
  final VoidCallback onSwitchToWatch;

  const GroupsScreen({
    super.key,
    required this.groups,
    required this.onGroupsChanged,
    required this.onSwitchToWatch,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return _EmptyGroupsView(
        onGroupsChanged: onGroupsChanged,
        onSwitchToWatch: onSwitchToWatch,
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
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
              itemCount: groups.length +1, // +1 for the "New group" button
              separatorBuilder: (_, __) => const Divider(
                indent: 24,
                endIndent: 24,
                height: 1,
              ),
              itemBuilder: (context, index) {
                // Eğer index sonuncu ise, "New group" butonunu göster
                if (index == groups.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
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
                  );
    }
                // Grup itemleri buradan başlar
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

        ],
      ),
    );
  }
}

// ─── Boş durum: grup oluşturma + kategori presetleri ─────────────────────────

class _EmptyGroupsView extends StatefulWidget {
  final VoidCallback onGroupsChanged;
  final VoidCallback onSwitchToWatch;

  const _EmptyGroupsView({
    required this.onGroupsChanged,
    required this.onSwitchToWatch,
  });

  @override
  State<_EmptyGroupsView> createState() => _EmptyGroupsViewState();
}

class _EmptyGroupsViewState extends State<_EmptyGroupsView> {
  final _nameController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() => _isValid = _nameController.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addGroup() {
    if (!_isValid) return;
    _openChannelSearch(_nameController.text.trim());
  }

  void _openChannelSearch(String groupName, {String? initialQuery}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChannelSearchScreen(
          groupName: groupName,
          initialQuery: initialQuery,
        ),
      ),
    );
    widget.onGroupsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          // ── Başlık ────────────────────────────────────────────────
          const Text(
            'Groups',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your category name\nand watch YouTube as a TV.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // ── Grup adı ──────────────────────────────────────────────
          const Text(
            'Group Name',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'You can add your group name',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'Type your group name',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addGroup(),
          ),

          const SizedBox(height: 16),

          // Add a Group butonu
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isValid ? _addGroup : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceVariant,
                disabledForegroundColor: AppColors.textTertiary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add a Group',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── OR ayırıcı ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Divider(color: Colors.white.withOpacity(0.12)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: Colors.white.withOpacity(0.12)),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Kategori başlığı ──────────────────────────────────────
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Groups',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Use popular group names and add new channels',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),

          const SizedBox(height: 16),

          // ── Kategori grid ─────────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: _kCategories.map((cat) {
              return _CategoryCard(
                category: cat,
                onTap: () => _openChannelSearch(
                  cat.name,
                  initialQuery: cat.searchQuery,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Kategori kartı ──────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final _Category category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(category.icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    category.subtitle,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Kategori verisi ─────────────────────────────────────────────────────────

class _Category {
  final String name;
  final IconData icon;
  final String subtitle;
  final String searchQuery;

  const _Category({
    required this.name,
    required this.icon,
    required this.subtitle,
    required this.searchQuery,
  });
}

const _kCategories = [
  _Category(
    name: 'Music',
    icon: Icons.music_note_outlined,
    subtitle: 'Top tracks and videos',
    searchQuery: 'music',
  ),
  _Category(
    name: 'Gaming',
    icon: Icons.sports_esports_outlined,
    subtitle: 'Gameplay & lets plays',
    searchQuery: 'gaming',
  ),
  _Category(
    name: 'Education',
    icon: Icons.school_outlined,
    subtitle: 'Learn something new',
    searchQuery: 'education',
  ),
  _Category(
    name: 'Comedy',
    icon: Icons.sentiment_satisfied_alt_outlined,
    subtitle: 'Laugh out loud',
    searchQuery: 'comedy',
  ),
  _Category(
    name: 'Movies',
    icon: Icons.movie_outlined,
    subtitle: 'Trailers & classics',
    searchQuery: 'movie trailers',
  ),
  _Category(
    name: 'Trending',
    icon: Icons.local_fire_department_outlined,
    subtitle: "What's popular now",
    searchQuery: 'trending',
  ),
];