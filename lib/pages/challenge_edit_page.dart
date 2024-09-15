import 'package:flutter/material.dart';
import '../models/challenge.dart';

class ChallengeEditPage extends StatefulWidget {
  final Function(Challenge) onSave;
  final Challenge? challenge;

  ChallengeEditPage({Key? key, required this.onSave, this.challenge}) : super(key: key);

  @override
  _ChallengeEditPageState createState() => _ChallengeEditPageState();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challenge == null ? 'Neue Challenge' : 'Challenge bearbeiten'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Bitte füllen Sie alle Felder korrekt aus.')),
            );
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
