import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';

//1.	when loggedin, it should save userid for autologin.
//2.	add firebase features for inventory and profile.
//3.	add logout function in profile

class AuthService {
  //shortcuts to call
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String kFirestoreDbId = 'inventory-db';
  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: kFirestoreDbId,
  );
  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('items');

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
    final profile = await _db.collection('profiles').doc(uid);
    return cred;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<User?> get authState => _auth.authStateChanges();

  // Update user profile information
  Future<void> updateUserProfile({
    String? displayName,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      // Update additional profile info in Firestore
      await _db.collection('profiles').doc(user.uid).update({
        if (displayName != null) 'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
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

  //region Lending
  Future<void> createItem(String name, String desc) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');


    final DocumentReference userProfileRef = _db.collection('profiles').doc(user.uid);
    final String ownerDisplayName = user.displayName ?? 'Unknown Owner'; // Get display name

    await _items.add({
      'name': name,
      'ownerRef': userProfileRef,
      'ownerDisplayName': ownerDisplayName,
      'isLent': false,
      'borrowerRef': null,
      'dueAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'isLent': false,
      'isPublic': true,
      'startedAt': null,
      'desc': desc,
    });

  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMyLentItems() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty(); // Or handle appropriately
    }

    // Get the DocumentReference to the current user's profile
    final DocumentReference userProfileRef = _db.collection('profiles').doc(user.uid);

    return _items // _items is your CollectionReference<Map<String, dynamic>> to the 'items' collection
        .where('ownerRef', isEqualTo: userProfileRef)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }//endregion

  //region Borrowing
  Future<void> startBorrow({
    required String itemId,
    required String borrowerUid,
    DateTime? dueAt,
  }) async {
    final DocumentReference borrowerRef = _auth.currentUser?.uid as DocumentReference<Object?>;
    final itemRef = _items.doc(itemId);

    await _db.runTransaction((txn) async {
      final itemSnap = await txn.get(itemRef);
      if (!itemSnap.exists) {
        throw Exception('Item not found');
      }
      final item = itemSnap.data() as Map<String, dynamic>;
      if (item['isLent'] == true) {
        throw Exception('Item already lent');
      }

      txn.update(itemRef, {
        'isLent': true,
        'borrowerRef': borrowerRef,
        'startedAt': FieldValue.serverTimestamp(),
        'dueAt': dueAt != null ? Timestamp.fromDate(dueAt) : null,
      });
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamBorrowedItems() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty(); // Or handle appropriately
    }
    final DocumentReference userProfileRef = _db.collection('profiles').doc(user.uid);

      return _items
          .where('borrowerRef', isNotEqualTo: userProfileRef)
          .orderBy('startedAt', descending: true)
          .snapshots();
  }

  Future<void> returnItem({required String itemId}) async {
    final itemRef = _items.doc(itemId);

    await _db.runTransaction((txn) async {
      final itemSnap = await txn.get(itemRef);
      if (!itemSnap.exists) throw Exception('Item not found');
      final item = itemSnap.data() as Map<String, dynamic>;

      // Clear item’s active state
      txn.update(itemRef, {
        'isLent': false,
        'borrowerRef': null,
      });
    });
  } //endregion

  //delete
  Future<void> deleteItem(String id) async {
    await _items.doc(id).delete();
  }

  //update
  Future<void> updateItem(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _items.doc(id).set(updates);
  } //endregion
}
