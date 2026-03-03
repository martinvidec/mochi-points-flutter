import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/hero.dart' as app;
import '../../providers/auth_provider.dart';
import '../../providers/hero_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/error_state.dart';
import '../../widgets/glass_scaffold.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/hero_card.dart';

class HeroCustomizationPage extends StatefulWidget {
  final app.Hero hero;

  const HeroCustomizationPage({super.key, required this.hero});

  @override
  State<HeroCustomizationPage> createState() => _HeroCustomizationPageState();
}

class _HeroCustomizationPageState extends State<HeroCustomizationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  late String _skinColor;
  late String _hairStyle;
  late String _hairColor;
  late String _outfit;
  late String? _accessory;
  late String? _pet;

  static const _skinColors = ['light', 'medium', 'dark'];
  static const _skinColorLabels = {'light': 'Hell', 'medium': 'Mittel', 'dark': 'Dunkel'};
  static const _skinColorValues = {
    'light': Color(0xFFFFDBB4),
    'medium': Color(0xFFD4A574),
    'dark': Color(0xFF8B6F47),
  };

  static const _hairStyles = ['short', 'long', 'curly', 'braids'];
  static const _hairStyleLabels = {
    'short': 'Kurz',
    'long': 'Lang',
    'curly': 'Lockig',
    'braids': 'Zopf',
  };

  static const _hairColors = ['brown', 'blond', 'black', 'red'];
  static const _hairColorLabels = {
    'brown': 'Braun',
    'blond': 'Blond',
    'black': 'Schwarz',
    'red': 'Rot',
  };
  static const _hairColorValues = {
    'brown': Color(0xFF6B3A2A),
    'blond': Color(0xFFE8D44D),
    'black': Color(0xFF2C2C2C),
    'red': Color(0xFFB5452A),
  };

  static const _outfits = ['casual', 'sporty', 'fancy', 'adventurer'];
  static const _outfitLabels = {
    'casual': 'Casual',
    'sporty': 'Sportlich',
    'fancy': 'Schick',
    'adventurer': 'Abenteurer',
  };

  static const _accessories = [null, 'glasses', 'hat', 'scarf'];
  static const _accessoryLabels = {
    null: 'Keins',
    'glasses': 'Brille',
    'hat': 'Hut',
    'scarf': 'Schal',
  };

  static const _pets = [null, 'cat', 'dog', 'dragon'];
  static const _petLabels = {
    null: 'Keins',
    'cat': 'Katze',
    'dog': 'Hund',
    'dragon': 'Drache',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hero.name);
    _skinColor = widget.hero.appearance.skinColor;
    _hairStyle = widget.hero.appearance.hairStyle;
    _hairColor = widget.hero.appearance.hairColor;
    _outfit = widget.hero.appearance.outfit;
    _accessory = widget.hero.appearance.accessory;
    _pet = widget.hero.appearance.pet;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  app.HeroAppearance get _currentAppearance => app.HeroAppearance(
        baseAvatar: widget.hero.appearance.baseAvatar,
        skinColor: _skinColor,
        hairStyle: _hairStyle,
        hairColor: _hairColor,
        outfit: _outfit,
        accessory: _accessory,
        pet: _pet,
      );

  app.Hero get _previewHero => widget.hero.copyWith(
        name: _nameController.text.isEmpty ? widget.hero.name : _nameController.text,
        appearance: _currentAppearance,
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final success = await context.read<HeroProvider>().updateHero(
          userId,
          name: _nameController.text.trim(),
          appearance: _currentAppearance,
        );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        AppSnackbar.error(context, 'Fehler beim Speichern');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: const Text('Hero anpassen'),
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
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            16,
            16,
          ),
          children: [
            // Live Preview
            HeroCard(hero: _previewHero, compact: true),
            const SizedBox(height: 12),

            // Hero Name
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hero Name',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      hintText: 'Name deines Helden',
                      hintStyle: TextStyle(color: Colors.white.withAlpha(102)),
                      filled: true,
                      fillColor: Colors.white.withAlpha(13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withAlpha(51)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withAlpha(51)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.teal),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitte gib einen Namen ein';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Skin Color
            _buildChoiceSection(
              title: 'Hautfarbe',
              children: _skinColors.map((value) {
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _skinColorValues[value],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(128)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_skinColorLabels[value]!),
                    ],
                  ),
                  selected: _skinColor == value,
                  onSelected: (selected) {
                    if (selected) setState(() => _skinColor = value);
                  },
                  selectedColor: AppColors.teal.withAlpha(77),
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: _skinColor == value ? AppColors.teal : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: _skinColor == value ? AppColors.teal : Colors.white.withAlpha(51),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Hair Style
            _buildChoiceSection(
              title: 'Frisur',
              children: _hairStyles.map((value) {
                return ChoiceChip(
                  label: Text(_hairStyleLabels[value]!),
                  selected: _hairStyle == value,
                  onSelected: (selected) {
                    if (selected) setState(() => _hairStyle = value);
                  },
                  selectedColor: AppColors.teal.withAlpha(77),
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: _hairStyle == value ? AppColors.teal : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: _hairStyle == value ? AppColors.teal : Colors.white.withAlpha(51),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Hair Color
            _buildChoiceSection(
              title: 'Haarfarbe',
              children: _hairColors.map((value) {
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _hairColorValues[value],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(128)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_hairColorLabels[value]!),
                    ],
                  ),
                  selected: _hairColor == value,
                  onSelected: (selected) {
                    if (selected) setState(() => _hairColor = value);
                  },
                  selectedColor: AppColors.teal.withAlpha(77),
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: _hairColor == value ? AppColors.teal : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: _hairColor == value ? AppColors.teal : Colors.white.withAlpha(51),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Outfit
            _buildChoiceSection(
              title: 'Outfit',
              children: _outfits.map((value) {
                return ChoiceChip(
                  label: Text(_outfitLabels[value]!),
                  selected: _outfit == value,
                  onSelected: (selected) {
                    if (selected) setState(() => _outfit = value);
                  },
                  selectedColor: AppColors.teal.withAlpha(77),
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: _outfit == value ? AppColors.teal : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: _outfit == value ? AppColors.teal : Colors.white.withAlpha(51),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Accessory
            _buildChoiceSection(
              title: 'Accessoire',
              children: _accessories.map((value) {
                return ChoiceChip(
                  label: Text(_accessoryLabels[value]!),
                  selected: _accessory == value,
                  onSelected: (selected) {
                    if (selected) setState(() => _accessory = value);
                  },
                  selectedColor: AppColors.teal.withAlpha(77),
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: _accessory == value ? AppColors.teal : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: _accessory == value ? AppColors.teal : Colors.white.withAlpha(51),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Pet
            _buildChoiceSection(
              title: 'Haustier',
              children: _pets.map((value) {
                return ChoiceChip(
                  label: Text(_petLabels[value]!),
                  selected: _pet == value,
                  onSelected: (selected) {
                    if (selected) setState(() => _pet = value);
                  },
                  selectedColor: AppColors.teal.withAlpha(77),
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: _pet == value ? AppColors.teal : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: _pet == value ? AppColors.teal : Colors.white.withAlpha(51),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceSection({
    required String title,
    required List<Widget> children,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children,
          ),
        ],
      ),
    );
  }
}
