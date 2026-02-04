import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../models/contact_model.dart';
import '../services/contacts_service.dart';
import 'sos_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactsService _service = ContactsService();

  void _showAddDialog([ContactModel? existing]) {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final phoneCtl = TextEditingController(text: existing?.phone ?? '');
    final relationCtl = TextEditingController(text: existing?.relation ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Contact' : 'Edit Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phoneCtl, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: relationCtl, decoration: const InputDecoration(labelText: 'Relation')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final name = nameCtl.text.trim();
              final phone = phoneCtl.text.trim();
              final rel = relationCtl.text.trim();
              if (name.isEmpty || phone.isEmpty) return;
              final model = ContactModel(id: existing?.id, name: name, phone: phone, relation: rel);
              if (existing == null) {
                await _service.addContact(model);
              } else {
                await _service.updateContact(model);
              }
              navigator.pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Future<void> _importDeviceContacts() async {
    final messenger = ScaffoldMessenger.of(context);
    final permission = await fc.FlutterContacts.requestPermission();
    if (!permission) {
      messenger.showSnackBar(const SnackBar(content: Text('Contacts permission denied')));
      return;
    }
    final deviceContacts = await fc.FlutterContacts.getContacts(withProperties: true);
    int added = 0;
    final existing = await _service.fetchContactsOnce();
    final existingPhones = existing.map((e) => e.phone.replaceAll(RegExp(r'\s+'), '')).toSet();
    for (final dc in deviceContacts) {
      final phones = dc.phones;
      if (phones.isEmpty) continue;
      final name = dc.displayName;
      final phoneRaw = phones.first.number;
      final phone = phoneRaw.replaceAll(RegExp(r'\s+'), '');
      if (existingPhones.contains(phone)) continue; // dedupe by phone
      final model = ContactModel(name: name, phone: phone);
      await _service.addContact(model);
      added++;
    }
    messenger.showSnackBar(SnackBar(content: Text('Imported $added contacts')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync trusted list',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _service.pushTrustedToServer();
                await _service.pullTrustedFromServer();
                messenger.showSnackBar(const SnackBar(content: Text('Synced trusted contacts')));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Sync failed: $e')));
              }
            },
          )
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_contact',
            onPressed: () => _showAddDialog(),
            backgroundColor: Colors.pink.shade500,
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'emergency_sos',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SosScreen()));
            },
            backgroundColor: Colors.red.shade600,
            icon: const Icon(Icons.emergency, color: Colors.white),
            label: const Text('Emergency SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: StreamBuilder<List<ContactModel>>(
        stream: _service.streamContacts(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No trusted contacts yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Tap the + button to add your first contact', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final c = items[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(c.relation.isNotEmpty ? c.relation : 'Contact', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      Text(c.phone, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.trusted ? Colors.pink.shade100 : Colors.grey.shade200,
                    ),
                    child: Center(
                      child: Icon(
                        c.trusted ? Icons.star : Icons.person,
                        color: c.trusted ? Colors.pink : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        child: const Text('Toggle Trusted'),
                        onTap: () async {
                          final updated = ContactModel(
                            id: c.id,
                            name: c.name,
                            phone: c.phone,
                            relation: c.relation,
                            trusted: !c.trusted,
                            createdAt: c.createdAt,
                          );
                          await _service.updateContact(updated);
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: () => _showAddDialog(c),
                      ),
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () async {
                          if (c.id != null) {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Contact?'),
                                content: Text('Remove ${c.name}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await _service.deleteContact(c.id!);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
