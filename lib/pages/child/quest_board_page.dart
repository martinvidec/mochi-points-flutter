import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/quest.dart';
import '../../models/enums.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/quest_card.dart';
import '../../widgets/glass_app_bar.dart';
import '../quest_detail_page.dart';

class QuestBoardPage extends StatefulWidget {
  const QuestBoardPage({super.key});

  @override
  State<QuestBoardPage> createState() => _QuestBoardPageState();
}

class _QuestBoardPageState extends State<QuestBoardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  QuestType? _filterType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadQuests();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _filterType = null; // All
          break;
        case 1:
          _filterType = QuestType.daily;
          break;
        case 2:
          _filterType = QuestType.weekly;
          break;
        case 3:
          _filterType = QuestType.epic;
          break;
        case 4:
          _filterType = QuestType.series;
          break;
      }
    });
  }

  Future<void> _loadQuests() async {
    await context.read<QuestProvider>().loadQuests();
  }

  Future<void> _handleRefresh() async {
    await _loadQuests();
  }

  Future<void> _handleQuestTap(Quest quest, QuestInstance? instance) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuestDetailPage(
          quest: quest,
          instance: instance,
        ),
      ),
    );
    // Refresh after returning from detail page
    _loadQuests();
  }

  List<Quest> _getFilteredQuests(List<Quest> quests) {
    if (_filterType == null) return quests;
    return quests.where((quest) => quest.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final questProvider = context.watch<QuestProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';

    final activeQuests = questProvider.activeQuests(currentUserId);
    final availableQuests = questProvider.availableQuests(currentUserId);
    final filteredQuests = _getFilteredQuests(availableQuests);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: const Text('Quest Board'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Alle'),
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Epic'),
            Tab(text: 'Series'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            // Active Quests Section
            if (activeQuests.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Aktive Quests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final instance = activeQuests[index];
                    final quest = questProvider.quests
                        .where((q) => q.id == instance.questId)
                        .firstOrNull;
                    if (quest == null) return const SizedBox.shrink();

                    return QuestCard(
                      quest: quest,
                      instance: instance,
                      onTap: () => _handleQuestTap(quest, instance),
                    );
                  },
                  childCount: activeQuests.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: Divider(height: 32, thickness: 1),
              ),
            ],
            // Available Quests Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.explore,
                      color: AppColors.rarityRare,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Verfügbare Quests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filteredQuests.isEmpty)
              SliverFillRemaining(
                child: EmptyState.quests(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final quest = filteredQuests[index];
                    return QuestCard(
                      quest: quest,
                      onTap: () => _handleQuestTap(quest, null),
                    );
                  },
                  childCount: filteredQuests.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
