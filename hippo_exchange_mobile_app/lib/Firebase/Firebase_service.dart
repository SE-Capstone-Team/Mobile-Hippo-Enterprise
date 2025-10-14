import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

class AuthService {
  //region shortcuts to call in Firebase Service
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String kFirestoreDbId = 'inventory-db';
  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: kFirestoreDbId,
  );

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('items');

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _db.collection('profiles');

  //endregion

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
    String? firstName, String? lastName,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (firstName != null) {
        await user.updateDisplayName(firstName);
      }
      if (lastName != null) {
        await user.updateDisplayName(lastName);
      }

      // Update additional profile info in Firestore
      await _db.collection('profiles').doc(user.uid).update({
        if (firstName != null || lastName != null)
          'firstName': firstName,
        'lastName': lastName,
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
  Future<String> _uploadImage(File image) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    final storageRef = _storage.ref().child('item_images').child('${user.uid}-${DateTime.now().toIso8601String()}');
    final uploadTask = await storageRef.putFile(image);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> createItem(String name, String desc, File image) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final imageUrl = await _uploadImage(image);
    final DocumentReference userProfileRef = _profiles.doc(user.uid);
    final userProfile = await userProfileRef.get();
    final location = userProfile['address'];

    await _items.add({
      'name': name,
      'desc': desc,
      'picture': imageUrl,
      'ownerId': userProfileRef,
      'isLent': false,
      'borrowerId': null,
      'dueAt': null,
      'borrowedOn': null,
      'location': location,
    });
  }

    Stream<QuerySnapshot<Map<String, dynamic>>> streamMyLentItems() {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.empty(); // Or handle appropriately
      }

      // Get the DocumentReference to the current user's profile
      final DocumentReference userProfileRef = _profiles.doc(user.uid);

      return _items // _items is your CollectionReference<Map<String, dynamic>> to the 'items' collection
          .where('ownerId', isEqualTo: userProfileRef)
          .orderBy('name', descending: true)
          .snapshots();
    } //endregion

    //region Available Items for Home Page
    Stream<QuerySnapshot<Map<String, dynamic>>> streamAvailableItems() {
      // Stream all items that are not currently lent (available for borrowing)
      return _items
          .where('isLent', isEqualTo: false)
          .orderBy('name')
          .snapshots();
    } //endregion

    //region Borrowing
    Future<void> startBorrow({
      required String itemId,
      required String borrowerId,
      DateTime? dueAt,
    }) async {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final DocumentReference borrowerId = _profiles.doc(user.uid);
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
          'borrowerId': borrowerId,
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
      final DocumentReference userProfileRef = _profiles.doc(user.uid);

      return _items
          .where('borrowerId', isEqualTo: userProfileRef)
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

    //region delete and update
    Future<void> deleteItem(String id) async {
      await _items.doc(id).delete();
    }

    //update
    Future<void> updateItem(String id, Map<String, dynamic> updates) async {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _items.doc(id).set(updates);
    } //endregion

    //region laymen's termed firebase errors
    String mapAuthError(Object e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-credential':
            return 'Email or password is Incorrect!';
          case 'channel-error':
            return 'Missing Email or password';
          case 'invalid-email':
            return 'That email address is malformed.';
          case 'user-disabled':
            return 'This account has been disabled.';
          case 'user-not-found':
            return 'No user found with that email.';
          case 'wrong-password':
            return 'Incorrect password.';
          case 'email-already-in-use':
            return 'Email is already registered.';
          case 'operation-not-allowed':
            return 'Sign-in method is disabled.';
          case 'too-many-requests':
            return 'Too many attempts. Try again later.';
          case 'network-request-failed':
            return 'Network error. Check connection.';
          case 'unauthorized':
            return 'User is not Authenticated!';
          default:
            return e.message ?? 'Authentication error occurred.';
        }
      }
      return 'Something went wrong. Please try again.';
    } //endregion
  }
