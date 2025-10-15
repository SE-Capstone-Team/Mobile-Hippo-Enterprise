import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.itemData != null) {
      _itemData = widget.itemData;
      _isLoading = false;
    } else {
      _loadItemData();
    }
  }

  Future<void> _loadItemData() async {
    try {
      final doc = await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'inventory-db',
      ).collection('items').doc(widget.itemId).get();

      if (doc.exists) {
        setState(() {
          _itemData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading item: $e')),
        );
      }
    }
  }

  Future<void> _borrowItem() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm Borrow'),
            content: Text('Are you sure you want to borrow "${_itemData!['name']}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF93B9E1),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Borrow'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF93B9E1),
            ),
          ),
        );

        await AuthService().startBorrow(
          itemId: widget.itemId,
        );

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully borrowed "${_itemData!['name']}"!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error borrowing item: ${e.toString()}'),
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
    final address = _itemData!['location'] ?? 'Not available';
    final imageUrl = _itemData!['picture'];

    String? borrowedDate;
    String? dueDate;

    if (_itemData!['borrowedOn'] != null) {
      final borrowedOnTimestamp = _itemData!['borrowedOn'] as Timestamp;
      final borrowedOnDateTime = borrowedOnTimestamp.toDate().toLocal();
      borrowedDate = "${borrowedOnDateTime.year}-${borrowedOnDateTime.month.toString().padLeft(2, '0')}-${borrowedOnDateTime.day.toString().padLeft(2, '0')}";
    }

    if (_itemData!['dueAt'] != null) {
      final dueAtTimestamp = _itemData!['dueAt'] as Timestamp;
      final dueDateTime = dueAtTimestamp.toDate().toLocal();
      dueDate = "${dueDateTime.year}-${dueDateTime.month.toString().padLeft(2, '0')}-${dueDateTime.day.toString().padLeft(2, '0')}";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

                _buildOwnerName(),
                const SizedBox(height: 12),
                _buildDetailRow('Item Location', address),
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

  Widget _buildOwnerName() {
    final ownerId = _itemData!['ownerId'] as DocumentReference?;

    if (ownerId == null) {
      return _buildDetailRow('Owner', 'Unknown');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: ownerId.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDetailRow('Owner', 'Loading...');
        }
        if (snapshot.hasError || !snapshot.data!.exists) {
          return _buildDetailRow('Owner', 'Unknown');
        }

        final ownerData = snapshot.data!.data() as Map<String, dynamic>?;
        final firstName = ownerData?['firstName'] ?? '';
        final lastName = ownerData?['lastName'] ?? '';
        final displayName = '$firstName $lastName'.trim();

        return _buildDetailRow('Owner', displayName.isNotEmpty ? displayName : 'Unnamed');
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
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
