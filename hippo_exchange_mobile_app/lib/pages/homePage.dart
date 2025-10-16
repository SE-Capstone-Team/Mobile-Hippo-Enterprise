import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';
import 'package:hippo_exchange_mobile_app/pages/viewItem.dart';

// NEW: notifications imports
import 'package:hippo_exchange_mobile_app/pages/notifications_inbox.dart';
import 'package:hippo_exchange_mobile_app/services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final AuthService _authService = AuthService();
  
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5), // Off-white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        title: RichText(
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Hippo ',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: 'Exchange: ',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF93b9e1),
                ),
              ),
              TextSpan(
                text: 'Home',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        // NEW: notification bell with unread badge
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

        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Color(0xFF93b9e1).withOpacity(0.2),
            height: 1.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: Color(0xFF93b9e1).withOpacity(0.3)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon:
                  Icon(Icons.search, color: Color(0xFF93b9e1)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Subtitle
            Text(
              'Items for you',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // Items List
            Expanded(
              child: _buildFirebaseItemsList(),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build Firebase-connected items list
  Widget _buildFirebaseItemsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _authService.streamAvailableItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF93b9e1)),
                SizedBox(height: 16),
                Text(
                  'Loading items from database...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AuthService().mapFirebaseError(snapshot.error!),
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No items available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Be the first to share an item!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }
        
        // Filter docs to exclude items that match the search query and exclude current user's items
        final currentUser = FirebaseAuth.instance.currentUser;
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          final itemName = (data['name'] ?? '').toLowerCase();
          final itemDesc = (data['desc'] ?? '').toLowerCase();
          
          // Check if item matches search query
          final matchesSearch = _searchQuery.isEmpty || 
              itemName.contains(_searchQuery) || 
              itemDesc.contains(_searchQuery);
          
          // Check if item is not owned by current user
          bool notOwnedByCurrentUser = true;
          if (currentUser != null) {
            final ownerId = data['ownerId'];
            if (ownerId is DocumentReference) {
              // Compare the document ID from the reference
              notOwnedByCurrentUser = ownerId.id != currentUser.uid;
            }
          }
          
          return matchesSearch && notOwnedByCurrentUser;
        }).toList();
        
        if (filteredDocs.isEmpty && _searchQuery.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No items found for "$_searchQuery"',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No available items to borrow',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data();

            // Add safety check for required fields
            if (data['name'] == null) {
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  'Invalid item data (ID: ${doc.id})',
                  style: TextStyle(color: Colors.red[700]),
                ),
              );
            }

            return FirebaseItemCard(
              itemId: doc.id,
              itemData: data,
              onBorrow: () => _borrowFirebaseItem(doc.id, data),
            );
          },
        );
      },
    );
  }

  void _borrowFirebaseItem(String itemId, Map<String, dynamic> data) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewItemPage(
          itemId: itemId,
          itemData: data,
          showBorrowButton: true, // Enable borrowing from home page
        ),
      ),
    );
  }
}

// Firebase-specific ItemCard widget that handles Firestore data
class FirebaseItemCard extends StatelessWidget {
  final String itemId;
  final Map<String, dynamic> itemData;
  final VoidCallback onBorrow;

  const FirebaseItemCard({
    super.key,
    required this.itemId,
    required this.itemData,
    required this.onBorrow,
  });

  @override
  Widget build(BuildContext context) {
    final name = itemData['name'] ?? 'Unnamed Item';
    final description = itemData['desc'] ?? '';
    final imageUrl = itemData['picture'];
    final pricePerDay = itemData['pricePerDay'] as num?;
    final isFree = pricePerDay == null || pricePerDay <= 0;

    return Card(
      color: Colors.white, // White card background
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Image/Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(0xFF93b9e1).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
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
                                _buildFallbackIcon(),
                          )
                        : _buildFallbackIcon(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildLenderInfo(itemData),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Price Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isFree
                        ? Colors.green.withOpacity(0.15)
                        : Color(0xFF93b9e1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isFree
                        ? 'Free!'
                        : '\$${pricePerDay?.toStringAsFixed(2)}/day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isFree
                          ? Colors.green[700]
                          : Color(0xFF93b9e1),
                    ),
                  ),
                ),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Description:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF93b9e1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onBorrow,
                child: Text(
                  'View Item',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: Color(0xFF93b9e1).withOpacity(0.1),
      child: Icon(
        Icons.inventory_2,
        color: Color(0xFF93b9e1),
        size: 24,
      ),
    );
  }

  Future<String> _getOwnerName(DocumentReference ownerId) async {
    try {
      // Use a new FirebaseFirestore instance to get owner info using the same database config
      final tempDb = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'inventory-db',
      );
      final ownerDoc = await tempDb.collection('profiles').doc(ownerId.id).get();
      if (ownerDoc.exists) {
        final ownerData = ownerDoc.data();
        final firstName = ownerData?['firstName'] ?? '';
        final lastName = ownerData?['lastName'] ?? '';
        final ownerName = '$firstName $lastName'.trim();
        return ownerName.isNotEmpty ? ownerName : 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      debugPrint("HomePage: Error fetching owner name: $e");
      return 'Unavailable';
    }
  }

  Widget _buildLenderInfo(Map<String, dynamic> itemData) {
    final ownerId = itemData['ownerId'];
    
    // Debug: Print the ownerId to understand its structure
    debugPrint("HomePage: ownerId type: ${ownerId.runtimeType}, value: $ownerId");
    
    // Handle different data types for ownerId
    if (ownerId == null) {
      return Text(
        'Lender: Unknown',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      );
    }

    // If ownerId is a DocumentReference, fetch the owner data
    if (ownerId is DocumentReference) {
      return FutureBuilder<String>(
        future: _getOwnerName(ownerId),
        builder: (context, ownerSnapshot) {
          if (ownerSnapshot.hasData) {
            return Text(
              'Lender: ${ownerSnapshot.data}',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF93b9e1),
                fontWeight: FontWeight.w500,
              ),
            );
          }

          if (ownerSnapshot.hasError) {
            debugPrint("HomePage: Owner lookup error: ${ownerSnapshot.error}");
            return Text(
              'Lender: Unavailable',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            );
          }

          return Text(
            'Lender: Loading...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          );
        },
      );
    }

    // If ownerId is a String (legacy data), display it directly or show placeholder
    if (ownerId is String) {
      return Text(
        'Lender: ${ownerId.isNotEmpty ? ownerId : 'Unknown'}',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF93b9e1),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Fallback for any other data type
    return Text(
      'Lender: Unknown',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
      ),
    );
  }
}
