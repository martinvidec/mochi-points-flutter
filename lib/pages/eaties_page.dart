import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/eaty_provider.dart';
import '../models/eaty.dart';

class EatiesPage extends StatelessWidget {
  const EatiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final eatyProvider = Provider.of<EatyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Eaties'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              _addNewEaty(context); // Pass context to the method
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: eatyProvider.eaties.length,
        itemBuilder: (context, index) {
          final eaty = eatyProvider.eaties[index];
          return ListTile(
            title: Text(eaty.name),
            subtitle: Text('${eaty.price} Punkte'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _deleteEaty(context, eaty); // Pass context to the method
              },
            ),
          );
        },
      ),
    );
  }

  void _addNewEaty(BuildContext context) { // Pass context as a parameter
    final eatyProvider = Provider.of<EatyProvider>(context, listen: false); // Get the EatyProvider

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newName = '';
        double newPrice = 0;
        String errorText = '';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Neues Eaty hinzufügen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Name'),
                    onChanged: (value) => newName = value,
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Preis',
                      errorText: errorText.isNotEmpty ? errorText : null,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        final parsed = double.tryParse(value);
                        if (parsed != null && parsed > 0) {
                          newPrice = parsed;
                          errorText = '';
                        } else {
                          newPrice = 0;
                          errorText = 'Bitte geben Sie einen gültigen Preis ein';
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Abbrechen'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Hinzufügen'),
                  onPressed: () {
                    if (newName.isNotEmpty && newPrice > 0) {
                      Navigator.of(context).pop();
                      // Use the EatyProvider to add the new Eaty
                      eatyProvider.addEaty(Eaty(newName, newPrice));
                    } else {
                      setState(() {
                        errorText = 'Bitte geben Sie einen Namen und einen gültigen Preis ein';
                      });
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteEaty(BuildContext context, Eaty eaty) { // Pass context as a parameter
    final eatyProvider = Provider.of<EatyProvider>(context, listen: false); // Get the EatyProvider

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eaty löschen'),
          content: Text('Möchten Sie "${eaty.name}" wirklich löschen?'),
          actions: [
            TextButton(
              child: Text('Abbrechen'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Löschen'),
              onPressed: () {
                Navigator.of(context).pop();
                // Remove the Eaty from the provider
                eatyProvider.removeEaty(eaty);
              },
            ),
          ],
        );
      },
    );
  }
  
}
