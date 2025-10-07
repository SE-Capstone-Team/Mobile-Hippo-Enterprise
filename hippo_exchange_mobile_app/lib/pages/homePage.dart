import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';

// Model classes for items
class ItemModel {
  final String id;
  final String name;
  final String description;
  final String lenderName;
  final String imageUrl;
  final bool isAvailable;

  ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.lenderName,
    required this.imageUrl,
    this.isAvailable = true,
  });

  // Factory constructor to create ItemModel from Firestore document
  factory ItemModel.fromFirestore(String docId, Map<String, dynamic> data) {
    return ItemModel(
      id: docId,
      name: data['name'] ?? 'Unnamed Item',
      description: data['desc'] ?? '',
      lenderName: 'Loading...', // Will be populated separately
      imageUrl: data['picture'] ?? 'assets/images/HippoExchangeLogo.png',
      isAvailable: !(data['isLent'] ?? false),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _useFirebaseData = true; // Toggle between Firebase and demo data
  final AuthService _authService = AuthService();
  
  // Demo data - fallback when Firebase is not connected
  List<ItemModel> _demoItems = [
    ItemModel(
      id: '1',
      name: 'Harbor Freight Engineer\'s Hammer',
      description: 'Heavy-duty hammer perfect for construction work. Well-maintained and ready to use.',
      lenderName: 'Dexter Morgan',
      imageUrl: 'assets/images/Hammer.webp',
    ),
    ItemModel(
      id: '2',
      name: 'Justin Men\'s Conductor 8" Boots',
      description: 'Comfortable steel-toe boots, size 10. Great for outdoor work and construction.',
      lenderName: 'Jesus Martinez',
      imageUrl: 'assets/images/boots.jpg',
    ),
    ItemModel(
      id: '3',
      name: 'Hercules Compact Drill Kit',
      description: 'Complete drill kit with various bits. Perfect for home improvement projects.',
      lenderName: 'Hannah Davis',
      imageUrl: 'assets/images/Drill.webp',
    ),
    ItemModel(
      id: '4',
      name: 'Global Carry-On Spinner',
      description: 'Lightweight luggage perfect for travel. TSA approved size with smooth rolling wheels.',
      lenderName: 'Sarah Johnson',
      imageUrl: 'assets/images/Carryon Spinner.webp',
    ),
    ItemModel(
      id: '5',
      name: 'The Martian - Hardback',
      description: 'Popular science fiction novel in excellent condition. Great for book lovers.',
      lenderName: 'Mike Chen',
      imageUrl: 'assets/images/TheMartian.jpg',
    ),
    ItemModel(
      id: '6',
      name: 'Diamond Necklace',
      description: 'Elegant jewelry piece for special occasions. Handle with care.',
      lenderName: 'Emily Rose',
      imageUrl: 'assets/images/Diamond Necklace.webp',
    ),
    ItemModel(
      id: '7',
      name: 'Foldable Baby Stroller',
      description: 'Compact and lightweight stroller. Easy to fold and transport.',
      lenderName: 'Jennifer Wilson',
      imageUrl: 'assets/images/Stroller.webp',
    ),
    ItemModel(
      id: '8',
      name: 'Heavy Duty Stapler',
      description: 'Professional-grade stapler for office or home use. Includes staples.',
      lenderName: 'Robert Kim',
      imageUrl: 'assets/images/Stapler.jpg',
    ),
    ItemModel(
      id: '9',
      name: 'Camping Tent',
      description: 'Four-person tent perfect for camping trips. Waterproof and easy to set up.',
      lenderName: 'Alex Thompson',
      imageUrl: 'assets/images/Tent.webp',
    ),
    ItemModel(
      id: '10',
      name: 'HD Projector',
      description: 'High-definition projector for presentations or movie nights. Includes cables.',
      lenderName: 'Lisa Wang',
      imageUrl: 'assets/images/projector.jpg',
    ),
  ];

  List<ItemModel> get _filteredDemoItems {
    if (_searchQuery.isEmpty) {
      return _demoItems;
    }
    return _demoItems.where((item) {
      return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             item.lenderName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Hippo ',
                style: TextStyle(
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
              TextSpan(
                text: 'Home',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Data source toggle button
          PopupMenuButton<String>(
            icon: Icon(
              _useFirebaseData ? Icons.cloud : Icons.visibility,
              color: Color(0xFF93b9e1),
            ),
            tooltip: _useFirebaseData ? 'Using Firebase Data' : 'Using Demo Data',
            onSelected: (value) {
              setState(() {
                _useFirebaseData = value == 'firebase';
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'firebase',
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud,
                      color: _useFirebaseData ? Color(0xFF93b9e1) : Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Firebase Data',
                      style: TextStyle(
                        color: _useFirebaseData ? Color(0xFF93b9e1) : Colors.black,
                        fontWeight: _useFirebaseData ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (_useFirebaseData) ...[
                      SizedBox(width: 8),
                      Icon(Icons.check, color: Color(0xFF93b9e1), size: 16),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'demo',
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      color: !_useFirebaseData ? Colors.orange : Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Demo Data',
                      style: TextStyle(
                        color: !_useFirebaseData ? Colors.orange : Colors.black,
                        fontWeight: !_useFirebaseData ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (!_useFirebaseData) ...[
                      SizedBox(width: 8),
                      Icon(Icons.check, color: Colors.orange, size: 16),
                    ],
                  ],
                ),
              ),
            ],
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
                border: Border.all(color: Color(0xFF93b9e1).withOpacity(0.3)),
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
                  prefixIcon: Icon(Icons.search, color: Color(0xFF93b9e1)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: _useFirebaseData ? _buildFirebaseItemsList() : _buildDemoItemsList(),
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
                  color: Colors.red[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading items',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _useFirebaseData = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF93b9e1),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Use Demo Data'),
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
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _useFirebaseData = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF93b9e1),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('View Demo Data'),
                ),
              ],
            ),
          );
        }
        
        var docs = snapshot.data!.docs;
        
        // Filter items based on search query
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data();
            final name = (data['name'] ?? '').toString().toLowerCase();
            final desc = (data['desc'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery.toLowerCase()) ||
                   desc.contains(_searchQuery.toLowerCase());
          }).toList();
        }
        
        if (docs.isEmpty && _searchQuery.isNotEmpty) {
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
        
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
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

  // Method to build demo items list
  Widget _buildDemoItemsList() {
    final items = _filteredDemoItems;
    
    if (items.isEmpty && _searchQuery.isNotEmpty) {
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle button
        Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Showing demo data - Switch to Firebase',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _useFirebaseData = true;
                          });
                        },
                        child: Text(
                          'Switch',
                          style: TextStyle(color: Color(0xFF93b9e1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ItemCard(
                item: item,
                onBorrow: () => _borrowDemoItem(item),
              );
            },
          ),
        ),
      ],
    );
  }

  void _borrowDemoItem(ItemModel item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo: Borrowing "${item.name}" - Firebase integration available'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Switch to Firebase',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _useFirebaseData = true;
            });
          },
        ),
      ),
    );
  }

  void _borrowFirebaseItem(String itemId, Map<String, dynamic> data) async {
    try {
      // TODO: Implement actual borrowing logic with user authentication
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Borrowing "${data['name']}" - Implementation in progress'),
          backgroundColor: Color(0xFF93b9e1),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      
      // Future implementation:
      // await _authService.startBorrow(
      //   itemId: itemId,
      //   borrowerUid: currentUser.uid,
      //   dueAt: DateTime.now().add(Duration(days: 7)),
      // );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Reusable ItemCard widget - ready for database integration
class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onBorrow;

  const ItemCard({
    super.key,
    required this.item,
    required this.onBorrow,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    child: Image.asset(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Color(0xFF93b9e1).withOpacity(0.1),
                          child: Icon(
                            Icons.inventory_2,
                            color: Color(0xFF93b9e1),
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lender: ${item.lenderName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF93b9e1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.isAvailable 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isAvailable ? 'Available' : 'Not Available',
                          style: TextStyle(
                            fontSize: 12,
                            color: item.isAvailable ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.description.isNotEmpty) ...[
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
                item.description,
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
                  backgroundColor: item.isAvailable 
                      ? Color(0xFF93b9e1) 
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: item.isAvailable ? onBorrow : null,
                child: Text(
                  item.isAvailable ? 'Borrow Item' : 'Not Available',
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
    final isAvailable = !(itemData['isLent'] ?? false);
    final imageUrl = itemData['picture'] ?? 'assets/images/HippoExchangeLogo.png';

    return Card(
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
                    child: imageUrl.startsWith('assets/')
                        ? Image.asset(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackIcon();
                            },
                          )
                        : (imageUrl.startsWith('http')
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildFallbackIcon();
                                },
                              )
                            : _buildFallbackIcon()),
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
                      FutureBuilder<DocumentSnapshot>(
                        future: (itemData['ownerId'] as DocumentReference?)?.get(),
                        builder: (context, ownerSnapshot) {
                          if (ownerSnapshot.hasData && ownerSnapshot.data!.exists) {
                            final ownerData = ownerSnapshot.data!.data() as Map<String, dynamic>?;
                            final firstName = ownerData?['firstName'] ?? '';
                            final lastName = ownerData?['lastName'] ?? '';
                            final fullName = '$firstName $lastName'.trim();
                            return Text(
                              'Lender: ${fullName.isNotEmpty ? fullName : 'Unknown'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF93b9e1),
                                fontWeight: FontWeight.w500,
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
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAvailable 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isAvailable ? 'Available' : 'Currently Borrowed',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAvailable ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
                  backgroundColor: isAvailable 
                      ? Color(0xFF93b9e1) 
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: isAvailable ? onBorrow : null,
                child: Text(
                  isAvailable ? 'Borrow Item' : 'Not Available',
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
}
