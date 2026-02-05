import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowra/services/cycle_service.dart';
import 'package:flowra/models/cycle_model.dart';

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  setUpAll(() {
    // No global fallback values required for these mocks here.
  });

  test('addCycle pushes data with generated id', () async {
    final mockDb = MockFirebaseDatabase();
    final mockRef = MockDatabaseReference();
    final mockPushRef = MockDatabaseReference();
    final mockAuth = MockFirebaseAuth();
    final mockUser = MockUser();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('uid123');

    when(() => mockDb.ref('cycles/uid123')).thenReturn(mockRef);
    when(() => mockRef.push()).thenReturn(mockPushRef);
    when(() => mockPushRef.key).thenReturn('push_key');
    when(() => mockPushRef.set(any())).thenAnswer((_) async => Future<void>.value());

    final service = CycleService(db: mockDb, auth: mockAuth);
    final model = CycleModel(startDate: DateTime.utc(2026, 1, 1), cycleLength: 28, periodLength: 5);

    await service.addCycle(model);

    final captured = verify(() => mockPushRef.set(captureAny())).captured.single as Map<String, dynamic>;
    expect(captured['id'], equals('push_key'));
    expect(captured['startDate'], equals(model.startDate.toIso8601String()));
    expect(captured['cycleLength'], equals(28));
    expect(captured['periodLength'], equals(5));
  });
}
