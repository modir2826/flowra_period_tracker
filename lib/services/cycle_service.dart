import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cycle_model.dart';

class CycleService {
  final FirebaseDatabase _db;
  final FirebaseAuth _auth;

  CycleService({FirebaseDatabase? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DatabaseReference _userCyclesRef(String uid) => _db.ref('cycles/$uid');
  DatabaseReference _userRecentCyclesRef(String uid) => _db.ref('recent_cycles/$uid');

  Future<void> addCycle(CycleModel cycle) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final ref = _userCyclesRef(uid).push();
    final id = ref.key;
    final data = cycle.toJson()..['id'] = id;
    await ref.set(data);
  }

  Future<void> addRecentCycle(CycleModel cycle, {int limit = 5}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final ref = _userRecentCyclesRef(uid).push();
    final id = ref.key;
    final data = cycle.toJson()..['id'] = id;
    await ref.set(data);

    final snapshot = await _userRecentCyclesRef(uid).get();
    if (!snapshot.exists) return;
    final map = Map<String, dynamic>.from(snapshot.value as Map);
    final items = map.entries.map((e) {
      final m = Map<String, dynamic>.from(e.value as Map);
      m['id'] = e.key;
      final createdAt = m['createdAt'] != null
          ? DateTime.parse(m['createdAt'] as String)
          : DateTime.parse(m['startDate'] as String);
      return _RecentCycleEntry(id: e.key, createdAt: createdAt);
    }).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (items.length <= limit) return;

    final extras = items.sublist(limit);
    for (final extra in extras) {
      await _userRecentCyclesRef(uid).child(extra.id).remove();
    }
  }

  Future<void> updateCycle(CycleModel cycle) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    if (cycle.id == null) throw Exception('Cycle id required');

    await _userCyclesRef(uid).child(cycle.id!).update(cycle.toJson());
  }

  Future<void> deleteCycle(String id) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    await _userCyclesRef(uid).child(id).remove();
  }

  Future<List<CycleModel>> fetchCyclesOnce() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final snapshot = await _userCyclesRef(uid).get();
    if (!snapshot.exists) return [];

    final List<CycleModel> list = [];
    final map = Map<String, dynamic>.from(snapshot.value as Map);
    map.forEach((key, value) {
      final m = Map<String, dynamic>.from(value as Map);
      m['id'] = key;
      list.add(CycleModel.fromJson(m));
    });
    // sort by startDate descending
    list.sort((a, b) => b.startDate.compareTo(a.startDate));
    return list;
  }

  Stream<List<CycleModel>> streamCycles() {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final ref = _userCyclesRef(uid);
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return <CycleModel>[];
      final map = Map<String, dynamic>.from(snapshot.value as Map);
      final list = map.entries.map((e) {
        final m = Map<String, dynamic>.from(e.value as Map);
        m['id'] = e.key;
        return CycleModel.fromJson(m);
      }).toList();
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      return list;
    });
  }

  Stream<List<CycleModel>> streamRecentCycles({int limit = 5}) {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final ref = _userRecentCyclesRef(uid);
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists) return <CycleModel>[];
      final map = Map<String, dynamic>.from(snapshot.value as Map);
      final list = map.entries.map((e) {
        final m = Map<String, dynamic>.from(e.value as Map);
        m['id'] = e.key;
        return CycleModel.fromJson(m);
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (list.length > limit) {
        return list.sublist(0, limit);
      }
      return list;
    });
  }

  // Helper: average cycle length across provided cycles
  double averageCycleLength(List<CycleModel> cycles) {
    if (cycles.isEmpty) return 28.0;
    final total = cycles.map((c) => c.cycleLength).reduce((a, b) => a + b);
    return total / cycles.length;
  }

  // Predict next cycle start date using last cycle and average cycle length
  DateTime? predictNextCycleStart(List<CycleModel> cycles) {
    if (cycles.isEmpty) return null;
    final sorted = List<CycleModel>.from(cycles)..sort((a, b) => b.startDate.compareTo(a.startDate));
    final last = sorted.first;
    final avg = averageCycleLength(cycles);
    return last.startDate.add(Duration(days: avg.round()));
  }
}

class _RecentCycleEntry {
  final String id;
  final DateTime createdAt;

  _RecentCycleEntry({required this.id, required this.createdAt});
}
