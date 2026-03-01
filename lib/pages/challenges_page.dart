import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/challenge.dart';
import '../providers/challenge_provider.dart';
import '../views/challenges_view.dart';
import 'challenge_edit_page.dart';

class ChallengesPage extends StatelessWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final challengeProvider = Provider.of<ChallengeProvider>(context);

    void addNewChallenge() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChallengeEditPage(
            onSave: (Challenge newChallenge) {
              challengeProvider.addChallenge(newChallenge);
            },
          ),
        ),
      );
    }

    void editChallenge(Challenge challenge) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChallengeEditPage(
            challenge: challenge,
            onSave: (Challenge updatedChallenge) {
              challengeProvider.updateChallenge(updatedChallenge);
            },
          ),
        ),
      );
    }

    void deleteChallenge(Challenge challenge) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Challenge löschen'),
            content: Text('Möchten Sie "${challenge.name}" wirklich löschen?'),
            actions: [
              TextButton(
                child: Text('Abbrechen'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text('Löschen'),
                onPressed: () {
                  Navigator.of(context).pop();
                  challengeProvider.deleteChallenge(challenge.id);
                },
              ),
            ],
          );
        },
      );
    }

    return ChallengesView(
      challenges: challengeProvider.challenges,
      onEdit: editChallenge,
      onDelete: deleteChallenge,
      onAdd: addNewChallenge,
    );
  }
}
