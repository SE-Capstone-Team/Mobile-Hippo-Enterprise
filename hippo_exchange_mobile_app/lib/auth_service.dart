import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // region login and logout process
  Future<UserCredential> emailsignin({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final profile = await FirebaseFirestore.instance.collection('users').doc(
        uid).get();
    return cred;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<User?> get authState => _auth.authStateChanges();
// endregion

 //region register process
  Future<UserCredential> register({
    required String email,
    required String password,
    String? displayName
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (displayName != null && displayName.isNotEmpty) {
      await cred.user!.updateDisplayName(displayName);
    }
    await _db.collection('users').doc(cred.user!.uid).set({
      'email':email,
      'displayName': displayName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'roles': ['user'],
    }, SetOptions(merge: true));
    await cred.user!.sendEmailVerification();

    return cred;
  }

 //endregion

}