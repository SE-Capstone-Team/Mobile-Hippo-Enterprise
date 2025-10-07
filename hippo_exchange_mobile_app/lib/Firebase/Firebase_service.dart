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
    return cred;
  }

  Future<void> signOut() => _auth.signOut();

  Stream<User?> get authState => _auth.authStateChanges();

  // Update user profile information
  //firstname lastname
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
    required firstName,
    required lastName,
    required address
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _db.collection('profiles').doc(cred.user!.uid).set({
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'address': address,
    }, SetOptions(merge: true));
    await cred.user!.sendEmailVerification();

    return cred;
  }

  //endregion

  //region Lending
  Future<void> createItem(String name, String desc) async {
    final user = _auth.currentUser;
    final DocumentReference userProfileRef = _db.collection('profiles').doc(user?.uid);
    final userProfile = await userProfileRef.get();
    final location = userProfile['address'];
    if (user == null) throw Exception('Not signed in');

    await _items.add({
      'name': name,
      'ownerId': userProfileRef,
      'isLent': false,
      'borrowerId': null,
      'dueAt': null,
      'borrowedOn': null,
      'location': location,
      'picture': null,
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
        .where('ownerId', isEqualTo: userProfileRef)
        .orderBy('name', descending: true)
        .snapshots();
  }//endregion

  //region Borrowing
  Future<void> startBorrow({
    required String itemId,
    required String borrowerUid,
    DateTime? dueAt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    
    final DocumentReference borrowerRef = _db.collection('profiles').doc(user.uid);
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
        'borrowerId': borrowerRef,
        'borrowedOn': FieldValue.serverTimestamp(),
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
          .where('borrowerRef', isEqualTo: userProfileRef)
          .orderBy('dueAt', descending: true)
          .snapshots();
  }

  Future<void> returnItem({required String itemId}) async {
    final itemRef = _items.doc(itemId);

    await _db.runTransaction((txn) async {
      final itemSnap = await txn.get(itemRef);
      if (!itemSnap.exists) throw Exception('Item not found');

      // Clear item’s active state
      txn.update(itemRef, {
        'isLent': false,
        'borrowerId': null,
        'borrowedOn': null,
        'dueAt': null,
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

  String mapAuthError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential': return 'Email or password is Incorrect!';
        case 'channel-error': return 'Missing Parameter';
        case 'invalid-email': return 'That email address is malformed.';
        case 'user-disabled': return 'This account has been disabled.';
        case 'user-not-found': return 'No user found with that email.';
        case 'wrong-password': return 'Incorrect password.';
        case 'email-already-in-use': return 'Email is already registered.';
        case 'operation-not-allowed': return 'Sign-in method is disabled.';
        case 'too-many-requests': return 'Too many attempts. Try again later.';
        case 'network-request-failed': return 'Network error. Check connection.';
        default: return e.message ?? 'Authentication error occurred.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
