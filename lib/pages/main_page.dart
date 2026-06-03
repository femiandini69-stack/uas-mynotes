import 'package:flutter/material.dart';

import 'home_page.dart';
import 'favorite_page.dart';
import 'archive_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomePage(),
    FavoritePage(),
    ArchivePage(),
  ];

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFFFF7FB);
    const Color primaryPink = Color(0xFFE992BD);
    const Color textSoft = Color(0xFF9D7C8D);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      body: pages[selectedIndex],

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: primaryPink.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            backgroundColor: Colors.white,
            selectedItemColor: primaryPink,
            unselectedItemColor: textSoft,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border_rounded),
                activeIcon: Icon(Icons.favorite_rounded),
                label: 'Favorite',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.archive_outlined),
                activeIcon: Icon(Icons.archive_rounded),
                label: 'Arsip',
              ),
            ],
          ),
        ),
      ),
    );
  }
}