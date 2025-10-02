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
        databaseId: 'inventory-db',
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Hippo ',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: 'Exchange: ',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF93B9E1),
                ),
              ),
              const TextSpan(
                text: 'Lending',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(.5),
          child: Container(
            color: const Color(0xFF93B9E1).withOpacity(0.2),
            height: 1.0,
          ),
        ),
        actions: [
      Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF93b9e1),
      ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: AuthService().streamMyLentItems(),
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
                final data = d.data() as Map<String, dynamic>;
                final itemName = data['name'] ?? 'unnamed Item';
                final isLent = data['isLent'] == true;


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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddItemPage()),
        );},
        backgroundColor: Color(0xFF1a6ec7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),

      ),
    );
  }
}