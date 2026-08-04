import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:design_system/design_system.dart';
import 'package:shared/shared.dart';
import 'package:core/core.dart';

final _emergencyContactsProvider = FutureProvider.family<List<EmergencyContact>, String>((ref, patientId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/v1/patients/$patientId/emergency-contacts');
  return (response.data as List).map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>)).toList();
});

class EmergencyContactScreen extends ConsumerStatefulWidget {
  final String patientId;
  const EmergencyContactScreen({super.key, required this.patientId});

  @override
  ConsumerState<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends ConsumerState<EmergencyContactScreen> {
  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(_emergencyContactsProvider(widget.patientId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddDialog(context),
      ),
      body: contactsAsync.when(
        loading: () => const Center(child: AppLoading()),
        error: (e, _) => AppErrorState(title: 'Error', message: e.toString()),
        data: (contacts) {
          if (contacts.isEmpty) {
            return AppEmptyState(
              icon: Icons.emergency,
              title: 'No Emergency Contacts',
              message: 'Add emergency contacts for this patient',
              actionLabel: 'Add Contact',
              onAction: () => _showAddDialog(context),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(NeuroSpacing.md),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Padding(
                padding: EdgeInsets.only(bottom: NeuroSpacing.sm),
                child: AppCard(
                  child: Padding(
                    padding: EdgeInsets.all(NeuroSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?'),
                            ),
                            SizedBox(width: NeuroSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(contact.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                      if (contact.isPrimary) ...[
                                        SizedBox(width: NeuroSpacing.xs),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: NeuroColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(NeuroRadius.sm),
                                          ),
                                          child: Text('PRIMARY', style: TextStyle(fontSize: 9, color: NeuroColors.primary, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(contact.relationship, style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                              onSelected: (value) {
                                if (value == 'delete') _confirmDelete(contact);
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: NeuroSpacing.sm),
                        if (contact.phone != null) _contactRow(Icons.phone, contact.phone!),
                        if (contact.email != null) _contactRow(Icons.email, contact.email!),
                        if (contact.address != null) _contactRow(Icons.location_on, contact.address!),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(top: NeuroSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          SizedBox(width: NeuroSpacing.sm),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    bool isPrimary = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              SizedBox(height: NeuroSpacing.sm),
              TextField(controller: relCtrl, decoration: const InputDecoration(labelText: 'Relationship', border: OutlineInputBorder())),
              SizedBox(height: NeuroSpacing.sm),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
              SizedBox(height: NeuroSpacing.sm),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
              SizedBox(height: NeuroSpacing.sm),
              StatefulBuilder(
                builder: (context, setDialogState) => SwitchListTile(
                  title: const Text('Primary Contact'),
                  value: isPrimary,
                  onChanged: (v) => setDialogState(() => isPrimary = v),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameCtrl.text.isEmpty || relCtrl.text.isEmpty) return;
            try {
              final apiClient = ref.read(apiClientProvider);
              await apiClient.post('/v1/patients/${widget.patientId}/emergency-contacts', data: {
                'name': nameCtrl.text, 'relationship': relCtrl.text,
                'phone': phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                'email': emailCtrl.text.isEmpty ? null : emailCtrl.text,
                'isPrimary': isPrimary,
              });
              Navigator.pop(context);
              ref.invalidate(_emergencyContactsProvider(widget.patientId));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _confirmDelete(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Delete ${contact.name} as emergency contact?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: NeuroColors.critical),
            onPressed: () async {
              try {
                final apiClient = ref.read(apiClientProvider);
                await apiClient.delete('/v1/patients/${widget.patientId}/emergency-contacts/${contact.id}');
                Navigator.pop(context);
                ref.invalidate(_emergencyContactsProvider(widget.patientId));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: NeuroColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
