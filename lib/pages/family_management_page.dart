import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enums.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_scaffold.dart';

class FamilyManagementPage extends StatelessWidget {
  const FamilyManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: const GlassAppBar(
        title: Text('Familie verwalten'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'family_add_fab',
        onPressed: () => _showAddMemberDialog(context),
        child: const Icon(Icons.person_add),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final family = authProvider.currentFamily;
            final members = authProvider.familyMembers;

            return ListView(
              padding:
                  const EdgeInsets.fromLTRB(16, kToolbarHeight + 24, 16, 80),
              children: [
                // Family name header
                if (family != null)
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.family_restroom,
                          color: AppColors.teal,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Familie ${family.name}',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Parents section
                _buildSectionHeader('Eltern'),
                const SizedBox(height: 8),
                ...authProvider.parents.map(
                  (parent) => _buildMemberTile(context, parent.name, 'Elternteil',
                      Icons.shield, AppColors.gold),
                ),
                if (authProvider.parents.isEmpty)
                  _buildEmptyHint('Noch keine Eltern hinzugefügt'),
                const SizedBox(height: 16),

                // Children section
                _buildSectionHeader('Kinder'),
                const SizedBox(height: 8),
                ...authProvider.children.map(
                  (child) => _buildMemberTile(context, child.name, 'Mochi Hero',
                      Icons.emoji_events, AppColors.teal),
                ),
                if (authProvider.children.isEmpty)
                  _buildEmptyHint('Noch keine Kinder hinzugefügt'),

                const SizedBox(height: 16),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${members.length} Familienmitglieder',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    String name,
    String role,
    IconData icon,
    Color color,
  ) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 12,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(51),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          role,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHint(String text) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final pinController = TextEditingController();
    UserRole selectedRole = UserRole.child;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text(
                'Mitglied hinzufügen',
                style: TextStyle(color: AppColors.text),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.white.withAlpha(51)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.teal),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedRole,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      labelText: 'Rolle',
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.white.withAlpha(51)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.teal),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.child,
                        child: Text('Kind'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.parent,
                        child: Text('Elternteil'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedRole = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    style: const TextStyle(color: AppColors.text),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      labelText: 'PIN (optional)',
                      helperText: '4-stellig',
                      helperStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      labelStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      counterStyle:
                          const TextStyle(color: AppColors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.white.withAlpha(51)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.teal),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Abbrechen',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final pin = pinController.text.trim();
                    await context.read<AuthProvider>().addMember(
                          name,
                          selectedRole,
                          pin: pin.length == 4 ? pin : null,
                        );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Hinzufügen'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
