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
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? address,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      // Update additional profile info in Firestore
      await _db.collection('profiles').doc(user.uid).update({
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (address != null) 'address': address,
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

  Future<void> createItem(String name, String desc, File image, double pricePerDay) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final imageUrl = await _uploadImage(image);
    final DocumentReference userProfileRef = _profiles.doc(user.uid);
    final userProfile = await userProfileRef.get();
    final location = (userProfile.data() as Map<String, dynamic>)['address'];

    await _items.add({
      'name': name,
      'desc': desc,
      'pricePerDay': pricePerDay,
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

      final DocumentReference userProfileRef = _profiles.doc(user.uid);

      return _items
          .where('ownerId', isEqualTo: userProfileRef)
          .orderBy('name', descending: true)
          .snapshots();
    } //endregion

    //region Available Items for Home Page
    Stream<QuerySnapshot<Map<String, dynamic>>> streamAvailableItems() {
      return _items
          .where('isLent', isEqualTo: false)
          .orderBy('name')
          .snapshots();
    } //endregion

    //region Borrowing
    Future<void> startBorrow({
      required String itemId,
    }) async {
      final user = _auth.currentUser; // This is the borrower
      if (user == null) throw Exception('Not signed in');

      final DocumentReference borrowerIdRef = _profiles.doc(user.uid);
      final borrowerProfile = await borrowerIdRef.get();
      final borrowerAddress = (borrowerProfile.data() as Map<String, dynamic>)['address'];

      final itemRef = _items.doc(itemId);
      final dueDate = DateTime.now().add(const Duration(days: 7));

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
          'borrowerId': borrowerIdRef,
          'location': borrowerAddress, // Update location to borrower's address
          'borrowedOn': FieldValue.serverTimestamp(),
          'dueAt': Timestamp.fromDate(dueDate),
        });
      });
    }

    Stream<QuerySnapshot<Map<String, dynamic>>> streamBorrowedItems() {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.empty();
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

        final itemData = itemSnap.data() as Map<String, dynamic>;
        final ownerIdRef = itemData['ownerId'] as DocumentReference;
        final ownerProfileSnap = await txn.get(ownerIdRef);
        if (!ownerProfileSnap.exists) throw Exception('Owner not found');
        final ownerAddress = (ownerProfileSnap.data() as Map<String, dynamic>)['address'];

        // When returned, clear borrower info and revert location
        txn.update(itemRef, {
          'isLent': false,
          'borrowerId': null,
          'location': ownerAddress,
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
      await _items.doc(id).update(updates);
    } //endregion

    //region laymen's termed firebase errors
    String mapFirebaseError(Object e) {
      if (e is FirebaseAuthException) {
        return _mapAuthError(e);
      }
      if (e is FirebaseException) {
        return _mapFirestoreError(e);
      }
      if (e is Exception) {
        return _mapGeneralError(e);
      }
      return 'Something went wrong. Please try again.';
    }

    String _mapAuthError(FirebaseAuthException e) {
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

    String _mapFirestoreError(FirebaseException e) {
      switch (e.code) {
        case 'permission-denied':
          return 'You don\'t have permission to perform this action.';
        case 'unavailable':
          return 'Service is temporarily unavailable. Please try again.';
        case 'deadline-exceeded':
          return 'Request timed out. Please check your connection and try again.';
        case 'resource-exhausted':
          return 'Too many requests. Please try again later.';
        case 'cancelled':
          return 'Operation was cancelled.';
        case 'data-loss':
          return 'Data corruption detected. Please contact support.';
        case 'unauthenticated':
          return 'Please sign in to continue.';
        case 'invalid-argument':
          return 'Invalid data provided. Please check your input.';
        case 'not-found':
          return 'The requested item was not found.';
        case 'already-exists':
          return 'This item already exists.';
        case 'failed-precondition':
          return 'Operation failed due to conflicting changes. Please refresh and try again.';
        case 'aborted':
          return 'Operation was interrupted due to a conflict. Please try again.';
        case 'out-of-range':
          return 'Invalid range specified.';
        case 'unimplemented':
          return 'This feature is not available yet.';
        case 'internal':
          return 'Internal server error. Please try again later.';
        case 'unknown':
          return 'An unknown error occurred. Please try again.';
        default:
          return e.message ?? 'Database error occurred.';
      }
    }

    String _mapGeneralError(Exception e) {
      final message = e.toString();

      if (message.contains('Not signed in')) {
        return 'Please sign in to continue.';
      }
      if (message.contains('Item not found')) {
        return 'This item is no longer available.';
      }
      if (message.contains('Item already lent')) {
        return 'Sorry, this item was just borrowed by someone else. Please try another item.';
      }
      if (message.contains('You cannot borrow your own item')) {
        return 'You cannot borrow your own item.';
      }
      if (message.contains('timeout') || message.contains('Timeout')) {
        return 'The request timed out. This might happen if someone else just borrowed the item. Please refresh and try again.';
      }
      if (message.contains('network') || message.contains('Network')) {
        return 'Network error. Please check your connection and try again.';
      }
      if (message.contains('storage') || message.contains('Storage')) {
        return 'Error uploading image. Please try again.';
      }

      return 'Something went wrong. Please try again.';
    }

    String mapAuthError(Object e) {
      return mapFirebaseError(e);
    }
  }
