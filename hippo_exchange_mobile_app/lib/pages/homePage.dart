import 'package:flutter/material.dart';

void main() => runApp(const BorrowlyApp());

class BorrowlyApp extends StatelessWidget {
  const BorrowlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hippo Exchange',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(fontSize: 14),
          bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Optional AppBar (mock shows just status bar; SafeArea handles it)
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Home Page',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(fontSize: 24)),
              ),
            ),

            // ---- Items Lent ----
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Items Lent',
                onTap: () {
                  // TODO: push to items lent screen
                },
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140, // enough for circle + caption
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: demoLent.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, i) => LentCircle(item: demoLent[i]),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ---- Items Borrowed ----
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Items Borrowed',
                onTap: () {
                  // TODO: push to items borrowed screen
                },
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 300, // card height to show image + text like the mock
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: demoBorrowed.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) =>
                      BorrowedCard(item: demoBorrowed[i]),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),

      // ---- Bottom Navigation ----
      /*bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        height: 72,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: ''),
          NavigationDestination(icon: Icon(Icons.block_outlined), label: ''),
          NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined), label: ''),
          NavigationDestination(
              icon: Icon(Icons.notifications_none_outlined), label: ''),
          NavigationDestination(icon: Icon(Icons.person_outline), label: ''),
        ],
      ),*/
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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.w800),
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
          ClipOval(
            child: Container(
              width: 76,
              height: 76,
              color: const Color(0xFFF2F2F2),
              child: Image.network(item.imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontWeight: FontWeight.w600),
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
      width: 260, // matches mock’s card width ratio
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(item.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),

                // Meta line
                Text('Borrowed from: ${item.fromName}',
                    style: Theme.of(context).textTheme.bodySmall),

                const SizedBox(height: 4),

                // Title (2 lines)
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 8),

                // Duration
                Text(
                  'Borrowed for: ${item.duration}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontWeight: FontWeight.w600),
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
    'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?q=80&w=800',
    caption: 'Global\nCarry-On Spinner',
  ),
  LentItem(
    imageUrl:
    'https://images.unsplash.com/photo-1532012197267-da84d127e765?q=80&w=800',
    caption: 'The Martian –\nHardback',
  ),
  LentItem(
    imageUrl:
    'https://images.unsplash.com/photo-1543294001-f7cd5d7fb516?q=80&w=800',
    caption: 'Diamond\nNecklace',
  ),
  LentItem(
    imageUrl:
    'https://images.unsplash.com/photo-1519494080410-f9aa76cb4283?q=80&w=800',
    caption: 'Foldable Baby\nStroller',
  ),
];

const demoBorrowed = <BorrowedItem>[
  BorrowedItem(
    imageUrl:
    'https://images.unsplash.com/photo-1611463106254-c6b8b3a2a8f1?q=80&w=1200',
    fromName: '<name>',
    title: "Harbor Freight Engineer's Hammer",
    duration: '1 week',
  ),
  BorrowedItem(
    imageUrl:
    'https://images.unsplash.com/photo-1520256862855-398228c41684?q=80&w=1200',
    fromName: '<name>',
    title: "Justin Men's Conductor 8\" Lace-Up Boots",
    duration: '6 days',
  ),
  BorrowedItem(
    imageUrl:
    'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1200',
    fromName: '<name>',
    title: 'Hercules Compact Drill Kit',
    duration: '3 days',
  ),
];
