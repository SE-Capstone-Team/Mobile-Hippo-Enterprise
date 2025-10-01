import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';

//tasks
//Step 1: pull from items database
//step 2: display information in real time
//step 3: display images without being locally stored

// Widget for a single borrowed item row
class BorrowingPage extends StatefulWidget {
  const BorrowingPage({super.key});


  @override
  State<BorrowingPage> createState() => _BorrowingPageState();
}

class _BorrowingPageState extends State<BorrowingPage> {
  late final FirebaseFirestore db;


  @override
  void initState() {
    super.initState();
    db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: AuthService.kFirestoreDbId
    );
  }

  Stream<QuerySnapshot> _BorrowQuery() {
    return db.collection('items')
        .where('borrowerRef', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('startedAt', descending: true)
        .snapshots();
  }

  /// Adjust stock safely (prevents negatives)
  Future<void> _adjustStock(String docId, int delta) async {
    await db.runTransaction((txn) async {
      final ref = db.collection('items').doc(docId);
      final snap = await txn.get(ref);
      if (!snap.exists) throw StateError('Item not found');
      final data = snap.data()!;
      final current = (data['quantity'] ?? 0) as int;
      final next = current + delta;
      if (next < 0) throw StateError('Stock cannot go negative.');
      txn.update(ref, {
        'quantity': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrowed Items')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _BorrowQuery(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No items yet.'));
          }

          return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final d = docs[i];
                final m = d.data();
                final itemName = d['name'] ?? 'unnamed Item';
                final dueAt = d['dueAt'] ?? '';
                final ownerName = d['ownerDisplayName'] ?? 'Owner';


                return ListTile(
                  title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    dueAt != null
                        ? 'Borrowed from $ownerName • Due ${dueAt.toLocal().toString().split(' ')[0]}'
                        : 'Borrowed from $ownerName',
                  ),
                  trailing: const Icon(Icons.shopping_bag, color: Colors.blue),
                );
              }
          );
        },
      ),
    );
  }
}
