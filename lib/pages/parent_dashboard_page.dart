import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/hero_provider.dart';
import '../providers/points_provider.dart';
import '../providers/quest_provider.dart';
import '../providers/reward_provider.dart';
import '../theme/app_colors.dart';
import '../models/enums.dart';
import '../models/hero.dart' as app;
import '../widgets/bottom_navigation.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_scaffold.dart';
import 'parent/quest_management_page.dart';
import 'parent/quest_edit_page.dart';
import 'parent/reward_management_page.dart';
import 'parent/reward_edit_page.dart';
import 'parent/approval_page.dart';
import 'family_management_page.dart';
import 'notification_settings_page.dart';
import 'notifications_page.dart';
import 'appearance_settings_page.dart';
import 'help_support_page.dart';

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomeTab(),
          const QuestManagementPage(),
          const RewardManagementPage(),
          const ApprovalPage(),
          _buildProfileTab(),
        ],
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                title: Text(
                  'Hallo, ${authProvider.currentUser?.name ?? ""}!',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  _buildNotificationBell(),
                ],
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withAlpha(128),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withAlpha(26),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildQuickStatsCard(),
                    const SizedBox(height: 16),
                    _buildPendingApprovalsCard(),
                    const SizedBox(height: 16),
                    _buildFamilyOverviewCard(),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationBell() {
    final userId = context.watch<AuthProvider>().currentUser?.id ?? '';
    final unreadCount = context.watch<NotificationProvider>().unreadCount(userId);

    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        child: const Icon(Icons.notifications_outlined, color: AppColors.text),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const NotificationsPage(),
          ),
        );
      },
    );
  }

  Widget _buildQuickStatsCard() {
    return Consumer3<QuestProvider, PointsProvider, AuthProvider>(
      builder: (context, questProvider, pointsProvider, authProvider, child) {
        // Count quests completed this week (across all children)
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

        int weeklyQuests = 0;
        for (final instances in questProvider.instances.values) {
          weeklyQuests += instances.where((i) =>
            i.status == QuestStatus.completed &&
            i.approvedAt != null &&
            i.approvedAt!.isAfter(weekStartDate),
          ).length;
        }

        // Sum points earned this week across all children
        final children = authProvider.children;
        int weeklyPoints = 0;
        for (final child in children) {
          weeklyPoints += pointsProvider.weeklyEarned(child.id);
        }

        // Count pending reward redemptions
        final pendingRewards = context.read<RewardProvider>().pendingRedemptions.length;

        return GlassContainer(
          padding: const EdgeInsets.all(20),
          tintColor: AppColors.primaryStart.withAlpha(100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diese Woche',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Quests', '$weeklyQuests', Icons.shield),
                  _buildStatItem('Punkte', '$weeklyPoints', Icons.star),
                  _buildStatItem('Rewards', '$pendingRewards', Icons.card_giftcard),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingApprovalsCard() {
    return Consumer<QuestProvider>(
      builder: (context, questProvider, child) {
        final pendingCount = questProvider.pendingApprovalCount;

        return GestureDetector(
          onTap: pendingCount > 0
              ? () => setState(() => _currentNavIndex = 3)
              : null,
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ausstehende Genehmigungen',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$pendingCount Quests warten auf Bestätigung',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              if (pendingCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryStart,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildFamilyOverviewCard() {
    return Consumer3<AuthProvider, HeroProvider, PointsProvider>(
      builder: (context, authProvider, heroProvider, pointsProvider, child) {
        final children = authProvider.children;

        return GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Familie',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (children.isEmpty)
                const Center(
                  child: Text(
                    'Noch keine Kinder hinzugefügt',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...children.map((child) {
                  final hero = heroProvider.heroForUser(child.id);
                  final balance = pointsProvider.balance(child.id);
                  return _buildChildRow(child.name, hero, balance);
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChildRow(String name, app.Hero? hero, int balance) {
    final level = hero?.level ?? 1;
    final streak = hero?.currentStreak ?? 0;
    final xpProgress = hero?.xpProgress ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.teal.withAlpha(51),
            child: const Icon(Icons.emoji_events, color: AppColors.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Lvl $level',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: xpProgress,
                          backgroundColor: AppColors.surface,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryStart.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 2),
                  Text(
                    '$streak',
                    style: const TextStyle(
                      color: AppColors.primaryStart,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          Text(
            '$balance MP',
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          const Text(
            'Profil',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingsItem(
            icon: Icons.family_restroom,
            title: 'Familie verwalten',
            subtitle: 'Mitglieder hinzufügen oder entfernen',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FamilyManagementPage(),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Benachrichtigungen',
            subtitle: 'Push-Benachrichtigungen konfigurieren',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsPage(),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.palette_outlined,
            title: 'Erscheinungsbild',
            subtitle: 'Theme und Darstellung',
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AppearanceSettingsPage(),
                ),
              );
              if (mounted) setState(() {});
            },
          ),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Hilfe & Support',
            subtitle: 'FAQ und Kontakt',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HelpSupportPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Abmelden',
            subtitle: 'Aus dem Account ausloggen',
            isDestructive: true,
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 12,
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppColors.error : AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDestructive ? AppColors.error : AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget? _buildFab() {
    switch (_currentNavIndex) {
      case 1: // Quests tab
        return FloatingActionButton(
          heroTag: 'quest_fab',
          onPressed: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (context) => const QuestEditPage(),
              ),
            );
            if (result == true && mounted) {
              context.read<QuestProvider>().loadQuests();
            }
          },
          child: const Icon(Icons.add),
        );
      case 2: // Rewards tab
        return FloatingActionButton.extended(
          heroTag: 'reward_fab',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RewardEditPage(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Neue Belohnung'),
        );
      default:
        return null;
    }
  }

  Widget _buildBottomNav() {
    return Consumer<QuestProvider>(
      builder: (context, questProvider, child) {
        return BottomNavigation(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() {
              _currentNavIndex = index;
            });
          },
          role: UserRole.parent,
          pendingApprovals: questProvider.pendingApprovalCount,
        );
      },
    );
  }
}
