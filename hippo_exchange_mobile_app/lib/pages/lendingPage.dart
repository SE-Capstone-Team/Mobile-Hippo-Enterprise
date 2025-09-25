import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase_service.dart';

// Widget for a single lent item row

class LentItemRow extends StatelessWidget {
  final LentItem item;
  const LentItemRow({super.key, required this.item});

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
                    'Borrowed by: ${item.borrower}',
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

// Model for a lent item that will be pulled from DB
class LentItem {
  final String imageUrl;
  final String name;
  final String borrower;
  final String timeAgo;
  LentItem({
    required this.imageUrl,
    required this.name,
    required this.borrower,
    required this.timeAgo,
  });
}

class Lendingpage extends StatefulWidget {
  const Lendingpage({super.key});

  @override
  State<Lendingpage> createState() => _LendingPageState();
}

class _LendingPageState extends State<Lendingpage> {
  // Simulate fetching from a database (replace with your DB logic)
  var fltCreditCount =
      0; // this represents the credits at the bottom of the page
  Future<List<LentItem>> fetchLentItems() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      LentItem(imageUrl: 'assets/images/Carryon Spinner.webp', name: 'Global Carry-On Spinner', borrower: 'Alice', timeAgo: '2d'),
      LentItem(
        imageUrl: 'assets/images/TheMartian.jpg',
        name: 'The Martian -Hardback',
        borrower: 'Bob',
        timeAgo: '1w',
      ),
      LentItem(imageUrl: 'assets/images/Diamond Necklace.webp', name: 'Diamond Necklace', borrower: 'Charlie', timeAgo: '3w'),
      LentItem(imageUrl: 'assets/images/Stroller.webp', name: 'Foldable Baby Stroller', borrower: 'Dana', timeAgo: '5d'),
      LentItem(imageUrl: 'assets/images/projector.jpg', name: 'Projector', borrower: 'Eve', timeAgo: '4h'),
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
                "Lent Items",
                style: TextStyle(fontSize: 40, color: Colors.black),
                textAlign: TextAlign.left,
              ),
              iconTheme: const IconThemeData(color: Colors.black),
            ),
          ),
        ),

        // LIST OF LENT OBJECTS START
        body: Container(
          color: Colors.white,
          child: Column(
            children: [
              const SizedBox(height: 20), // Space between app bar and list
              Expanded(
                child: FutureBuilder<List<LentItem>>(
                  future: fetchLentItems(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No items lent.'));
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
                              return LentItemRow(item: item);
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
