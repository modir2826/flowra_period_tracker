import 'package:firebase_database/firebase_database.dart';

class UserService {
  final _db = FirebaseDatabase.instance.ref();

  Future<void> saveUser({
    required String uid,
    required String email,
    required String name,
  }) async {
    await _db.child('users/$uid').set({
      'email': email,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
