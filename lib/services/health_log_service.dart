import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/health_log_model.dart';

class HealthLogService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DatabaseReference _userLogsRef(String uid) => _db.ref('health_logs/$uid');

  Future<void> addLog(HealthLogModel log) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final ref = _userLogsRef(uid).push();
    final id = ref.key;
    final data = log.toJson()..['id'] = id;
    await ref.set(data);
  }

  Future<void> deleteLog(String id) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    await _userLogsRef(uid).child(id).remove();
  }

  Future<List<HealthLogModel>> fetchLogsOnce() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final snapshot = await _userLogsRef(uid).get();
    if (!snapshot.exists) return [];

    final list = <HealthLogModel>[];
    final map = Map<String, dynamic>.from(snapshot.value as Map);
    map.forEach((key, value) {
      final m = Map<String, dynamic>.from(value as Map);
      m['id'] = key;
      list.add(HealthLogModel.fromJson(m));
    });
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Stream<List<HealthLogModel>> streamLogs() {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final ref = _userLogsRef(uid);
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return <HealthLogModel>[];
      final map = Map<String, dynamic>.from(snapshot.value as Map);
      final list = map.entries.map((e) {
        final m = Map<String, dynamic>.from(e.value as Map);
        m['id'] = e.key;
        return HealthLogModel.fromJson(m);
      }).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }
}
