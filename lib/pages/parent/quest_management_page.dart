import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/quest_provider.dart';
import '../../models/quest.dart';
import '../../models/enums.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/glass_app_bar.dart';
import 'quest_edit_page.dart';

class QuestManagementPage extends StatefulWidget {
  const QuestManagementPage({super.key});

  @override
  State<QuestManagementPage> createState() => _QuestManagementPageState();
}

class _QuestManagementPageState extends State<QuestManagementPage> {
  QuestType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    await context.read<QuestProvider>().loadQuests();
  }

  Future<void> _createQuest() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const QuestEditPage(),
      ),
    );

    if (result == true) {
      _loadQuests();
    }
  }

  Future<void> _editQuest(Quest quest) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => QuestEditPage(quest: quest),
      ),
    );

    if (result == true) {
      _loadQuests();
    }
  }


  List<Quest> _getFilteredQuests(List<Quest> quests) {
    if (_filterType == null) return quests;
    return quests.where((quest) => quest.type == _filterType).toList();
  }

  String _getTypeText(QuestType type) {
    switch (type) {
      case QuestType.daily:
        return 'Daily';
      case QuestType.weekly:
        return 'Weekly';
      case QuestType.epic:
        return 'Epic';
      case QuestType.series:
        return 'Series';
    }
  }

  String _getRarityText(QuestRarity rarity) {
    switch (rarity) {
      case QuestRarity.common:
        return 'Gewöhnlich';
      case QuestRarity.rare:
        return 'Selten';
      case QuestRarity.epic:
        return 'Episch';
      case QuestRarity.legendary:
        return 'Legendär';
    }
  }

  @override
  Widget build(BuildContext context) {
    final questProvider = context.watch<QuestProvider>();
    final allQuests = questProvider.quests;
    final filteredQuests = _getFilteredQuests(allQuests);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: const Text('Quest Verwaltung'),
        actions: [
          PopupMenuButton<QuestType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (type) {
              setState(() {
                _filterType = type;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('Alle anzeigen'),
              ),
              const PopupMenuDivider(),
              ...QuestType.values.map((type) {
                return PopupMenuItem(
                  value: type,
                  child: Text(_getTypeText(type)),
                );
              }),
            ],
          ),
        ],
      ),
      body: filteredQuests.isEmpty
          ? _filterType == null
              ? EmptyState.quests(onCreateQuest: _createQuest)
              : EmptyState(
                  icon: Icons.explore_outlined,
                  title: 'Keine ${_getTypeText(_filterType!)} Quests',
                )
          : ListView.builder(
              itemCount: filteredQuests.length,
              itemBuilder: (context, index) {
                final quest = filteredQuests[index];
                return Dismissible(
                  key: Key(quest.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Quest löschen?'),
                        content: Text('Möchtest du "${quest.name}" wirklich löschen?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Abbrechen'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Löschen'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    await context.read<QuestProvider>().deleteQuest(quest.id);
                  },
                  child: GlassContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: quest.rarityColor.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(quest.icon, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      title: Text(
                        quest.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: quest.rarityColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getRarityText(quest.rarity),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.rarityRare.withAlpha(51),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getTypeText(quest.type),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.rarityRare,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${quest.rewardPoints} Punkte • ${quest.rewardXP} XP'),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _editQuest(quest),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createQuest,
        child: const Icon(Icons.add),
      ),
    );
  }
}
