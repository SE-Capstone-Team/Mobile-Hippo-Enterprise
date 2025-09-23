import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/auth_service.dart';


class Lendingpage extends StatefulWidget{
    const Lendingpage({super.key});

  @override
  State<Lendingpage> createState() => _LendingPageState();

}

// Model for a lent item
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
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: SizedBox(
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
                          title: Text(item.name),
                          subtitle: Text('Borrowed by: ${item.borrower}'),
                          trailing: Text(item.timeAgo),
                        ),
                      );
                    },
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