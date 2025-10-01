import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/view/My_page/flight_tracker_page.dart';
import 'package:travel_app/view/My_page/edit_profile.dart';
import 'package:travel_app/view/My_page/flights_booking_list.dart';
import 'package:travel_app/view/My_page/inquery_list_page.dart';
import 'package:travel_app/view/My_page/package_booking_List.dart';
import 'package:travel_app/view/My_page/privacy_police.dart';
import 'package:travel_app/view/My_page/terms_of_service.dart';
import 'package:travel_app/view/login/join/login.dart';
import 'package:travel_app/view/shorts/VideosPage.dart';
import 'package:travel_app/vm/inquery_provider.dart';
import 'package:travel_app/vm/shorts_provider.dart';
import 'package:travel_app/vm/user_provider.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  static const Color navy = Color(0xFF0A1D37);
  static const Color yellow = Color(0xFFFFD600);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final userAsync = ref.watch(userStreamProvider);
    final countShorts = ref.watch(myShortsCountProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "내 프로필",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: yellow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined, color: Color(0xFF003366), size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상단 프로필 섹션 (네이비 배경)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 32),
              decoration: const BoxDecoration(
                color: Color(0xFF003366),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  userAsync.when(
                    data: (userData) => Text(
                      userData?.name ?? '사용자',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    loading: () => Container(
                      width: 120,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    error: (_, __) => Text(
                      user?.email?.split('@')[0] ?? '사용자',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 통계 카드
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: navy.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    icon: Icons.stars,
                    label: '포인트',
                    value: '0P',
                    color: yellow,
                  ),
                  Container(width: 1, height: 50, color: Colors.grey[300]),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InqueryListPage()),
                      );
                    },
                    child: ref.watch(incompleteInqueryCountProvider).when(
                          data: (count) => _buildStatCard(
                            icon: Icons.support_agent,
                            label: '문의',
                            value: '$count',
                            color: Colors.red,
                          ),
                          loading: () => _buildStatCard(
                            icon: Icons.support_agent,
                            label: '문의',
                            value: '...',
                            color: Colors.red,
                          ),
                          error: (_, __) => _buildStatCard(
                            icon: Icons.support_agent,
                            label: '문의',
                            value: '0',
                            color: Colors.red,
                          ),
                        ),
                  ),
                  Container(width: 1, height: 50, color: Colors.grey[300]),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VideosPage()),
                      );
                    },
                    child: countShorts.when(
                      data: (count) => _buildStatCard(
                        icon: Icons.play_circle_filled,
                        label: '영상',
                        value: '$count',
                        color: navy,
                      ),
                      loading: () => _buildStatCard(
                        icon: Icons.play_circle_filled,
                        label: '영상',
                        value: '...',
                        color: navy,
                      ),
                      error: (_, __) => _buildStatCard(
                        icon: Icons.play_circle_filled,
                        label: '영상',
                        value: '0',
                        color: navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 활동 메뉴
            _buildMenuSection(
              title: "내 활동",
              icon: Icons.local_activity,
              children: [
                _buildMenuItem(
                  icon: Icons.flight_takeoff,
                  title: '항공 예약',
                  subtitle: '내 항공 예약 관리',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FlightsBookingList()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.radar,
                  title: '항공편 추적',
                  subtitle: '실시간 항공편 추적',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FlightTrackerPage()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.card_travel,
                  title: '패키지 예약',
                  subtitle: '여행 패키지 예약 관리',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PackageBookingList()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.video_library_outlined,
                  title: '내 영상',
                  subtitle: '내 여행 영상 관리',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VideosPage()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 설정 메뉴
            _buildMenuSection(
              title: "설정 & 고객지원",
              icon: Icons.settings,
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: '프로필 수정',
                  subtitle: '개인 정보 수정',
                  onTap: () {
                    final userAsyncValue = ref.read(userStreamProvider);
                    userAsyncValue.whenData((userData) {
                      if (userData != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfile(userInfo: userData),
                          ),
                        );
                      }
                    });
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: '고객센터 문의',
                  subtitle: '계정 관련 도움 받기',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InqueryListPage()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: '개인정보 처리방침',
                  subtitle: '개인정보 보호 정책',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: '이용약관',
                  subtitle: '서비스 이용 약관',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 로그아웃 버튼
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text("로그아웃"),
                        content: const Text("정말 로그아웃 하시겠습니까?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("취소"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("로그아웃",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseAuth.instance.signOut();
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Login(),));
                    }
                  },
                  icon: const Icon(Icons.logout, color: navy),
                  label: const Text(
                    "로그아웃",
                    style: TextStyle(
                        color: navy, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: navy)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildMenuSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: navy.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: yellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: navy, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: navy.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: navy),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: navy)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: navy.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
