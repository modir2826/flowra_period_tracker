import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Backend base URL for sync
const String _backendBase = 'http://localhost:8000';

class ContactsService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DatabaseReference _userContactsRef(String uid) => _db.ref('contacts/$uid');

  Future<void> addContact(ContactModel c) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final ref = _userContactsRef(uid).push();
    final id = ref.key;
    final data = c.toJson()..['id'] = id;
    await ref.set(data);
  }

  Future<void> updateContact(ContactModel c) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    if (c.id == null) throw Exception('Contact id required');
    await _userContactsRef(uid).child(c.id!).update(c.toJson());
  }

  Future<void> deleteContact(String id) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    await _userContactsRef(uid).child(id).remove();
  }

  Future<List<ContactModel>> fetchContactsOnce() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final snapshot = await _userContactsRef(uid).get();
    if (!snapshot.exists) return [];
    final map = Map<String, dynamic>.from(snapshot.value as Map);
    final list = <ContactModel>[];
    map.forEach((key, value) {
      final m = Map<String, dynamic>.from(value as Map);
      m['id'] = key;
      list.add(ContactModel.fromJson(m));
    });
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Stream<List<ContactModel>> streamContacts() {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final ref = _userContactsRef(uid);
    return ref.onValue.map((event) {
      final snap = event.snapshot;
      if (!snap.exists) return <ContactModel>[];
      final map = Map<String, dynamic>.from(snap.value as Map);
      final list = map.entries.map((e) {
        final m = Map<String, dynamic>.from(e.value as Map);
        m['id'] = e.key;
        return ContactModel.fromJson(m);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Push trusted contacts to server (replace)
  Future<void> pushTrustedToServer() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final contacts = await fetchContactsOnce();
    final trusted = contacts.where((c) => c.trusted).map((c) => c.toJson()).toList();
    final url = Uri.parse('$_backendBase/trusted/$uid');
    await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(trusted));
  }

  // Fetch trusted contacts from server and merge locally (replace if ids differ)
  Future<void> pullTrustedFromServer() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final url = Uri.parse('$_backendBase/trusted/$uid');
    final resp = await http.get(url);
    if (resp.statusCode != 200) throw Exception('Failed to fetch trusted contacts');
    final List<dynamic> data = jsonDecode(resp.body) as List<dynamic>;
    for (final item in data) {
      final map = Map<String, dynamic>.from(item as Map);
      final contact = ContactModel.fromJson(map);
      // Add or update locally: naive approach - add as new item
      await addContact(contact);
    }
  }
}
