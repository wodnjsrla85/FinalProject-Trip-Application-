import 'package:flutter/material.dart';
import 'package:travel_app/view/Favorite/my_favorite_page.dart';
import 'package:travel_app/view/My_page/my_page.dart';
import 'package:travel_app/view/home_booking/home.dart';
import 'package:travel_app/view/shorts/shorts_reels_page.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int currentIndex = 0;

  final List<Widget> pages = const [
    Home(),
    ShortsReelsPage(),
    MyFavoritePage(),
    MyPage(),
  ];

  final Color navyColor = const Color(0xFF003366); // 메인 네이비
  final Color yellowColor = const Color(0xFFFFD700); // 옐로우 포인트

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            onTap: (index) => setState(() => currentIndex = index),
            selectedItemColor: yellowColor,   // ✅ 선택된 탭: 옐로우
            unselectedItemColor: navyColor,   // ✅ 비선택 탭: 네이비
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 11,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.flight_takeoff),
                label: "홈",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.ondemand_video),
                label: "숏츠",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bookmark_border),
                label: "저장",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: "프로필",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
