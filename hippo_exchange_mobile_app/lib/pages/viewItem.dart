import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// NEW: notifications imports
import 'package:hippo_exchange_mobile_app/pages/notifications_inbox.dart';
import 'package:hippo_exchange_mobile_app/services/notification_service.dart';

class ViewItemPage extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic>? itemData; // Optional pre-loaded data
  final bool showBorrowButton; // Whether to show borrow functionality

  const ViewItemPage({
    super.key,
    required this.itemId,
    this.itemData,
    this.showBorrowButton = false, // Default to false
  });

  @override
  State<ViewItemPage> createState() => _ViewItemPageState();
}

class _ViewItemPageState extends State<ViewItemPage> {
  Map<String, dynamic>? _itemData;
  bool _isLoading = true;
  late final FirebaseFirestore db;

  @override
  void initState() {
    super.initState();
    db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'inventory-db',
    );
    if (widget.itemData != null) {
      _itemData = widget.itemData;
      _isLoading = false;
    } else {
      _loadItemData();
    }
  }

  Future<void> _loadItemData() async {
    try {
      final doc = await db.collection('items').doc(widget.itemId).get();
      
      if (doc.exists) {
        setState(() {
          _itemData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService().mapFirebaseError(e))),
        );
      }
    }
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
      debugPrint("ViewItemPage: Error fetching owner name: $e");
      return 'Owner info unavailable';
    }
  }

  Future<void> _borrowItem() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Borrow'),
            content: Text('Are you sure you want to borrow "${_itemData!['name']}"?'),
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
                child: const Text('Borrow'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        // Loading spinner
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF93B9E1)),
          ),
        );

        // Call Firebase borrowing method
        await AuthService().startBorrow(
          itemId: widget.itemId,
          dueAt: DateTime.now().add(Duration(days: 7)), // Default 7 days from now
        );

        // Close loading
        if (mounted) Navigator.of(context).pop();

        // NEW: Fire local notification (and optional OS banner)
        await NotificationService.instance.notifyLocal(
          title: 'Borrow complete',
          body: 'You borrowed “${_itemData!['name']}”.',
          payload: {
            'type': 'borrow_complete',
            'itemId': widget.itemId,
            'name': _itemData!['name'],
          },
          showSystemBanner: true,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully borrowed "${_itemData!['name']}"!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back after success
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close any open dialogs
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService().mapFirebaseError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text("Item Details"),
        backgroundColor: const Color(0xFF93B9E1),
        elevation: 0,

        // NEW: Notification Bell with unread badge
        actions: [
          StatefulBuilder(
            builder: (context, setNotificationState) {
              return FutureBuilder<int>(
                future: NotificationService.instance.getUnreadCount(),
                builder: (context, snap) {
                  final unread = snap.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        tooltip: 'Notifications',
                        icon: const Icon(
                          Icons.notifications,
                          size: 28, // Increased size
                        ),
                        onPressed: () async {
                          // Immediate feedback - disable during navigation
                          setNotificationState(() {});
                          
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsInboxPage(),
                            ),
                          );
                          
                          // Only refresh the notification badge, not the entire page
                          if (mounted) {
                            setNotificationState(() {});
                          }
                        },
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF93B9E1), // Updated to match app theme
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _itemData == null
          ? const Center(child: Text('Item not found'))
          : _buildItemDetails(),
    );
  }

  Widget _buildItemDetails() {
    final itemName = _itemData!['name'] ?? 'Unnamed Item';
    final itemDesc = _itemData!['desc'] ?? 'No description available';
    final isLent = _itemData!['isLent'] == true;
    final imageUrl = _itemData!['picture'];
    
    // Format dates
    String? borrowedDate;
    String? dueDate;
    
    if (_itemData!['borrowedOn'] != null) {
      final borrowedOnTimestamp = _itemData!['borrowedOn'] as Timestamp;
      final borrowedDateTime = borrowedOnTimestamp.toDate().toLocal();
      borrowedDate = "${borrowedDateTime.year}-${borrowedDateTime.month.toString().padLeft(2, '0')}-${borrowedDateTime.day.toString().padLeft(2, '0')}";
    }

    if (_itemData!['dueAt'] != null) {
      final dueAtTimestamp = _itemData!['dueAt'] as Timestamp;
      final dueDateTime = dueAtTimestamp.toDate().toLocal();
      dueDate =
      "${dueDateTime.year}-${dueDateTime.month.toString().padLeft(2, '0')}-${dueDateTime.day.toString().padLeft(2, '0')}";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area (placeholder)
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF2F2F2),
              border: Border.all(
                color: const Color(0xFF93B9E1).withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes !=
                                    null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                        Icons.image,
                        size: 80,
                        color: Color(0xFF93B9E1),
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      size: 80,
                      color: Color(0xFF93B9E1),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Item title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF93B9E1).withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF93B9E1).withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  itemDesc,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Item details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF93B9E1).withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildOwnerDetailRow(),
                const SizedBox(height: 12),

                _buildDetailRow(
                  'Status',
                  isLent ? 'Currently Borrowed' : 'Available',
                  statusColor: isLent ? Colors.red : Colors.green,
                ),

                if (borrowedDate != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Borrowed On', borrowedDate),
                ],

                if (dueDate != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Due Date', dueDate),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Borrow Button (only show if requested and available)
          if (widget.showBorrowButton && !isLent) ...[
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
                onPressed: () => _borrowItem(),
                child: const Text(
                  'Borrow This Item',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnerDetailRow() {
    final ownerId = _itemData!['ownerId'];
    
    // Debug: Print the ownerId to understand its structure
    debugPrint("ViewItemPage: ownerId type: ${ownerId.runtimeType}, value: $ownerId");
    
    // Handle the case where ownerId is a DocumentReference
    if (ownerId is DocumentReference) {
      return FutureBuilder<String>(
        future: _getOwnerName(ownerId),
        builder: (context, ownerSnapshot) {
          if (ownerSnapshot.hasData) {
            return _buildDetailRow('Owner', ownerSnapshot.data!);
          }
          
          if (ownerSnapshot.hasError) {
            debugPrint("ViewItemPage: Owner lookup error: ${ownerSnapshot.error}");
            return _buildDetailRow('Owner', 'Owner info unavailable');
          }
          
          return _buildDetailRow('Owner', 'Loading...');
        },
      );
    }
    
    // Fallback for any other data type or null
    debugPrint("ViewItemPage: ownerId is not DocumentReference. Type: ${ownerId.runtimeType}, value: $ownerId");
    return _buildDetailRow('Owner', 'Unknown Owner (${ownerId?.runtimeType ?? 'null'})');
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: statusColor ?? Colors.black87,
              fontWeight: statusColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

