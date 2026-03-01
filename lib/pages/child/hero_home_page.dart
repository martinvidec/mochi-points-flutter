import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quest.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hero_provider.dart';
import '../../providers/points_provider.dart';
import '../../providers/quest_provider.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/points_display.dart';
import '../../widgets/quest_card.dart';

class ChildHeroHomePage extends StatefulWidget {
  const ChildHeroHomePage({super.key});

  @override
  State<ChildHeroHomePage> createState() => _ChildHeroHomePageState();
}

class _ChildHeroHomePageState extends State<ChildHeroHomePage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomeTab(),
          _buildQuestsTab(),
          _buildShopTab(),
          _buildRewardsTab(),
          _buildStatsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: Consumer4<AuthProvider, HeroProvider, PointsProvider, QuestProvider>(
        builder: (context, authProvider, heroProvider, pointsProvider, questProvider, child) {
          final userId = authProvider.currentUser?.id;
          if (userId == null) {
            return const Center(
              child: Text(
                'Nicht angemeldet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final hero = heroProvider.heroForUser(userId);
          final points = pointsProvider.balance(userId);
          final weeklyEarned = pointsProvider.weeklyEarned(userId);
          final activeQuests = questProvider.activeQuests(userId);
          final availableQuests = questProvider.availableQuests(userId);

          return RefreshIndicator(
            onRefresh: () async {
              await questProvider.loadQuests();
            },
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: const Color(0xFF1A1B2E),
                  floating: true,
                  title: const Text(
                    'Mochi Hero',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
                      onPressed: () {
                        // TODO: Notifications
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                      onPressed: () {
                        _showSettingsMenu(context);
                      },
                    ),
                  ],
                ),

                // Hero Card
                SliverToBoxAdapter(
                  child: hero != null
                      ? HeroCard(
                          hero: hero,
                          onTap: () {
                            // TODO: Navigate to hero detail/customization
                          },
                        )
                      : _buildNoHeroCard(),
                ),

                // Points Display
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildPointsSection(points, weeklyEarned),
                  ),
                ),

                // Today's Quests Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Aktive Quests',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentNavIndex = 1;
                            });
                          },
                          child: const Text(
                            'Alle anzeigen',
                            style: TextStyle(
                              color: Color(0xFF4ECDC4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Active Quests List
                if (activeQuests.isEmpty && availableQuests.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyQuestsCard(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < activeQuests.length) {
                          final instance = activeQuests[index];
                          final quest = questProvider.quests
                              .where((q) => q.id == instance.questId)
                              .firstOrNull;
                          if (quest == null) return const SizedBox.shrink();
                          return QuestCard(
                            quest: quest,
                            instance: instance,
                            onTap: () => _onQuestTap(quest, instance),
                          );
                        } else {
                          // Show first few available quests
                          final availableIndex = index - activeQuests.length;
                          if (availableIndex >= 3) return null;
                          final quest = availableQuests[availableIndex];
                          return QuestCard(
                            quest: quest,
                            onTap: () => _onQuestTap(quest, null),
                          );
                        }
                      },
                      childCount: activeQuests.length + (availableQuests.length > 3 ? 3 : availableQuests.length),
                    ),
                  ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildQuickActions(),
                  ),
                ),

                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoHeroCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D4A3E), Color(0xFF1A3A2E)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withAlpha(128),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_add,
            size: 48,
            color: Color(0xFF4ECDC4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Erstelle deinen Hero!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Starte dein Abenteuer und verdiene Mochi Punkte',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha(179),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPointsSection(int points, int weeklyEarned) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2B42), Color(0xFF3A3B52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFE66D).withAlpha(51),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: PointsDisplay(
              points: points,
              variant: PointsDisplayVariant.large,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diese Woche',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(153),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Color(0xFF4ECDC4),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+$weeklyEarned',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Punkte verdient',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(128),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQuestsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(26),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.white.withAlpha(102),
          ),
          const SizedBox(height: 12),
          const Text(
            'Keine aktiven Quests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Schau im Quest Board nach neuen Abenteuern!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha(153),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _currentNavIndex = 1;
              });
            },
            icon: const Icon(Icons.explore),
            label: const Text('Quest Board'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.explore,
            label: 'Alle Quests',
            color: const Color(0xFF4A9DFF),
            onTap: () {
              setState(() {
                _currentNavIndex = 1;
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.store,
            label: 'Shop',
            color: const Color(0xFFFFE66D),
            onTap: () {
              setState(() {
                _currentNavIndex = 2;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withAlpha(77),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestsTab() {
    return const Center(
      child: Text(
        'Quest Board\n(Öffnet quest_board_page.dart)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildShopTab() {
    return const Center(
      child: Text(
        'Shop\n(Öffnet shop_page.dart)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildRewardsTab() {
    return const Center(
      child: Text(
        'Meine Belohnungen\n(Öffnet my_rewards_page.dart)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildStatsTab() {
    return const Center(
      child: Text(
        'Statistiken & Achievements\n(Kommt bald)',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B42),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'Quests',
                index: 1,
                badge: _getQuestBadgeCount(),
              ),
              _buildNavItem(
                icon: Icons.store_outlined,
                activeIcon: Icons.store,
                label: 'Shop',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.card_giftcard_outlined,
                activeIcon: Icons.card_giftcard,
                label: 'Rewards',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events,
                label: 'Stats',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    int? badge,
  }) {
    final isActive = _currentNavIndex == index;
    final color = isActive ? const Color(0xFFFF6B6B) : Colors.white54;

    return InkWell(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: color,
                  size: 24,
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B6B),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  int? _getQuestBadgeCount() {
    final authProvider = context.read<AuthProvider>();
    final questProvider = context.read<QuestProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId == null) return null;

    final availableCount = questProvider.availableQuests(userId).length;
    return availableCount > 0 ? availableCount : null;
  }

  void _onQuestTap(Quest quest, QuestInstance? instance) {
    Navigator.of(context).pushNamed(
      '/quest-detail',
      arguments: {'quest': quest, 'instance': instance},
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2B42),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.white70),
                  title: const Text(
                    'Profil bearbeiten',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to profile edit
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.white70),
                  title: const Text(
                    'Transaktionen',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/transactions');
                  },
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
                  title: const Text(
                    'Abmelden',
                    style: TextStyle(color: Color(0xFFFF6B6B)),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
