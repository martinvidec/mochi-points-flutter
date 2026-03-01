import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/enums.dart';
import 'add_member_page.dart';

class FamilySetupPage extends StatefulWidget {
  const FamilySetupPage({super.key});

  @override
  State<FamilySetupPage> createState() => _FamilySetupPageState();
}

class _FamilySetupPageState extends State<FamilySetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  int _currentStep = 0;
  final List<MemberData> _members = [];
  MemberData? _firstParent;

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  Future<void> _addFirstParent() async {
    final result = await Navigator.of(context).push<MemberData>(
      MaterialPageRoute(
        builder: (context) => const AddMemberPage(isFirstParent: true),
      ),
    );

    if (result != null) {
      setState(() {
        _firstParent = result;
      });
    }
  }

  Future<void> _addMember() async {
    final result = await Navigator.of(context).push<MemberData>(
      MaterialPageRoute(
        builder: (context) => const AddMemberPage(),
      ),
    );

    if (result != null) {
      setState(() {
        _members.add(result);
      });
    }
  }

  void _removeMember(int index) {
    setState(() {
      _members.removeAt(index);
    });
  }

  Future<void> _finishSetup() async {
    final authProvider = context.read<AuthProvider>();

    // Create family
    final familyCreated = await authProvider.createFamily(
      _familyNameController.text.trim(),
    );

    if (!familyCreated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Erstellen der Familie')),
        );
      }
      return;
    }

    // Add first parent
    if (_firstParent != null) {
      await authProvider.addMember(
        _firstParent!.name,
        _firstParent!.role,
        pin: _firstParent!.pin,
      );
    }

    // Add other members
    for (final member in _members) {
      await authProvider.addMember(
        member.name,
        member.role,
        pin: member.pin,
      );
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Familie einrichten'),
      ),
      body: SafeArea(
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _currentStep = 1;
                });
              }
            } else if (_currentStep == 1) {
              if (_firstParent != null) {
                setState(() {
                  _currentStep = 2;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bitte einen Elternteil erstellen'),
                  ),
                );
              }
            } else if (_currentStep == 2) {
              _finishSetup();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          steps: [
            Step(
              title: const Text('Familienname'),
              content: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _familyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Familienname',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte Familiennamen eingeben';
                    }
                    return null;
                  },
                ),
              ),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Elternteil erstellen'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_firstParent == null)
                    ElevatedButton.icon(
                      onPressed: _addFirstParent,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Elternteil erstellen'),
                    )
                  else
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(_firstParent!.name),
                        subtitle: const Text('Eltern'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _addFirstParent,
                        ),
                      ),
                    ),
                ],
              ),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Weitere Mitglieder'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addMember,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Mitglied hinzufügen'),
                  ),
                  const SizedBox(height: 16),
                  ..._members.asMap().entries.map((entry) {
                    final index = entry.key;
                    final member = entry.value;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            member.role == UserRole.parent
                                ? Icons.person
                                : Icons.child_care,
                          ),
                        ),
                        title: Text(member.name),
                        subtitle: Text(
                          member.role == UserRole.parent ? 'Eltern' : 'Kind',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeMember(index),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              isActive: _currentStep >= 2,
            ),
          ],
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 2 ? 'Fertig' : 'Weiter'),
                  ),
                  const SizedBox(width: 8),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Zurück'),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
