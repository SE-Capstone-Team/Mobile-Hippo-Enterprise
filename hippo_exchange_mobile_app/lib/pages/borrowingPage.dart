import 'package:flutter/material.dart';

// Widget for a single borrowed item row
class BorrowedItemRow extends StatelessWidget {
  final BorrowedItem item;
  const BorrowedItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: SizedBox(
        height: 64,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl.isEmpty
                    ? const Icon(Icons.image, size: 40, color: Colors.grey)
                    : Image.asset(
                        item.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.timeAgo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lent by: ${item.lender}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model for a borrowed item that will be pulled from DB
class BorrowedItem {
  final String imageUrl;
  final String name;
  final String lender;
  final String timeAgo;
  BorrowedItem({
    required this.imageUrl,
    required this.name,
    required this.lender,
    required this.timeAgo,
  });
}

class BorrowingPage extends StatefulWidget {
  const BorrowingPage({super.key});

  @override
  State<BorrowingPage> createState() => _BorrowingPageState();
}

class _BorrowingPageState extends State<BorrowingPage> {
  // Simulate fetching from a database (replace with your DB logic)
  var fltCreditCount =
      0; // this represents the credits at the bottom of the page
  Future<List<BorrowedItem>> fetchBorrowedItems() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      BorrowedItem(imageUrl: 'assets/images/Hammer.webp',
          name: 'Drill',
          lender: 'Dexter',
          timeAgo: '2d'
      ),
      BorrowedItem(
        imageUrl: 'assets/images/boots.jpg',
        name: 'Justin Men\'s Conductor 8\" Boots',
        lender: 'Jesus',
        timeAgo: '1w',
      ),
      BorrowedItem(
        imageUrl: 'assets/images/Drill.webp',
        name: 'Hercules Compact Drill Kit',
        lender: 'Hannah',
        timeAgo: '3w',
      ),
      BorrowedItem(imageUrl: 'assets/images/Tent.webp',
          name: 'Tent',
          lender: 'Dana',
          timeAgo: '5d'
      ),
      BorrowedItem(
        imageUrl: 'assets/images/Stapler.jpg',
        name: 'Red Swingline Stapler',
        lender: 'Milton',
        timeAgo: '4h',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        // APP BAR THAT CONTAINS THE TITLE
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Align(
            child: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              titleSpacing: 20,
              // PAGE TITLE
              title: const Text(
                "Borrowing",
                style: TextStyle(fontSize: 40, color: Colors.black),
                textAlign: TextAlign.left,
              ),
              iconTheme: const IconThemeData(color: Colors.black),
            ),
          ),
        ),

        // LIST OF BORROWED OBJECTS START
        body: Container(
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 20), // Space between app bar and list
              Expanded(
                child: FutureBuilder<List<BorrowedItem>>(
                  future: fetchBorrowedItems(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No items borrowed.'));
                    }
                    final items = snapshot.data!;
                    return Column(
                      children: [
                        const Divider(
                          color: Color(0xFFE0E0E0), // Colors.grey[300]
                          thickness: 1.2,
                          height: 0,
                          indent: 0,
                          endIndent: 0,
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 0,
                            ),
                            itemCount: items.length,
                            separatorBuilder: (context, index) => const Divider(
                              color: Color(0xFFE0E0E0), // Colors.grey[300]
                              thickness: 1.2,
                              height: 0,
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return BorrowedItemRow(item: item);
                            },
                          ),
                        ),
                        const Divider(
                          color: Color(0xFFE0E0E0), // Colors.grey[300]
                          thickness: 1.2,
                          height: 0,
                          indent: 0,
                          endIndent: 0,
                        ),
                      ],
                    );
                  },
                ),
              ),
              // bottom box for what i belive is currency
              Container(
                width: double.infinity,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400, width: 1.2),
                ),
                // child: Center(child: Text("Currency: $fltCreditCount", style: TextStyle(fontSize: 20)))
              ),
            ],
          ),
        ),

        // LIST OF OBJECTS END
      ),
    );
  }
}
