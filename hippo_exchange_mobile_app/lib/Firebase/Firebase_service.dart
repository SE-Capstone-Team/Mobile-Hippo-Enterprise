import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

//1.	when loggedin, it should save userid for autologin.
//2.	add firebase features for inventory and profile.
//3.	add logout function in profile

class AuthService {
  //shortcuts to call
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'inventory-db',
  );
  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('items'); //region Inventory Process

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
    final profile = await _db.collection('profiles').doc(uid).get();
    return cred;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<User?> get authState => _auth.authStateChanges();
  // endregion

  //region register process
  Future<UserCredential> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (displayName != null && displayName.isNotEmpty) {
      await cred.user!.updateDisplayName(displayName);
    }
    await _db.collection('profiles').doc(cred.user!.uid).set({
      'email': email,
      'displayName': displayName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'roles': ['user'],
    }, SetOptions(merge: true));
    await cred.user!.sendEmailVerification();

    return cred;
  }

  //endregion

  //region Inventory Process
  Future<DocumentReference> addItem({
    required String name,
    required String sku,
    double? unitCost,
    String? location,
    String? category,
  }) async {
    //this what we grab
    final data = {
      'name': name,
      'sku': sku,
      'unitCost': unitCost,
      'location': location,
      'category': category,
    };
    return await _items.add(data);
  }

  //delete
  Future<void> deleteItem(String id) async {
    await _items.doc(id).delete();
  }

  //update
  Future<void> updateItem(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('items').doc(id).set(updates, SetOptions(merge: true));
  } //endregion
}
