import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cycle_model.dart';

class CycleService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DatabaseReference _userCyclesRef(String uid) => _db.ref('cycles/$uid');

  Future<void> addCycle(CycleModel cycle) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');

    final ref = _userCyclesRef(uid).push();
    final id = ref.key;
    final data = cycle.toJson()..['id'] = id;
    await ref.set(data);
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
    // sort by lastPeriodDate descending
    list.sort((a, b) => b.lastPeriodDate.compareTo(a.lastPeriodDate));
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
      list.sort((a, b) => b.lastPeriodDate.compareTo(a.lastPeriodDate));
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
    final sorted = List<CycleModel>.from(cycles)..sort((a, b) => b.lastPeriodDate.compareTo(a.lastPeriodDate));
    final last = sorted.first;
    final avg = averageCycleLength(cycles);
    return last.lastPeriodDate.add(Duration(days: avg.round()));
  }
}
