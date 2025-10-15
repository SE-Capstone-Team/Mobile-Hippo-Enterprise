import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';
import 'package:hippo_exchange_mobile_app/pages/viewItem.dart';

// NEW: notifications imports
import 'package:hippo_exchange_mobile_app/pages/notifications_inbox.dart';
import 'package:hippo_exchange_mobile_app/services/notification_service.dart';

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
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4F8),
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
                text: 'Borrowed',
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

        // NEW: Notification Bell with unread badge
        actions: [
          FutureBuilder<int>(
            future: NotificationService.instance.getUnreadCount(),
            builder: (context, snap) {
              final unread = snap.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    icon: const Icon(Icons.notifications),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsInboxPage(),
                        ),
                      );
                      if (mounted) setState(() {}); // refresh badge on return
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
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
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, i) {
                final d = docs[i];
                final data = d.data() as Map<String, dynamic>;
                final itemName = data['name'] ?? 'Unnamed Item';
                final itemDesc = data['desc'] ?? '';
                final imageUrl = data['picture'];

                final Timestamp? dueAtTimestamp = data['dueAt'] as Timestamp?;
                final Timestamp? borrowedOnTimestamp = data['borrowedOn'] as Timestamp?;

              String? startedDate;
              String? dueDate;

              if (startedAtTimestamp != null) {
                final startedDateTime = startedAtTimestamp.toDate().toLocal();
                startedDate =
                "${startedDateTime.year}-${startedDateTime.month.toString().padLeft(2, '0')}-${startedDateTime.day.toString().padLeft(2, '0')}";
              }

              if (dueAtTimestamp != null) {
                final dueDateTime = dueAtTimestamp.toDate().toLocal();
                dueDate =
                "${dueDateTime.year}-${dueDateTime.month.toString().padLeft(2, '0')}-${dueDateTime.day.toString().padLeft(2, '0')}";
              }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewItemPage(
                          itemId: d.id,
                          itemData: data,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF93B9E1).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Circular image placeholder
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.withOpacity(0.8),
                                      Colors.indigo.withOpacity(0.6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                          child: imageUrl != null
                                              ? Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: 60,
                                                  height: 60,
                                                  loadingBuilder: (context, child,
                                                      loadingProgress) {
                                                    if (loadingProgress == null) {
                                                      return child;
                                                    }
                                                    return const Center(
                                                        child: CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<Color>(
                                                              Colors.white),
                                                    ));
                                                  },
                                                  errorBuilder:
                                                      (context, error, stackTrace) =>
                                                          const Icon(
                                                    Icons.inventory_2,
                                                    color: Colors.white,
                                                    size: 28,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.inventory_2,
                                                  color: Colors.white,
                                                  size: 28,
                                                )),
                              ),
                              const SizedBox(width: 16),
                              
                              // Expanded content area
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Item name
                                    Text(
                                      itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    
                                    const SizedBox(height: 6),
                                    
                                    // Description
                                    if (itemDesc.isNotEmpty) ...[
                                      Text(
                                        itemDesc,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    
                                    // Owner info with FutureBuilder to fetch owner data
                                    _buildOwnerInfo(data['ownerId']),
                                    
                                    const SizedBox(height: 8),
                                    
                                    // Date information - stacked
                                    if (borrowedDate != null || dueDate != null) ...[
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (borrowedDate != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.green.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                'Borrowed: $borrowedDate',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                          
                                          if (dueDate != null && borrowedDate != null) ...[
                                            const SizedBox(height: 6),
                                          ],
                                          
                                          if (dueDate != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.orange.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                'Return by: $dueDate',
                                                style: TextStyle(
                                                  color: Colors.orange[700],
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              // Status icon
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.assignment_outlined,
                                  color: Colors.blue[600],
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Return Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF93B9E1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 2,
                              ),
                              onPressed: () => _returnItem(d.id, itemName),
                              child: const Text(
                                'Return This Item',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
          );
        },
        ),
      );
  }

  Future<String> _getOwnerName(DocumentReference ownerId) async {
    try {
      // Use the Firebase service instance to get owner info using the same database config
      final ownerDoc = await db.collection('profiles').doc(ownerId.id).get();
      if (ownerDoc.exists) {
        final ownerData = ownerDoc.data();
        final firstName = ownerData?['firstName'] ?? '';
        final lastName = ownerData?['lastName'] ?? '';
        final ownerName = '$firstName $lastName'.trim();
        return ownerName.isNotEmpty ? ownerName : 'Unknown Owner';
      }
      return 'Unknown Owner';
    } catch (e) {
      debugPrint("BorrowedPage: Error fetching owner name: $e");
      return 'Owner info unavailable';
    }
  }

  Future<void> _returnItem(String itemId, String itemName) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Return'),
            content: Text('Are you sure you want to return "$itemName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF93B9E1),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Return'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF93B9E1),
            ),
          ),
        );

        // Call Firebase return method
        await AuthService().returnItem(itemId: itemId);

        // Close loading dialog
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully returned "$itemName"!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close any open dialogs
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error returning item: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to build owner info from Firestore reference
  Widget _buildOwnerInfo(dynamic ownerId) {
    // Debug: Print the ownerId to understand its structure
    debugPrint("BorrowedPage: ownerId type: ${ownerId.runtimeType}, value: $ownerId");
    
    // Handle the case where ownerId is a DocumentReference
    if (ownerId is DocumentReference) {
      // Instead of directly accessing the DocumentReference, let's try using our Firebase service
      return FutureBuilder<String>(
        future: _getOwnerName(ownerId),
        builder: (context, ownerSnapshot) {
          if (ownerSnapshot.hasData) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Borrowed from: ${ownerSnapshot.data}',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            );
          }
          
          if (ownerSnapshot.hasError) {
            // Debug: Print the actual error
            debugPrint("BorrowedPage: Owner lookup error: ${ownerSnapshot.error}");
            // Return a simpler fallback instead of showing error to user
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Borrowed from: Owner info unavailable',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            );
          }
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Owner: Loading...',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          );
        },
      );
    }
    
    // Fallback for any other data type or null
    debugPrint("BorrowedPage: ownerId is not DocumentReference. Type: ${ownerId.runtimeType}, value: $ownerId");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        'Owner: Unknown (${ownerId?.runtimeType ?? 'null'})',
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

