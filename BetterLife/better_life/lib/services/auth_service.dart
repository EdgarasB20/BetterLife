import 'package:firebase_auth/firebase_auth.dart';

/// TEMPORARY DEV CREDENTIALS - Remove or disable in production
const _devEmail = 'dev@test.com';
const _devPassword = 'dev123456';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // displayName nėra būtinas, bet nice-to-have
    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      await cred.user?.updateDisplayName(trimmedName);
      await cred.user?.reload();
    }

    return cred;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  /// Quick dev login - TEMPORARY FEATURE for development only
  /// Remove this method and the dev credentials before production
  Future<UserCredential> devLogin() {
    return signIn(email: _devEmail, password: _devPassword);
  }
}