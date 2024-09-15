import 'package:flutter/material.dart';
import '../models/challenge.dart';

class ChallengesView extends StatelessWidget {
  final List<Challenge> challenges;
  final Function(Challenge) onEdit;
  final Function(Challenge) onDelete;
  final VoidCallback onAdd;

  const ChallengesView({
    Key? key,
    required this.challenges,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          return ListTile(
            leading: Icon(challenge.icon),
            title: Text(challenge.name),
            subtitle: Text('${challenge.reward} Punkte'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => onEdit(challenge),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => onDelete(challenge),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        child: Icon(Icons.add),
      ),
    );
  }
}
