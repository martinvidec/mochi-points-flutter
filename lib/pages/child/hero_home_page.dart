import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quest.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hero_provider.dart';
import '../../providers/points_provider.dart';
import '../../providers/quest_provider.dart';
import '../../theme/app_colors.dart';
import '../../models/enums.dart';
import '../../widgets/app_button.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/hero_card.dart';
import '../../widgets/points_display.dart';
import '../../widgets/quest_card.dart';
import '../quest_detail_page.dart';
import '../transaction_history_page.dart';
import 'quest_board_page.dart';
import 'shop_page.dart';
import 'my_rewards_page.dart';

class ChildHeroHomePage extends StatefulWidget {
  const ChildHeroHomePage({super.key});

  @override
  State<ChildHeroHomePage> createState() => _ChildHeroHomePageState();
}

class _ChildHeroHomePageState extends State<ChildHeroHomePage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomeTab(),
          _buildQuestsTab(),
          _buildRewardsTab(),
          _buildShopTab(),
          _buildProfileTab(),
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
                  backgroundColor: Colors.transparent,
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
                              color: AppColors.teal,
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
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      tintColor: const Color(0xFF2D4A3E).withAlpha(128),
      child: Column(
        children: [
          const Icon(
            Icons.person_add,
            size: 48,
            color: AppColors.teal,
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
    return GlassContainer(
      padding: const EdgeInsets.all(16),
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
                      color: AppColors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+$weeklyEarned',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.teal,
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
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
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
          AppButton.primary(
            onPressed: () {
              setState(() {
                _currentNavIndex = 1;
              });
            },
            label: 'Quest Board',
            icon: Icons.explore,
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
            color: AppColors.rarityRare,
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
            color: AppColors.gold,
            onTap: () {
              setState(() {
                _currentNavIndex = 3;
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
    return const QuestBoardPage();
  }

  Widget _buildShopTab() {
    return const ShopPage();
  }

  Widget _buildRewardsTab() {
    return const MyRewardsPage();
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
          _buildProfileItem(
            icon: Icons.person,
            title: 'Profil bearbeiten',
            subtitle: 'Name und Avatar anpassen',
            onTap: () {
              // TODO: Navigate to profile edit
            },
          ),
          _buildProfileItem(
            icon: Icons.history,
            title: 'Transaktionen',
            subtitle: 'Punkte-Historie anzeigen',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TransactionHistoryPage(),
                ),
              );
            },
          ),
          _buildProfileItem(
            icon: Icons.palette_outlined,
            title: 'Erscheinungsbild',
            subtitle: 'Theme und Darstellung',
            onTap: () {},
          ),
          _buildProfileItem(
            icon: Icons.help_outline,
            title: 'Hilfe & Support',
            subtitle: 'FAQ und Kontakt',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildProfileItem(
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

  Widget _buildProfileItem({
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

  Widget _buildBottomNav() {
    return BottomNavigation(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        setState(() {
          _currentNavIndex = index;
        });
      },
      role: UserRole.child,
      pendingRewards: _getPendingRewardsCount(),
    );
  }

  int _getPendingRewardsCount() {
    // TODO: Implement pending rewards count from provider
    return 0;
  }

  void _onQuestTap(Quest quest, QuestInstance? instance) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestDetailPage(
          quest: quest,
          instance: instance,
        ),
      ),
    );
  }

}
