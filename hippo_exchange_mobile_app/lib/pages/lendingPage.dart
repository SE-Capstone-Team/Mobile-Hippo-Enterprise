import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';
import 'package:hippo_exchange_mobile_app/pages/addItems.dart';

class LendingPage extends StatefulWidget {
  const LendingPage({super.key});
  @override
  State<LendingPage> createState() => _LendingPageState();
}

class _LendingPageState extends State<LendingPage> {
  late final FirebaseFirestore db;

  @override
  void initState() {
    super.initState();
    db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: AuthService.kFirestoreDbId
    );
  }
  Stream<QuerySnapshot> _lendQuery() {
    return db.collection('items')
        .where('ownerRef', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('createdAt', descending: true)
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
      appBar: AppBar(title: const Text('Lent Items'),
          actions: [
          IconButton(
          icon: const Icon(Icons.add_box_outlined),
      tooltip: 'Add Item',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddItemPage()),
        );
      },
    ),
    ],),
      body: StreamBuilder<QuerySnapshot>(
        stream: _lendQuery(),
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
                final isLent = d['isLent'] == true;
                return ListTile(
                  title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: isLent
                      ? Text('Currently lent')
                      : const Text('Available'),
                  trailing: isLent
                      ? const Icon(Icons.assignment_return, color: Colors.red)
                      : const Icon(Icons.check_circle, color: Colors.green),
                );
              }
          );
        },
      ),
    );
  }
}