import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';



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

  Query<Map<String, dynamic>> _lendQuery() {
    return db.collection('items')
        .where('isActive', isEqualTo: true)
        .orderBy('name');
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
      appBar: AppBar(title: const Text('lent Items')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _lendQuery().snapshots(),
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
                final name = (m['name'] ?? '') as String;
                final sku = (m['sku'] ?? '') as String;
                final qty = (m['quantity'] ?? 0) as int;

                return ListTile(
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('SKU: $sku   •   Qty: $qty'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: 'Decrease',
                        icon: const Icon(Icons.remove),
                        onPressed: () async {
                          try {
                            await _adjustStock(d.id, -1);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'Increase',
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          try {
                            await _adjustStock(d.id, 1);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  //onTap: () {
                  // optional: open details page
                  //};
                );
              }
          );
        },
      ),
    );
  }
}