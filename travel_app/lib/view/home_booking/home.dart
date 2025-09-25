import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/Widget/flight_result.dart';
import 'package:travel_app/Widget/flight_search.dart';
import 'package:travel_app/Widget/package_widget.dart';
import 'package:travel_app/Widget/user_info.dart';
import 'package:travel_app/view/My_page/inquery_list_page.dart';
import 'package:travel_app/view/home_booking/chat_bot_bottom_sheet.dart';
import 'package:travel_app/vm/home_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:travel_app/vm/inquery_provider.dart';

// ======================
// 챗 메시지 모델
// ======================
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// ======================
// 홈 화면
// ======================
class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchStateProvider);
    final flights = ref.watch(flightsProvider);
    final user = FirebaseAuth.instance.currentUser;
    final userInfo = ref.watch(userInfoProvider);
    final pendingCount = ref.watch(pendingReplyCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF003366), // 네이비 블루
      body: CustomScrollView(
        slivers: [
          // 커스텀 앱바
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF003366),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(color: Color(0xFF003366)),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SizedBox(height: 20,),
                        // 헤더 섹션
                        Row(
                          children: [
                            // 유저 프로필
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.3),
                                image: user?.photoURL != null
                                    ? DecorationImage(
                                        image: NetworkImage(user!.photoURL!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: user?.photoURL == null
                                  ? const Icon(Icons.person,
                                      color: Colors.white, size: 24)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome Back",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  userInfo.when(
                                    data: (data) {
                                      final name =
                                          data?['name'] ??
                                          (user?.email ?? "Traveler");
                                      return Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                                    loading: () => const Text(
                                      "Loading...",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    error: (_, __) => Text(
                                      user?.email ?? "Traveler",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 알림 버튼
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const InqueryListPage(),
                                  ),
                                );
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),

                                  // 🔔 답변 대기중 카운트 표시
                                  if (pendingCount > 0)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          "$pendingCount",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // 메인 타이틀
                        const Text(
                          "Book your\nFlight Ticket",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              collapseMode: CollapseMode.pin,
            ),
          ),

          // 메인 콘텐츠
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // 항공편 검색 카드
                    Container(
                      decoration: _modernCardDecoration(),
                      child: const FlightSearch(),
                    ),
                    const SizedBox(height: 24),

                    // 검색 결과
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: searchState
                          ? Container(
                              key: ValueKey(flights.hashCode),
                              decoration: _modernCardDecoration(),
                              child: const FlightResult(),
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),

                    if (searchState) const SizedBox(height: 24),

                    // 여행 패키지
                    Container(
                      decoration: _modernCardDecoration(),
                      child: const PackageWidget(),
                    ),

                    const SizedBox(height: 24),

                    // 서비스 카드
                    _buildModernServiceCards(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // 플로팅 액션 버튼 - 챗봇
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          onPressed: () => _showChatBot(context),
          backgroundColor: const Color(0xFFFFD700), // 옐로우
          elevation: 3,
          shape: const CircleBorder(),
          child: const Icon(Icons.chat_bubble,
              color: Color(0xFF003366), size: 24), // 블루 아이콘
        ),
      ),
    );
  }

  // 카드 데코레이션
  BoxDecoration _modernCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF003366).withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  void _showChatBot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ChatBotBottomSheet(),
    );
  }

  // 서비스 카드들
  Widget _buildModernServiceCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            "Travel Services",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A202C),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildModernServiceCard(
                "Check-in",
                "Online check-in available",
                Icons.flight_takeoff,
                const Color(0xFF003366), // 블루
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernServiceCard(
                "Flight Status",
                "Track your flight",
                Icons.schedule,
                const Color(0xFF48BB78),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernServiceCard(
                "Baggage",
                "Check allowance",
                Icons.luggage,
                const Color(0xFFFFD700), // 옐로우
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernServiceCard(
                "Loyalty",
                "Earn miles",
                Icons.card_giftcard,
                const Color(0xFF9F7AEA),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernServiceCard(
      String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
