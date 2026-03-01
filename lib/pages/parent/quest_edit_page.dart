import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/quest.dart';
import '../../models/enums.dart';
import '../../providers/quest_provider.dart';
import '../../providers/auth_provider.dart';

class QuestEditPage extends StatefulWidget {
  final Quest? quest;

  const QuestEditPage({super.key, this.quest});

  @override
  State<QuestEditPage> createState() => _QuestEditPageState();
}

class _QuestEditPageState extends State<QuestEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  final _xpController = TextEditingController();
  final _unitController = TextEditingController();

  String _selectedIcon = '📝';
  QuestType _selectedType = QuestType.daily;
  QuestRarity _selectedRarity = QuestRarity.common;
  List<String> _assignedTo = [];
  DateTime? _deadline;

  final List<String> _availableIcons = [
    '📝', '🧹', '🍽️', '🛏️', '📚', '🎯', '🏃', '🎨',
    '🎵', '🌱', '🐕', '🚗', '💪', '🧘', '🍎', '💧',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.quest != null) {
      _nameController.text = widget.quest!.name;
      _descriptionController.text = widget.quest!.description ?? '';
      _pointsController.text = widget.quest!.rewardPoints.toString();
      _xpController.text = widget.quest!.rewardXP.toString();
      _selectedIcon = widget.quest!.icon;
      _selectedType = widget.quest!.type;
      _selectedRarity = widget.quest!.rarity;
      _assignedTo = List.from(widget.quest!.assignedTo);
      _deadline = widget.quest!.deadline;
      _unitController.text = widget.quest!.unit ?? '';
    } else {
      _pointsController.text = '10';
      _xpController.text = '100';
    }

    _pointsController.addListener(_updateXP);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    _xpController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _updateXP() {
    final points = int.tryParse(_pointsController.text) ?? 0;
    if (points > 0) {
      _xpController.text = (points * 10).toString();
    }
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _deadline = date;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final questProvider = context.read<QuestProvider>();
    final familyId = authProvider.currentFamily?.id;
    final userId = authProvider.currentUser?.id;

    if (familyId == null || userId == null) return;

    final quest = Quest(
      id: widget.quest?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      familyId: familyId,
      createdBy: userId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      icon: _selectedIcon,
      type: _selectedType,
      rarity: _selectedRarity,
      rewardPoints: int.parse(_pointsController.text),
      rewardXP: int.parse(_xpController.text),
      assignedTo: _assignedTo,
      deadline: _deadline,
      createdAt: widget.quest?.createdAt ?? DateTime.now(),
      unit: _selectedType == QuestType.series && _unitController.text.isNotEmpty
          ? _unitController.text.trim()
          : null,
    );

    final success = widget.quest == null
        ? await questProvider.createQuest(quest)
        : await questProvider.updateQuest(quest);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Speichern der Quest')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = context.watch<AuthProvider>().children;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quest == null ? 'Quest erstellen' : 'Quest bearbeiten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Icon Picker
            const Text('Icon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 8,
                ),
                itemCount: _availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = _availableIcons[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedIcon == icon
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          width: _selectedIcon == icon ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte Name eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Type
            const Text('Typ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: QuestType.values.map((type) {
                String label;
                switch (type) {
                  case QuestType.daily:
                    label = 'Daily';
                    break;
                  case QuestType.weekly:
                    label = 'Weekly';
                    break;
                  case QuestType.epic:
                    label = 'Epic';
                    break;
                  case QuestType.series:
                    label = 'Series';
                    break;
                }
                return ChoiceChip(
                  label: Text(label),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = type;
                      if (type != QuestType.epic) {
                        _deadline = null;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Rarity
            const Text('Seltenheit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: QuestRarity.values.map((rarity) {
                String label;
                Color color;
                switch (rarity) {
                  case QuestRarity.common:
                    label = 'Gewöhnlich';
                    color = const Color(0xFFB8B8B8);
                    break;
                  case QuestRarity.rare:
                    label = 'Selten';
                    color = const Color(0xFF4A9DFF);
                    break;
                  case QuestRarity.epic:
                    label = 'Episch';
                    color = const Color(0xFFA855F7);
                    break;
                  case QuestRarity.legendary:
                    label = 'Legendär';
                    color = const Color(0xFFF59E0B);
                    break;
                }
                return ChoiceChip(
                  label: Text(label),
                  selected: _selectedRarity == rarity,
                  selectedColor: color,
                  onSelected: (selected) {
                    setState(() => _selectedRarity = rarity);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Points and XP
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pointsController,
                    decoration: const InputDecoration(
                      labelText: 'Punkte',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final points = int.tryParse(value ?? '');
                      if (points == null || points <= 0) {
                        return 'Muss > 0 sein';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _xpController,
                    decoration: const InputDecoration(
                      labelText: 'XP',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final xp = int.tryParse(value ?? '');
                      if (xp == null || xp <= 0) {
                        return 'Muss > 0 sein';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Assign to children
            const Text('Zuweisen an', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Alle Kinder'),
                  selected: _assignedTo.isEmpty,
                  onSelected: (selected) {
                    setState(() => _assignedTo = []);
                  },
                ),
                ...children.map((child) {
                  return FilterChip(
                    label: Text(child.name),
                    selected: _assignedTo.contains(child.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _assignedTo.add(child.id);
                        } else {
                          _assignedTo.remove(child.id);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
            // Deadline for Epic quests
            if (_selectedType == QuestType.epic) ...[
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Deadline'),
                subtitle: _deadline != null
                    ? Text('${_deadline!.day}.${_deadline!.month}.${_deadline!.year}')
                    : const Text('Keine Deadline gesetzt'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDeadline,
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
            // Unit for Series quests
            if (_selectedType == QuestType.series) ...[
              const SizedBox(height: 24),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Einheit (z.B. km, Minuten, Stück)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
