import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<UserModel?> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) throw Exception('User creation failed');

      // Update display name
      await user.updateDisplayName(displayName);
      await user.reload();

      // Create user document in Realtime Database
      UserModel userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: displayName,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        settings: {
          'notificationsEnabled': true,
          'privacyMode': false,
        },
      );

      await _database.ref('users/${user.uid}').set(userModel.toJson());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Login with email and password
  Future<UserModel?> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) throw Exception('Login failed');

      // Fetch user data from database
      final snapshot = await _database.ref('users/${user.uid}').get();
      
      if (snapshot.exists) {
        final data = _castStringKeyMap(snapshot.value);
        UserModel userModel = UserModel.fromJson(data);
        return userModel;
      }

      // Fallback if user data doesn't exist
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Get current user data from database
  Future<UserModel?> getCurrentUserData(String uid) async {
    try {
      final snapshot = await _database.ref('users/$uid').get();
      
      if (snapshot.exists) {
        final data = _castStringKeyMap(snapshot.value);
        return UserModel.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user data: ${e.toString()}');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      User? user = _auth.currentUser;
      
      if (displayName != null) {
        await user?.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user?.updatePhotoURL(photoURL);
      }
      await user?.reload();

      // Update in database
      final updates = {
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;

      await _database.ref('users/$uid').update(updates);
    } catch (e) {
      throw Exception('Profile update failed: ${e.toString()}');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  Map<String, dynamic> _castStringKeyMap(dynamic value) {
    if (value is! Map) {
      return <String, dynamic>{};
    }
    final result = <String, dynamic>{};
    value.forEach((k, v) {
      final key = k?.toString() ?? '';
      if (v is Map) {
        result[key] = _castStringKeyMap(v);
      } else {
        result[key] = v;
      }
    });
    return result;
  }
}
