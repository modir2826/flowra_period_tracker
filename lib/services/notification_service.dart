import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact_model.dart';

class NotificationService {
  final String baseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  NotificationService({this.baseUrl = 'http://127.0.0.1:8001'});

  String? get _uid => _auth.currentUser?.uid;

  Future<Map<String, dynamic>> triggerSos(List<ContactModel> contacts, {String? message, double? latitude, double? longitude}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final url = Uri.parse('$baseUrl/sos/$uid');
    final body = <String, dynamic>{
      'contacts': contacts.map((c) => c.toJson()).toList(),
      'message': message,
    };
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (resp.statusCode != 200) throw Exception('SOS server error: ${resp.body}');
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
