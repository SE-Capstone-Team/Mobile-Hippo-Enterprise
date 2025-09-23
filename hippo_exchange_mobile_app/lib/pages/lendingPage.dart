import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/auth_service.dart';

// Widget for a single lent item row

class LentItemRow extends StatelessWidget {
  final LentItem item;
  const LentItemRow({Key? key, required this.item}) : super(key: key);

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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.timeAgo,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
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


class Lendingpage extends StatefulWidget{
    const Lendingpage({super.key});

  @override
  State<Lendingpage> createState() => _LendingPageState();

}

// Model for a lent item that will be pulled from DB
class LentItem {
  final String imageUrl;
  final String name;
  final String borrower;
  final String timeAgo;
  LentItem({required this.imageUrl, required this.name, required this.borrower, required this.timeAgo});
}


class _LendingPageState extends State<Lendingpage> {
  // Simulate fetching from a database (replace with your DB logic)
  
  Future<List<LentItem>> fetchLentItems() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      LentItem(
        imageUrl: '',
        name: 'Drill',
        borrower: 'Alice',
        timeAgo: '2d',
      ),
      LentItem(
        imageUrl: '',
        name: 'Lawn Mower',
        borrower: 'Bob',
        timeAgo: '1w',
      ),
      LentItem(
        imageUrl: '',
        name: 'Bike',
        borrower: 'Charlie',
        timeAgo: '3w',
      ),
      LentItem(
        imageUrl: '',
        name: 'Tent',
        borrower: 'Dana',
        timeAgo: '5d',
      ),
      LentItem(
        imageUrl: '',
        name: 'Projector',
        borrower: 'Eve',
        timeAgo: '4h',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // APP BAR THAT CONTAINS THE TITLE
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Align(
            child: AppBar(
              titleSpacing: 20,
              // PAGE TITLE
              title: const Text(
                "Lent Items",
                style: TextStyle(fontSize: 40),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        ),

        // LIST OF LENT OBJECTS START
        body: Column(
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
                          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
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
          ],
        ),
        // LIST OF OBJECTS END

        // BOTTOM NAVIGATION BAR START
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: 0,
          onTap: (index) {},
        ),
      ),
    );
  }
}