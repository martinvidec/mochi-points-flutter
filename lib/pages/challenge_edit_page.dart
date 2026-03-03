import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../theme/app_colors.dart';
import '../widgets/error_state.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_scaffold.dart';

class ChallengeEditPage extends StatefulWidget {
  final Function(Challenge) onSave;
  final Challenge? challenge;

  const ChallengeEditPage({super.key, required this.onSave, this.challenge});

  @override
  State<ChallengeEditPage> createState() => _ChallengeEditPageState();
}

class _ChallengeEditPageState extends State<ChallengeEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _rewardController;
  IconData _selectedIcon = Icons.star;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.challenge?.name ?? '');
    _rewardController = TextEditingController(text: widget.challenge?.reward.toString() ?? '');
    _selectedIcon = widget.challenge?.icon ?? Icons.star;
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(widget.challenge == null ? 'Neue Challenge' : 'Challenge bearbeiten'),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + kToolbarHeight + 16, 16, 16,
        ),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _rewardController,
              decoration: InputDecoration(labelText: 'Belohnung'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            DropdownButton<IconData>(
              value: _selectedIcon,
              dropdownColor: AppColors.surface.withAlpha(230),
              onChanged: (IconData? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedIcon = newValue;
                  });
                }
              },
              items: [
                DropdownMenuItem(value: Icons.star, child: Icon(Icons.star)),
                DropdownMenuItem(value: Icons.favorite, child: Icon(Icons.favorite)),
                DropdownMenuItem(value: Icons.emoji_events, child: Icon(Icons.emoji_events)),
                // Add more icons as needed
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final name = _nameController.text;
          final reward = double.tryParse(_rewardController.text) ?? 0.0;
          if (name.isNotEmpty && reward > 0) {
            final challenge = Challenge(
              id: widget.challenge?.id ?? DateTime.now().toString(),
              name: name,
              icon: _selectedIcon,
              reward: reward,
            );
            widget.onSave(challenge);
            Navigator.of(context).pop();
          } else {
            // Show an error message
            AppSnackbar.error(context, 'Bitte füllen Sie alle Felder korrekt aus.');
          }
        },
        child: Icon(Icons.save),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rewardController.dispose();
    super.dispose();
  }
}
