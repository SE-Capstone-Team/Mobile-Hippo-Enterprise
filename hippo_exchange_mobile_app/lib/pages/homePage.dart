import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: AuthService().streamAvailableItems(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Color(0xFF93b9e1)));
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading items: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
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
                          const SizedBox(height: 16),
                          Text(
                            'No items available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  var items = snapshot.data!.docs;
                  
                  // Filter items based on search query
                  if (_searchQuery.isNotEmpty) {
                    items = items.where((doc) {
                      final data = doc.data();
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();
                  }
                  
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
                          const SizedBox(height: 16),
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
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final doc = items[index];
                      final data = doc.data();
                      return _buildItemCard(doc.id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(String itemId, Map<String, dynamic> data) {
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
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF93b9e1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Color(0xFF93b9e1),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unnamed Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<DocumentSnapshot>(
                        future: (data['ownerId'] as DocumentReference?)?.get(),
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
                    ],
                  ),
                ),
              ],
            ),
            if (data['desc'] != null && data['desc'].toString().isNotEmpty) ...[
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
                data['desc'] ?? '',
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
                onPressed: () => _borrowItem(itemId),
                child: Text(
                  'Borrow Item',
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

  void _borrowItem(String itemId) {
    // TODO: Implement borrow functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Borrow functionality will be implemented'),
        backgroundColor: Color(0xFF93b9e1),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const SectionHeader({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 24),
          ],
        ),
      ),
    );
  }
}

class LentCircle extends StatelessWidget {
  final LentItem item;
  const LentCircle({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120, // allows two-line caption
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Color(0xFF93b9e1).withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: ClipOval(
              child: Container(
                color: const Color(0xFFF2F2F2),
                child: Image.asset(item.imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class BorrowedCard extends StatelessWidget {
  final BorrowedItem item;
  const BorrowedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200, // CHANGED: was 173 → wider for text space
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: open details
          },
          child: Padding(
            padding: const EdgeInsets.all(10), // CHANGED: was 8 before
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Color(0xFF93b9e1).withOpacity(0.3),
                      width: 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 3 / 2, // CHANGED: less tall
                      child: Image.asset(item.imageUrl, fit: BoxFit.contain),//CHANGED: from cover to contain to make sure the picture fits in the box
                    ),
                  ),
                ),
                const SizedBox(height: 8), // CHANGED: was 5 → more breathing room

                // Meta line
                Text(
                  'From: ${item.fromName}',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 14, // CHANGED: was 11
                    color: Colors.black87,
                    fontWeight: FontWeight.w500, // ADDED emphasis
                  ),
                ),

                const SizedBox(height: 6), // CHANGED: was 3

                // Title (main item name)
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold, // CHANGED: was w700
                    fontSize: 18, // CHANGED: was 12
                  ),
                ),

                const SizedBox(height: 6), // CHANGED: was 3

                // Duration
                Text(
                  item.duration,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16, // CHANGED: was 11
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------- Demo data & models ---------- */

class LentItem {
  final String imageUrl;
  final String caption;
  const LentItem({required this.imageUrl, required this.caption});
}

class BorrowedItem {
  final String imageUrl;
  final String fromName;
  final String title;
  final String duration; // e.g., "1 week", "6 days"
  const BorrowedItem({
    required this.imageUrl,
    required this.fromName,
    required this.title,
    required this.duration,
  });
}

const demoLent = <LentItem>[
  LentItem(
    imageUrl:
        'assets/images/Carryon Spinner.webp',
    caption: 'Global\nCarry-On Spinner',
  ),
  LentItem(
    imageUrl:
        'assets/images/TheMartian.jpg',
    caption: 'The Martian –\nHardback',
  ),
  LentItem(
    imageUrl:
        'assets/images/Diamond Necklace.webp',
    caption: 'Diamond\nNecklace',
  ),
  LentItem(
    imageUrl:
        'assets/images/Stroller.webp',
    caption: 'Foldable Baby\nStroller',
  ),
];

const demoBorrowed = <BorrowedItem>[
  BorrowedItem(
    imageUrl:
        'assets/images/Hammer.webp',
    fromName: 'Dexter',
    title: "Harbor Freight Engineer's Hammer",
    duration: '1 week',
  ),
  BorrowedItem(
    imageUrl:
        'assets/images/boots.jpg',
    fromName: 'Jesus',
    title: "Justin Men's Conductor 8\" Boots",
    duration: '6 days',
  ),
  BorrowedItem(
    imageUrl:
        'assets/images/Drill.webp',
    fromName: 'Hannah',
    title: 'Hercules Compact Drill Kit',
    duration: '3 days',
  ),
];
