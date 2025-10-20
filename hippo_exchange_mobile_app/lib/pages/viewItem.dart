import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
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
  Map<String, dynamic>? _ownerData;
  bool _isLoading = true;
  String? _errorMessage;

  // State for UI interactivity
  bool _isEditing = false;
  bool _isDescriptionExpanded = true;
  bool _isDetailsExpanded = true;

  // New image file
  File? _newImageFile;

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
      _loadOwnerData();
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
      final itemData = await AuthService().getItemWithCache(widget.itemId);

      if (itemData != null) {
        if (mounted) {
          setState(() {
            _itemData = itemData;
            _initializeControllers();
            _isLoading = false;
          });
          _loadOwnerData();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Item not found';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AuthService().mapFirebaseError(e);
        });
      }
    }
  }

  Future<void> _loadOwnerData() async {
    if (_itemData != null && _itemData!['ownerId'] is DocumentReference) {
      try {
        final ownerId = (_itemData!['ownerId'] as DocumentReference).id;
        final _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: AuthService.kFirestoreDbId);
        final ownerProfile = await _db.collection('profiles').doc(ownerId).get();

        if (mounted) {
          setState(() {
            _ownerData = ownerProfile.data();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _ownerData = null;
            _errorMessage = 'Could not load owner details: ${e.toString()}';
          });
        }
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _newImageFile = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _borrowItem() async {
    setState(() {
      _errorMessage = null;
    });
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
      Navigator.of(context).pop(); // Go back to home page
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      setState(() {
        _errorMessage = AuthService().mapFirebaseError(e);
      });
    }
  }

  Future<void> _returnItem() async {
    setState(() {
      _errorMessage = null;
    });
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
        Navigator.of(context).pop(); // Go back
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService().mapFirebaseError(e);
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_isEditing) return;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final newDesc = _descController.text;
    double newPrice = double.tryParse(_priceController.text) ?? 0.0;
    if (newPrice < 0) {
      setState(() {
        _errorMessage = "Price cannot be negative.";
        _isLoading = false;
      });
      return;
    }

    try {
      await AuthService().updateItem(
        widget.itemId,
        {
          'desc': newDesc,
          'pricePerDay': newPrice,
        },
        _newImageFile, // Pass the new image file if it exists
      );

      // Reload data to show all changes, including new image URL
      await _loadItemData();

      setState(() {
        _isEditing = false;
        _newImageFile = null;
        _isLoading = false; // Turn off loader after reload
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService().mapFirebaseError(e);
          _isLoading = false; // Turn off loader on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _itemData != null &&
        _itemData!['ownerId'] is DocumentReference &&
        (_itemData!['ownerId'] as DocumentReference).id == FirebaseAuth.instance.currentUser?.uid;
    final isLent = _itemData != null && _itemData!['isLent'] == true;

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
          GestureDetector(
            onTap: _isEditing ? _showImageSourceActionSheet : null,
            child: Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF2F2F2),
                border: Border.all(color: const Color(0xFF93B9E1).withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _newImageFile != null
                    ? Image.file(_newImageFile!, fit: BoxFit.cover)
                    : (imageUrl != null
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
                        : const Icon(Icons.image, size: 80, color: Color(0xFF93B9E1))),
              ),
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
              child: ElevatedButton.icon(
                onPressed: _borrowItem,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: const Text('Borrow Item', style: TextStyle(color: Colors.white, fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF93B9E1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (isBorrower)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _returnItem,
                icon: const Icon(Icons.assignment_return, color: Colors.white),
                label: const Text('Return Item', style: TextStyle(color: Colors.white, fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_errorMessage != null)
            Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required Widget child,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          child,
        ],
        const Divider(height: 32, thickness: 1),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: statusColor ?? Colors.black,
              fontWeight: statusColor != null ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableDetailRow({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('$label:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        const SizedBox(width: 8),
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  textAlign: TextAlign.end,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                )
              : Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.end,
                ),
        ),
      ],
    );
  }

  Widget _buildOwnerName() {
    if (_ownerData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final ownerName = _ownerData!['firstName'] ?? 'Unknown Owner';
    final profilePictureUrl = _ownerData!['pfp'];

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF93B9E1),
          backgroundImage: profilePictureUrl != null ? NetworkImage(profilePictureUrl) : null,
          child: profilePictureUrl == null
              ? const Icon(
                  Icons.person,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Text('Owner:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        Expanded(
          child: Text(
            ownerName,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
