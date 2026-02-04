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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SosScreen()));
        },
        backgroundColor: Colors.red.shade600,
        icon: const Icon(Icons.emergency, color: Colors.white),
        label: const Text('Emergency SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<ContactModel>>(
        stream: _service.streamContacts(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('No trusted contacts yet'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final c = items[i];
              return ListTile(
                title: Text(c.name),
                subtitle: Text('${c.relation} · ${c.phone}'),
                leading: IconButton(
                  icon: Icon(c.trusted ? Icons.star : Icons.star_border, color: c.trusted ? Colors.amber : Colors.grey),
                  onPressed: () async {
                    final updated = ContactModel(id: c.id, name: c.name, phone: c.phone, relation: c.relation, trusted: !c.trusted, createdAt: c.createdAt);
                    await _service.updateContact(updated);
                  },
                ),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: () => _showAddDialog(c)),
                  IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { if (c.id != null) await _service.deleteContact(c.id!); }),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
