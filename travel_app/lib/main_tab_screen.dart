import 'package:flutter/material.dart';
import 'package:travel_app/view/Favorite/my_favorite_page.dart';
import 'package:travel_app/view/My_page/my_page.dart';
import 'package:travel_app/view/home_booking/home.dart';
import 'package:travel_app/view/shorts/VideosPage.dart';
import 'package:travel_app/view/shorts/shorts_reels_page.dart'; // 현재 있는 비디오 페이지

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int currentIndex = 0;
  
  final List<Widget> pages = [
    const Home(),           // 기존 홈
    const ShortsReelsPage(),     // 기존 비디오
    const MyFavoritePage(),    // 새로 만들기
    const MyPage(),    // 새로 만들기
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: '숏츠'),
          BottomNavigationBarItem(icon: Icon(Icons.airplane_ticket_outlined), label: '내 여행'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
      ),
    );
  }
}
