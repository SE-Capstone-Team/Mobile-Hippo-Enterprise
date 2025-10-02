import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/pages/borrowingPage.dart';
import 'package:hippo_exchange_mobile_app/pages/lendingPage.dart';


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Optional AppBar (mock shows just status bar; SafeArea handles it)
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
        SliverToBoxAdapter(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: RichText(

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
                  text: 'Exchange',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF93b9e1),
                ),
              ),
            ],
          ),
        ),
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
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: BorrowedCard(item: demoBorrowed[i]),
                ),
                childCount: demoBorrowed.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
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
