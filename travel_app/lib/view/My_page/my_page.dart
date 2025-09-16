import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/view/My_page/flight_tracker_page.dart';
import 'package:travel_app/model/app_user.dart';
import 'package:travel_app/view/My_page/edit_profile.dart';
import 'package:travel_app/view/My_page/flights_booking_list.dart';
import 'package:travel_app/view/My_page/package_booking_List.dart';
import 'package:travel_app/view/My_page/privacy_police.dart';
import 'package:travel_app/view/My_page/terms_of_service.dart';
import 'package:travel_app/view/shorts/VideosPage.dart';
import 'package:travel_app/vm/user_provider.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final userAsync = ref.watch(userStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 상단 프로필 섹션
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 프로필 이미지 & 이름
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              userAsync.when(
                                data:
                                    (userData) => Text(
                                      userData?.name ?? '사용자',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                loading:
                                    () => const Text(
                                      '로딩 중...',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                error:
                                    (_, __) => Text(
                                      user?.email?.split('@')[0] ?? '사용자',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 통계 섹션
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          icon: Icons.local_parking_rounded,
                          label: '포인트',
                          value: '0P',
                          color: Colors.blue,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _buildStatCard(
                          icon: Icons.favorite,
                          label: '좋아요',
                          value: '12',
                          color: Colors.red,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _buildStatCard(
                          icon: Icons.video_library,
                          label: '비디오',
                          value: '5',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 메뉴 섹션
              Container(
                width: double.infinity,
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMenuTitle('내 활동'),
                    _buildMenuItem(
                      icon: Icons.flight_takeoff,
                      title: '내 항공권 예약',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FlightsBookingList(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
  icon: Icons.flight,
  title: '실시간 항공기 추적',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FlightTrackerPage(),
      ),
    );
  },
),
                    _buildMenuItem(
                      icon: Icons.card_travel,
                      title: '내 패키지 예약',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PackageBookingList(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.video_library_outlined,
                      title: '내 쇼츠 관리',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VideosPage(),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1),

                    _buildMenuTitle('설정'),
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: '내 정보 수정하기',
                      onTap: () {
                        // userAsync에서 실제 데이터를 가져와서 전달
                        final userAsyncValue = ref.read(userStreamProvider);
                        userAsyncValue.whenData((userData) {
                          if (userData != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        EditProfile(userInfo: userData),
                              ),
                            );
                          }
                        });
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: '문의하기',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: '개인정보 처리방침',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyPage(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.description_outlined,
                      title: '이용약관',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsOfServicePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 로그아웃 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('로그아웃'),
                              content: const Text('정말 로그아웃하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('로그아웃'),
                                ),
                              ],
                            ),
                      );

                      if (confirm == true) {
                        await FirebaseAuth.instance.signOut();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.red[300]!),
                    ),
                    child: Text(
                      '로그아웃',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMenuTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey[600]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
