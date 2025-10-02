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
        databaseId: 'inventory-db',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF93b9e1),
                ),
              ),
              const TextSpan(
                text: 'Borrowing',
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
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Color(0xFF93b9e1).withOpacity(0.2),
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
        stream: AuthService().streamBorrowedItems(),
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

          debugPrint("BorrowingPage: Found ${docs.length} borrowed items.");


          return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final d = docs[i];
                final data = d.data() as Map<String, dynamic>;
                final itemName = data['name'] ?? 'Unnamed Item';
                final ownerName = data['ownerDisplayName'] ?? 'Owner';

                final Timestamp? dueAtTimestamp = data['dueAt'] as Timestamp?;
                final Timestamp? startedAtTimestamp = data['startedAt'] as Timestamp?;


                String subtitleText = 'Borrowed from $ownerName';
                if (dueAtTimestamp != null) {
                  final dueDateTime = dueAtTimestamp.toDate().toLocal();
                  // Simple date format, you can use the `intl` package for more complex formatting
                  final formattedDueDate = "${dueDateTime.year}-${dueDateTime.month.toString().padLeft(2, '0')}-${dueDateTime.day.toString().padLeft(2, '0')}";
                  subtitleText += ' • Due $formattedDueDate';
                }

                String trailingText = ''; // For startedAt or other info
                if (startedAtTimestamp != null) {
                  final startedDateTime = startedAtTimestamp.toDate().toLocal();
                  final formattedStartedDate = "${startedDateTime.year}-${startedDateTime.month.toString().padLeft(2, '0')}-${startedDateTime.day.toString().padLeft(2, '0')}";
                  trailingText = 'Started: $formattedStartedDate';
                }



                return ListTile(
                  title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(subtitleText),
                  trailing: trailingText.isNotEmpty
                      ? Text(trailingText)
                      : const Icon(Icons.more_horiz), // Fallback icon
                  leading: const Icon(Icons.shopping_bag, color: Colors.blue),
                );
              }
          );
        },
        ),
      );
  }
}
