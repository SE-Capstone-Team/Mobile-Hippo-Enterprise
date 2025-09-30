import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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

  //region Lending
  Future<void> createItem(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final ownerDisplayName = _auth.currentUser?.displayName;
    await _items.add({
      'name': name,
      'ownerRef': user.uid,
      'ownerDisplayName': ownerDisplayName,
      'isLent': false,
      'borrowerRef': null,
      'dueAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Stream<QuerySnapshot> streamItems({bool? onlyAvailable}) {
      Query q = _items.orderBy('CreatedAt', descending: true);
      if (onlyAvailable != null) {
        q = q.where('isLent', isEqualTo: !onlyAvailable ? true : false);
      }
      return q.snapshots();
    }

    Stream<QuerySnapshot> streamMyItems() {
      return _items
          .where('owenerRef', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

  } //endregion

  //region Borrowing
  Future<void> startBorrow({
    required String itemId,
    required String borrowerUid,
    DateTime? dueAt,
  }) async {
    final borrowerRef = _auth.currentUser?.uid;
    final itemRef = _items.id;

    await _db.runTransaction((txn) async {
      final itemSnap = await txn.get(itemRef as DocumentReference<Object?>);
      if (!itemSnap.exists) {
        throw Exception('Item not found');
      }
      final item = itemSnap.data() as Map<String, dynamic>;
      if (item['isLent'] == true) {
        throw Exception('Item already lent');
      }

      final borrowerSnap = await txn.get(borrowerRef as DocumentReference<Object?>);
      final borrowerDisplayName =
          (borrowerSnap.data() as Map<String, dynamic>?)?['displayName'] as String? ?? 'Unknown';

      txn.update(_items.id as DocumentReference<Object?>, {
        'isLent': true,
        'borrowerRef': borrowerRef,
        'startedAt': FieldValue.serverTimestamp(),
        'dueAt': dueAt != null ? Timestamp.fromDate(dueAt) : null,
      });
    });
  }

  Future<void> returnItem({required String itemId}) async {
    final itemRef = _items.id;

    await _db.runTransaction((txn) async {
      final itemSnap = await txn.get(_items.id as DocumentReference<Object?>);
      if (!itemSnap.exists) throw Exception('Item not found');

      final item = itemSnap.data() as Map<String, dynamic>;
      final currentLoanRef = item['currentLoanRef'] as DocumentReference?;
      if (currentLoanRef == null) throw Exception('No active loan to close');

      // Mark loan returned
      txn.update(currentLoanRef, {
        'status': 'returned',
        'returnedAt': FieldValue.serverTimestamp(),
      });

      // Clear item’s active state
      txn.update(_items.id as DocumentReference<Object?>, {
        'isLent': false,
        'currentLoanRef': null,
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
    await _db.collection('items').doc(id).set(updates, SetOptions(merge: true));
  } //endregion
}
