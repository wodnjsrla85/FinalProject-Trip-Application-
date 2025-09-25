import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:travel_app/Widget/booking_sheet.dart';
import 'package:travel_app/model/travel_package.dart';
import 'package:travel_app/vm/booking_provider.dart';
import 'package:travel_app/vm/save_provider.dart';

// 저장 상태 Provider
final packageSavedProvider = StateProvider.family<bool, String>(
  (ref, String packageId) => false,
);

class PackageDetailPage extends ConsumerStatefulWidget {
  final TravelPackage package;

  const PackageDetailPage({super.key, required this.package});

  @override
  ConsumerState<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends ConsumerState<PackageDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Firestore에서 현재 저장 여부 확인 후 provider에 반영
    SaveProvider().isPackageSaved(widget.package.id).then((saved) {
      ref.read(packageSavedProvider(widget.package.id).notifier).state = saved;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          _buildHeroSection(context, pkg),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceCard(pkg),
                  _buildPackageInfo(pkg),
                  _buildTabSection(pkg),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(context, pkg),
    );
  }

  Widget _buildHeroSection(BuildContext context, TravelPackage pkg) {
    final isSaved = ref.watch(packageSavedProvider(pkg.id));

    return Container(
      height: 380,
      child: Stack(
        children: [
          // Background Image Carousel
          Container(
            height: 320,
            child:
                pkg.images.isNotEmpty
                    ? cs.CarouselSlider(
                      options: cs.CarouselOptions(
                        height: 320,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: pkg.images.length > 1,
                        autoPlay: pkg.images.length > 1,
                        onPageChanged: (index, reason) {
                          setState(() => _currentImageIndex = index);
                        },
                      ),
                      items:
                          pkg.images.map((url) {
                            return Stack(
                              children: [
                                Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 320,
                                  errorBuilder:
                                      (c, e, s) => Container(
                                        color: const Color(0xFF1E3A8A),
                                        child: const Icon(
                                          Icons.image,
                                          size: 60,
                                          color: Colors.white54,
                                        ),
                                      ),
                                ),
                              ],
                            );
                          }).toList(),
                    )
                    : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 60,
                          color: Colors.white54,
                        ),
                      ),
                    ),
          ),

          // App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildCircleButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  if (pkg.images.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${_currentImageIndex + 1}/${pkg.images.length}",
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      _buildCircleButton(
                        icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                        onTap: () async {
                          final saveProvider = SaveProvider();
                          try {
                            final newState = !isSaved;
                            await saveProvider.togglePackage(pkg.id);
                            ref
                                .read(packageSavedProvider(pkg.id).notifier)
                                .state = newState;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      newState
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(newState ? "저장되었습니다!" : "저장 해제되었습니다."),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("실패: $e"),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Package Title Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                    // const Color(0xFF1E3A8A).withOpacity(0.9),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg.pName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              pkg.pState == "예약가능"
                                  ? const Color(0xFFEAB308)
                                  : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          pkg.pState,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.people_outline,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "최대 ${pkg.pCount}명",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Color(0xFF1E3A8A).withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildPriceCard(TravelPackage pkg) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.attach_money,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "₩${pkg.pPrice}",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "1인 기준 가격",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageInfo(TravelPackage pkg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "여행 정보",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.calendar_today, "여행 시작일", pkg.pStart),
                _buildDivider(),
                _buildInfoRow(Icons.calendar_month, "여행 종료일", pkg.pEnd),
                _buildDivider(),
                _buildInfoRow(Icons.location_on_outlined, "여행지", pkg.pName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: Colors.grey[200],
    );
  }

  Widget _buildTabSection(TravelPackage pkg) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Custom Tab Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF1E3A8A),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: "개요"),
                Tab(text: "일정"),
                Tab(text: "포함사항"),
                Tab(text: "약관"),
              ],
            ),
          ),

          // Tab Content
          Container(
            height: 300,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent("패키지 개요", "이 여행 패키지의 상세한 설명이 여기에 표시됩니다."),
                _buildTabContent("여행 일정", "Day 1: 출발\nDay 2: 관광\nDay 3: 귀국"),
                _buildTabContent("포함사항", "• 항공료\n• 숙박비\n• 가이드\n• 일부 식사"),
                _buildTabContent("이용 약관", "예약 시 주의사항과 취소 정책이 안내됩니다."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, TravelPackage pkg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SafeArea(
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                int passengerCount = 1;

                // 인원 선택 다이얼로그
                passengerCount =
                    await showDialog<int>(
                      context: context,
                      builder: (ctx) {
                        int tempCount = 1;
                        return Dialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: StatefulBuilder(
                              builder:
                                  (c, setState) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "인원 선택",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "여행 인원을 선택하세요",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color:
                                                    tempCount > 1
                                                        ? const Color(
                                                          0xFF1E3A8A,
                                                        )
                                                        : Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.remove,
                                                  color: Colors.white,
                                                ),
                                                onPressed:
                                                    tempCount > 1
                                                        ? () => setState(
                                                          () => tempCount--,
                                                        )
                                                        : null,
                                              ),
                                            ),
                                            const SizedBox(width: 24),
                                            Text(
                                              "$tempCount",
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E3A8A),
                                              ),
                                            ),
                                            const SizedBox(width: 24),
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color:
                                                    tempCount <
                                                            int.parse(
                                                              pkg.pCount,
                                                            )
                                                        ? const Color(
                                                          0xFF1E3A8A,
                                                        )
                                                        : Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                ),
                                                onPressed:
                                                    tempCount <
                                                            int.parse(
                                                              pkg.pCount,
                                                            )
                                                        ? () => setState(
                                                          () => tempCount++,
                                                        )
                                                        : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 44,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey[300]!,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      ctx,
                                                      passengerCount,
                                                    ),
                                                child: Text(
                                                  "취소",
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Container(
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1E3A8A),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      ctx,
                                                      tempCount,
                                                    ),
                                                child: const Text(
                                                  "확인",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        );
                      },
                    ) ??
                    1;

                // 예약 바텀시트 호출
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder:
                      (_) => BookingSheet(
                        passengerCount: passengerCount,
                        price: int.parse(pkg.pPrice),
                      ),
                );

                if (result != null) {
                  try {
                    final bookingProvider = BookingProvider();
                    await bookingProvider.createBooking(
                      aid: pkg.id,
                      pricePerSeat: int.parse(pkg.pPrice),
                      selectedSeats: const [],
                      flightDate: pkg.pStart,
                      passports: List<String>.from(result['passports']),
                      payment: result['payment'],
                      what: "패키지",
                      passengerCount: passengerCount,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text("예약이 완료되었습니다!"),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.white),
                            const SizedBox(width: 8),
                            Text("예약 실패: $e"),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "예약하기",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
