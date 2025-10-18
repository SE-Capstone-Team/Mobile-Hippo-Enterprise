import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewItemPage extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic>? itemData;
  final bool showBorrowButton;

  const ViewItemPage({
    super.key,
    required this.itemId,
    this.itemData,
    this.showBorrowButton = false,
  });

  @override
  State<ViewItemPage> createState() => _ViewItemPageState();
}

class _ViewItemPageState extends State<ViewItemPage> {
  Map<String, dynamic>? _itemData;
  bool _isLoading = true;

  // State for UI interactivity
  bool _isEditing = false;
  bool _isDescriptionExpanded = true;
  bool _isDetailsExpanded = true;

  // Controllers for editing
  late final TextEditingController _descController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
    _priceController = TextEditingController();

    if (widget.itemData != null) {
      _itemData = widget.itemData;
      _initializeControllers();
      _isLoading = false;
    } else {
      _loadItemData();
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    if (_itemData != null) {
      _descController.text = _itemData!['desc'] ?? '';
      final price = _itemData!['pricePerDay'] as num? ?? 0;
      _priceController.text = price.toString();
    }
  }

  Future<void> _loadItemData() async {
    try {
      // Use cached data first
      final itemData = await AuthService().getItemWithCache(widget.itemId);
      
      if (itemData != null) {
        setState(() {
          _itemData = itemData;
          _initializeControllers();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item not found')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService().mapFirebaseError(e))),
        );
      }
    }
  }

  Future<void> _borrowItem() async {
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

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF93B9E1)),
      ),
    );

    try {
      await AuthService().startBorrow(itemId: widget.itemId);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully borrowed "${_itemData!['name']}"!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Go back to home page
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService().mapFirebaseError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _returnItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Item'),
        content: Text('Are you sure you want to return "${_itemData!['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Return'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AuthService().returnItem(itemId: widget.itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_itemData!['name']}" has been returned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthService().mapFirebaseError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_isEditing) return;

    final newDesc = _descController.text;
    double newPrice = double.tryParse(_priceController.text) ?? 0.0;
    if (newPrice < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Price cannot be negative.")),
        );
        return;
    }

    try {
      await AuthService().updateItem(widget.itemId, {
        'desc': newDesc,
        'pricePerDay': newPrice,
      });

      // Manually update local state to reflect changes immediately
      setState(() {
        _itemData!['desc'] = newDesc;
        _itemData!['pricePerDay'] = newPrice;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService().mapFirebaseError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _itemData != null &&
        (_itemData!['ownerId'] as DocumentReference).id ==
            FirebaseAuth.instance.currentUser?.uid;
    final isLent = _itemData!['isLent'] == true;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isBorrower = _itemData!['borrowerId'] != null && (_itemData!['borrowerId'] as DocumentReference).id == currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Item" : "Item Details"),
        backgroundColor: const Color(0xFF93B9E1),
        elevation: 0,
        actions: [
          if (isOwner && !isLent) // Only show edit button if owner and not lent
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: () {
                if (_isEditing) {
                  _saveChanges();
                } else {
                  setState(() => _isEditing = true);
                }
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
    final isLent = _itemData!['isLent'] == true;
    final address = _itemData!['location'] ?? 'Not available';
    final imageUrl = _itemData!['picture'];
    final pricePerDay = _itemData!['pricePerDay'] as num? ?? 0;
    final borrowedOnTimestamp = _itemData!['borrowedOn'] as Timestamp?;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isBorrower = _itemData!['borrowerId'] != null && (_itemData!['borrowerId'] as DocumentReference).id == currentUserId;

    String? borrowedDate, dueDate;
    String amountOwed = 'Free!';
    if (borrowedOnTimestamp != null) {
      final borrowedOn = borrowedOnTimestamp.toDate();
      borrowedDate = DateFormat('MMM d, yyyy').format(borrowedOn.toLocal());
      if (pricePerDay > 0) {
        final daysBorrowed = DateTime.now().difference(borrowedOn).inDays;
        final owed = (daysBorrowed + 1) * pricePerDay;
        amountOwed = '\$${owed.toStringAsFixed(2)}';
      }
    }
    
    if (_itemData!['dueAt'] != null) {
      dueDate = DateFormat('MMM d, yyyy').format((_itemData!['dueAt'] as Timestamp).toDate().toLocal());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and Title (non-collapsible)
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF2F2F2),
              border: Border.all(color: const Color(0xFF93B9E1).withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF93B9E1),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                        size: 80,
                        color: Color(0xFF93B9E1),
                      ),
                    )
                  : const Icon(Icons.image, size: 80, color: Color(0xFF93B9E1)),
            ),
          ),
          const SizedBox(height: 24),
          Text(itemName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Description Section (collapsible)
          _buildCollapsibleSection(
            title: 'Description',
            isExpanded: _isDescriptionExpanded,
            onToggle: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
            child: _isEditing
                ? TextField(
                    controller: _descController,
                    maxLines: null,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  )
                : Text(_itemData!['desc'] ?? 'No description.', style: const TextStyle(fontSize: 16, height: 1.5)),
          ),
          const SizedBox(height: 16),

          // Details Section (collapsible)
          _buildCollapsibleSection(
            title: 'Details',
            isExpanded: _isDetailsExpanded,
            onToggle: () => setState(() => _isDetailsExpanded = !_isDetailsExpanded),
            child: Column(
              children: [
                _buildOwnerName(),
                const SizedBox(height: 12),
                _buildDetailRow('Item Location', address),
                const SizedBox(height: 12),

                if (isBorrower) ...[
                  _buildDetailRow('Amount Owed', amountOwed, statusColor: Colors.orange[700]),
                  const SizedBox(height: 12),
                ] else ...[
                   _buildEditableDetailRow(
                    label: 'Price',
                    value: pricePerDay > 0 ? '\$${_priceController.text}/day' : 'Free!',
                    controller: _priceController,
                    isEditing: _isEditing,
                  ),
                  const SizedBox(height: 12),
                ],

                _buildDetailRow('Status', isLent ? 'Currently Borrowed' : 'Available', statusColor: isLent ? Colors.red : Colors.green),
                
                if (borrowedDate != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Borrowed On', borrowedDate),
                ],
                if (dueDate != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Payment Due', dueDate),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          if (widget.showBorrowButton && !isLent)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _borrowItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF93B9E1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Borrow This Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
            
            if (isBorrower)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _returnItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Return Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              )
        ],
      ),
    );
  }

  // Helper for collapsible sections
  Widget _buildCollapsibleSection({
    required String title,
    required Widget child,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF93B9E1).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 24, thickness: 1),
            child,
          ],
        ],
      ),
    );
  }

  // Fetches and displays owner name
  Widget _buildOwnerName() {
    // ... (same as before)
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

  // Standard row for displaying details
  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 16, color: statusColor ?? Colors.black87, fontWeight: statusColor != null ? FontWeight.w600 : FontWeight.normal))),
      ],
    );
  }
  
  // Row that can switch between text and a text field
  Widget _buildEditableDetailRow({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54))),
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: '\$', contentPadding: EdgeInsets.zero),
                )
              : Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87)),
        ),
      ],
    );
  }
}
