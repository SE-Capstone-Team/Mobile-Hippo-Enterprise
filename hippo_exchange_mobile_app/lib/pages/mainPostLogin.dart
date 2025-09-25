import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/pages/homePage.dart';
import 'package:hippo_exchange_mobile_app/pages/borrowingPage.dart';
import 'package:hippo_exchange_mobile_app/pages/lendingPage.dart';
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
    Lendingpage(),
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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0.5,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Borrowing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake),
            label: 'Lending',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
