import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reward.dart';
import '../../models/enums.dart';
import '../../providers/reward_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/error_state.dart';
import '../../widgets/glass_scaffold.dart';

class RewardEditPage extends StatefulWidget {
  final Reward? reward;

  const RewardEditPage({super.key, this.reward});

  @override
  State<RewardEditPage> createState() => _RewardEditPageState();
}

class _RewardEditPageState extends State<RewardEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  String _selectedIcon = '🎁';
  RewardCategory _selectedCategory = RewardCategory.item;
  bool _isActive = true;

  bool get isEditing => widget.reward != null;

  static const List<String> _availableIcons = [
    '🎁', '🎮', '🍕', '🍦', '🎬', '📱', '🎨', '🎵',
    '⚽', '🏀', '🎯', '🎪', '🎢', '🏊', '🚴', '⭐',
    '💎', '🎈', '🎉', '🎊', '🏆', '👑', '🦸', '🌟',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.reward?.name ?? '');
    _descriptionController = TextEditingController(text: widget.reward?.description ?? '');
    _priceController = TextEditingController(
      text: widget.reward?.price.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.reward?.stock?.toString() ?? '',
    );

    if (widget.reward != null) {
      _selectedIcon = widget.reward!.icon;
      _selectedCategory = widget.reward!.category;
      _isActive = widget.reward!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Belohnung bearbeiten' : 'Neue Belohnung'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveReward,
            child: const Text('Speichern'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Icon picker
            Center(
              child: GestureDetector(
                onTap: _showIconPicker,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _selectedIcon,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tippe zum Ändern',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'z.B. Extra Bildschirmzeit',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name ist erforderlich';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'Optional',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Preis (Punkte) *',
                hintText: 'z.B. 50',
                border: OutlineInputBorder(),
                prefixText: '✨ ',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Preis ist erforderlich';
                }
                final price = int.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Bitte gib eine gültige Zahl ein';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<RewardCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                border: OutlineInputBorder(),
              ),
              items: RewardCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryLabel(category)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _selectedCategory = value;
                }
              },
            ),
            const SizedBox(height: 16),

            // Stock
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Anzahl verfügbar',
                hintText: 'Leer = Unbegrenzt',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final stock = int.tryParse(value);
                  if (stock == null || stock < 0) {
                    return 'Bitte gib eine gültige Zahl ein';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Active toggle
            SwitchListTile(
              title: const Text('Aktiv'),
              subtitle: const Text('Inaktive Belohnungen werden nicht im Shop angezeigt'),
              value: _isActive,
              onChanged: (value) {
                setState(() => _isActive = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Icon auswählen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableIcons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIcon = icon);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : AppColors.textSecondary.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(RewardCategory category) {
    switch (category) {
      case RewardCategory.experience:
        return '🎉 Erlebnis';
      case RewardCategory.item:
        return '🎁 Sache';
      case RewardCategory.privilege:
        return '⭐ Privileg';
      case RewardCategory.custom:
        return '✨ Spezial';
    }
  }

  Future<void> _saveReward() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final rewardProvider = context.read<RewardProvider>();

    final userId = authProvider.currentUser?.id ?? '';
    final familyId = authProvider.currentUser?.familyId ?? '';

    final reward = Reward(
      id: widget.reward?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      familyId: familyId,
      createdBy: widget.reward?.createdBy ?? userId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      icon: _selectedIcon,
      price: int.parse(_priceController.text.trim()),
      category: _selectedCategory,
      stock: _stockController.text.trim().isEmpty
          ? null
          : int.parse(_stockController.text.trim()),
      isActive: _isActive,
      createdAt: widget.reward?.createdAt ?? DateTime.now(),
    );

    if (isEditing) {
      await rewardProvider.updateReward(reward);
    } else {
      await rewardProvider.createReward(reward);
    }

    if (mounted) {
      Navigator.pop(context);
      AppSnackbar.success(context, isEditing ? 'Belohnung aktualisiert' : 'Belohnung erstellt');
    }
  }
}
