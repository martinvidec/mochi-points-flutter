import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../models/enums.dart';
import '../providers/achievement_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_scaffold.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (null, 'Alle', Icons.grid_view),
    (AchievementCategory.streak, 'Streak', Icons.local_fire_department),
    (AchievementCategory.quests, 'Quests', Icons.assignment),
    (AchievementCategory.points, 'Points', Icons.stars),
    (AchievementCategory.special, 'Spezial', Icons.auto_awesome),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final achievementProvider = context.watch<AchievementProvider>();

    final heroId = authProvider.currentUser?.id ?? '';
    final unlockedCount = achievementProvider.getUnlockedCount(heroId);
    final totalCount = achievementProvider.totalCount;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Achievements'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) {
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.$3, size: 18),
                  const SizedBox(width: 6),
                  Text(tab.$2),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Stats header
          _buildStatsHeader(unlockedCount, totalCount),

          // Achievement grid
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                return _buildAchievementGrid(
                  heroId,
                  achievementProvider,
                  tab.$1,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(int unlocked, int total) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 0,
      child: Row(
        children: [
          // Trophy icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.gold, AppColors.primaryEnd],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.emoji_events, size: 24, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),

          // Progress info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked / $total freigeschaltet',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withAlpha(26),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.gold,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Percentage
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementGrid(
    String heroId,
    AchievementProvider provider,
    AchievementCategory? category,
  ) {
    final achievementsWithProgress = provider.getAchievementsWithProgress(heroId);

    // Filter by category if specified
    final filtered = category == null
        ? achievementsWithProgress
        : achievementsWithProgress
            .where((item) => item.$1.category == category)
            .toList();

    // Sort: unlocked first, then by tier (platinum > gold > silver > bronze)
    filtered.sort((a, b) {
      final aUnlocked = a.$2?.isUnlocked ?? false;
      final bUnlocked = b.$2?.isUnlocked ?? false;

      if (aUnlocked != bUnlocked) {
        return aUnlocked ? -1 : 1;
      }

      return b.$1.tier.index.compareTo(a.$1.tier.index);
    });

    if (filtered.isEmpty) {
      return _buildEmptyState(category);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final (achievement, progress) = filtered[index];
        return AchievementBadge(
          achievement: achievement,
          progress: progress,
          size: AchievementBadgeSize.medium,
          onTap: () => _showAchievementDetails(context, achievement, progress),
        );
      },
    );
  }

  Widget _buildEmptyState(AchievementCategory? category) {
    if (category == null) {
      return EmptyState.achievements();
    }
    return EmptyState(
      icon: Icons.emoji_events_outlined,
      title: 'Keine ${_getCategoryName(category)} Achievements',
    );
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.quests:
        return 'Quest';
      case AchievementCategory.points:
        return 'Points';
      case AchievementCategory.special:
        return 'Spezial';
    }
  }

  void _showAchievementDetails(
    BuildContext context,
    Achievement achievement,
    AchievementProgress? progress,
  ) {
    final isUnlocked = progress?.isUnlocked ?? false;
    final isSecret = achievement.isSecret && !isUnlocked;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface.withAlpha(200),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(77),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Badge
              AchievementBadge(
                achievement: achievement,
                progress: progress,
                size: AchievementBadgeSize.large,
                showName: false,
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                isSecret ? '???' : achievement.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),

              // Tier
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: achievement.tierColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: achievement.tierColor.withAlpha(128),
                  ),
                ),
                child: Text(
                  achievement.tier.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: achievement.tierColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                isSecret
                    ? 'Dieses Achievement ist noch geheim...'
                    : achievement.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withAlpha(179),
                ),
              ),
              const SizedBox(height: 20),

              // Progress or Rewards
              if (!isUnlocked && progress != null) ...[
                _buildProgressSection(progress),
              ] else if (isUnlocked) ...[
                _buildRewardsSection(achievement),
              ],

              // Unlock date
              if (isUnlocked && progress?.unlockedAt != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Freigeschaltet am ${_formatDate(progress!.unlockedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(102),
                  ),
                ),
              ],

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressSection(AchievementProgress progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fortschritt',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Text(
                '${progress.currentProgress} / ${progress.targetProgress}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.progressPercent,
              backgroundColor: Colors.white.withAlpha(26),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.teal,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection(Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildRewardItem(Icons.bolt, '${achievement.rewardXP} XP'),
          if (achievement.rewardPoints != null)
            _buildRewardItem(Icons.auto_awesome, '${achievement.rewardPoints} Points'),
          if (achievement.rewardItem != null)
            _buildRewardItem(Icons.card_giftcard, achievement.rewardItem!),
        ],
      ),
    );
  }

  Widget _buildRewardItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.gold),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
