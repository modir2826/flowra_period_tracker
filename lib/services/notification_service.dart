import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact_model.dart';

class NotificationService {
  final String baseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  NotificationService({this.baseUrl = 'http://localhost:8000'});

  String? get _uid => _auth.currentUser?.uid;

  Future<Map<String, dynamic>> triggerSos(List<ContactModel> contacts, {String? message}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final url = Uri.parse('$baseUrl/sos/$uid');
    final body = {'contacts': contacts.map((c) => c.toJson()).toList(), 'message': message};
    final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (resp.statusCode != 200) throw Exception('SOS server error: ${resp.body}');
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
