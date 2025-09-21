import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

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

}