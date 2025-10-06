import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/pages/homePage.dart';
import 'package:hippo_exchange_mobile_app/pages/borrowedPage.dart';
import 'package:hippo_exchange_mobile_app/pages/myItemsPage.dart';
import 'package:hippo_exchange_mobile_app/pages/profilePage.dart'; // Uncomment and implement when ready

class MainPostLoginPage extends StatefulWidget {
  const MainPostLoginPage({super.key});

  @override
  State<MainPostLoginPage> createState() => _MainPostLoginPageState();
}

class _MainPostLoginPageState extends State<MainPostLoginPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    BorrowingPage(),
    LendingPage(),
    UserProfilePage(), // Uncomment and implement when ready
    Center(child: Text('Profile Page (Coming Soon)')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Blue divider after header
          Container(
            height: 1,
            color: Color(0xFF93b9e1).withOpacity(0.3),
          ),
          // Main content
          Expanded(child: _pages[_selectedIndex]),
          // Blue divider before nav bar
          Container(
            height: 1,
            color: Color(0xFF93b9e1).withOpacity(0.3),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0.5,
        selectedItemColor: Color(0xFF1a6ec7),
        unselectedItemColor: Color(0xFF93b9e1),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store_mall_directory_rounded), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake),
            label: 'Borrowed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shelves),
            label: 'My Items',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
