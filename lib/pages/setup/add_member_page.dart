import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../widgets/app_button.dart';

class MemberData {
  final String name;
  final UserRole role;
  final String? pin;

  MemberData({
    required this.name,
    required this.role,
    this.pin,
  });
}

class AddMemberPage extends StatefulWidget {
  final bool isFirstParent;

  const AddMemberPage({
    super.key,
    this.isFirstParent = false,
  });

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  UserRole _selectedRole = UserRole.child;

  @override
  void initState() {
    super.initState();
    if (widget.isFirstParent) {
      _selectedRole = UserRole.parent;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final memberData = MemberData(
        name: _nameController.text.trim(),
        role: _selectedRole,
        pin: _pinController.text.isNotEmpty ? _pinController.text : null,
      );
      Navigator.of(context).pop(memberData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstParent ? 'Elternteil erstellen' : 'Mitglied hinzufügen'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 24),
                if (!widget.isFirstParent) ...[
                  const Text(
                    'Rolle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.parent,
                        label: Text('Eltern'),
                        icon: Icon(Icons.person),
                      ),
                      ButtonSegment(
                        value: UserRole.child,
                        label: Text('Kind'),
                        icon: Icon(Icons.child_care),
                      ),
                    ],
                    selected: {_selectedRole},
                    onSelectionChanged: (Set<UserRole> newSelection) {
                      setState(() {
                        _selectedRole = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                TextFormField(
                  controller: _pinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN (optional)',
                    border: OutlineInputBorder(),
                    helperText: '4-stellige PIN für mehr Sicherheit',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length != 4) {
                      return 'PIN muss 4 Ziffern haben';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                AppButton.primary(
                  onPressed: _save,
                  label: 'Speichern',
                  expanded: true,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
