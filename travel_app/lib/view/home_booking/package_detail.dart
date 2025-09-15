import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import '../../model/travel_package.dart';

class PackageDetailPage extends StatefulWidget {
  final TravelPackage package;

  const PackageDetailPage({super.key, required this.package});

  @override
  State<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends State<PackageDetailPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      appBar: AppBar(
        title: Text(pkg.pName),
        backgroundColor: const Color(0xFF667EEA),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("공유 기능 준비 중!")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("찜하기 완료!")),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildImageSlider(pkg),
          _buildPriceBar(pkg),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(pkg),
                _buildItineraryTab(pkg),
                _buildIncludesTab(pkg),
                _buildPolicyTab(pkg),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(pkg),
    );
  }

  Widget _buildImageSlider(TravelPackage pkg) {
    return SizedBox(
      height: 280,
      child: pkg.images.isNotEmpty
          ? Stack(
              alignment: Alignment.bottomCenter,
              children: [
                cs.CarouselSlider(
                  options: cs.CarouselOptions(
                    height: 280,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: pkg.images.length > 1,
                    autoPlay: pkg.images.length > 1,
                    autoPlayInterval: const Duration(seconds: 4),
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  ),
                  items: pkg.images.map((url) {
                    return Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, size: 80, color: Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
                if (pkg.images.length > 1)
                  Positioned(
                    bottom: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: pkg.images.asMap().entries.map((entry) {
                        return Container(
                          width: _currentIndex == entry.key ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentIndex == entry.key
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "${_currentIndex + 1}/${pkg.images.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            )
          : Container(
              color: Colors.grey.shade200,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                  SizedBox(height: 8),
                  Text("이미지가 없습니다", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
    );
  }

  Widget _buildPriceBar(TravelPackage pkg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "₩${pkg.pPrice}만원",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "₩${(int.parse(pkg.pPrice) * 1.2).round()}만원",
                    style: TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    "1인 기준 • ${pkg.pCount}명 최대",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pkg.pState == "예약가능" ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              pkg.pState,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF667EEA),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF667EEA),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: "개요"),
          Tab(text: "일정"),
          Tab(text: "포함사항"),
          Tab(text: "약관"),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(TravelPackage pkg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(
            title: "여행 정보",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.calendar_today, "출발일", pkg.pStart),
                _infoRow(Icons.event, "도착일", pkg.pEnd),
                _infoRow(Icons.confirmation_number, "예약번호", pkg.pNum),
                _infoRow(Icons.group, "최대 인원", "${pkg.pCount}명"),
                _infoRow(Icons.flight_takeoff, "항공편", "대한항공 KE001 (직항)"),
                _infoRow(Icons.hotel, "숙박", "5성급 호텔 (4박)"),
                _infoRow(Icons.location_on, "미팅 장소", "인천국제공항 제1터미널"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(
            title: "여행 하이라이트",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _highlightItem("🏛️", "유명 관광지 방문", "현지 가이드와 함께하는 깊이 있는 문화 체험"),
                _highlightItem("🍽️", "현지 맛집 투어", "미슐랭 추천 레스토랑과 전통 음식 체험"),
                _highlightItem("🛍️", "쇼핑 타임", "면세점과 현지 시장에서의 자유 쇼핑"),
                _highlightItem("📸", "인생샷 스팟", "SNS 인기 포토존에서 추억 만들기"),
                _highlightItem("🌅", "선택 관광", "추가 비용으로 즐기는 특별한 경험"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(
            title: "이런 분께 추천해요",
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _recommendChip("처음 해외여행"),
                _recommendChip("가족 여행객"),
                _recommendChip("문화 체험 선호"),
                _recommendChip("편안한 여행"),
                _recommendChip("사진 촬영 좋아함"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryTab(TravelPackage pkg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _infoCard(
            title: "상세 일정",
            child: Column(
              children: [
                _daySchedule(1, "인천 출발 → 도착", [
                  "09:00 인천국제공항 집합",
                  "11:00 대한항공 KE001편 출발",
                  "16:00 현지 도착 (현지시간)",
                  "18:00 호텔 체크인",
                  "19:30 환영 만찬"
                ]),
                _daySchedule(2, "시내 관광", [
                  "09:00 호텔 조식",
                  "10:00 주요 관광지 투어",
                  "12:00 현지 맛집 점심",
                  "14:00 박물관 관람",
                  "16:00 전통 시장 체험",
                  "18:00 저녁 식사 후 자유시간"
                ]),
                _daySchedule(3, "자유 일정", [
                  "09:00 호텔 조식",
                  "10:00 자유 일정",
                  "- 선택관광 A: 테마파크 (추가 \$80)",
                  "- 선택관광 B: 스파 체험 (추가 \$60)",
                  "18:00 가이드 추천 맛집 투어"
                ]),
                _daySchedule(4, "쇼핑 & 출발 준비", [
                  "09:00 호텔 조식 및 체크아웃",
                  "10:00 면세점 쇼핑",
                  "12:00 점심 식사",
                  "14:00 공항 이동",
                  "17:00 항공편 출발"
                ]),
                _daySchedule(5, "인천 도착", [
                  "08:00 인천국제공항 도착",
                  "10:00 입국 수속 후 해산"
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      "일정 안내",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "• 현지 사정에 따라 일정이 변경될 수 있습니다\n"
                  "• 모든 시간은 현지 시간 기준입니다\n"
                  "• 선택관광은 현지에서 신청 가능합니다",
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludesTab(TravelPackage pkg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _infoCard(
            title: "포함 사항",
            child: Column(
              children: [
                _includeItem(Icons.flight, "항공료", "왕복 항공료 (유류할증료, 공항세 포함)", true),
                _includeItem(Icons.hotel, "숙박", "4성급 호텔 4박 (2인 1실 기준)", true),
                _includeItem(Icons.restaurant, "식사", "조식 4회, 중식 3회, 석식 3회", true),
                _includeItem(Icons.directions_bus, "교통", "현지 교통비 및 관광버스", true),
                _includeItem(Icons.tour, "관광", "기본 관광지 입장료", true),
                _includeItem(Icons.person, "가이드", "현지 한국어 가이드", true),
                _includeItem(Icons.security, "보험", "여행자보험 (1억원)", true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(
            title: "불포함 사항",
            child: Column(
              children: [
                _includeItem(Icons.flight_land, "개인경비", "개인적인 경비 및 쇼핑비용", false),
                _includeItem(Icons.local_drink, "음료", "식사 시 음료 및 주류", false),
                _includeItem(Icons.room_service, "팁", "가이드 및 기사 팁 (1일 \$10 권장)", false),
                _includeItem(Icons.add_circle, "선택관광", "선택관광 비용", false),
                _includeItem(Icons.wifi, "통신", "현지 와이파이 또는 로밍", false),
                _includeItem(Icons.local_laundry_service, "세탁", "세탁비 및 기타 개인 서비스", false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Text(
                      "추가 비용 안내",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "• 1인실 사용 시 추가요금: 50만원\n"
                  "• 유아 (24개월 미만): 항공료의 10%\n"
                  "• 소아 (24개월~12세): 성인요금의 90%",
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyTab(TravelPackage pkg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _infoCard(
            title: "취소 규정",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _policyItem("출발 30일 전", "취소수수료 10%"),
                _policyItem("출발 20일 전", "취소수수료 20%"),
                _policyItem("출발 10일 전", "취소수수료 50%"),
                _policyItem("출발 7일 전", "취소수수료 70%"),
                _policyItem("출발 3일 전", "취소수수료 90%"),
                _policyItem("출발 당일", "취소수수료 100%"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(
            title: "예약 시 필요사항",
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• 여권 사본 (유효기간 6개월 이상 남아있어야 함)"),
                Text("• 비자 (해당 국가 요구 시)"),
                Text("• 영문 성명 확인서"),
                Text("• 여행자 보험 가입 동의서"),
                Text("• 응급연락처 및 알레르기 정보"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(
            title: "여행 약관",
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("• 본 상품은 최소 출발 인원 15명 기준입니다"),
                Text("• 출발 7일 전 최소 인원 미달 시 여행이 취소될 수 있습니다"),
                Text("• 항공 스케줄 변경 시 일정이 조정될 수 있습니다"),
                Text("• 현지 사정으로 인한 일정 변경 시 동급으로 대체됩니다"),
                Text("• 여행 중 안전사고에 대한 책임은 여행약관에 따릅니다"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Text(
                      "중요 안내사항",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "• COVID-19 관련 방역 수칙을 준수해야 합니다\n"
                  "• 여행 전 건강상태 확인이 필요합니다\n"
                  "• 현지 법규 및 관습을 존중해 주시기 바랍니다",
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(TravelPackage pkg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.phone),
              label: const Text("상담"),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("전화 상담: 1588-1234")),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF667EEA),
                side: const BorderSide(color: Color(0xFF667EEA)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart),
              label: const Text("예약하기"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("예약 확인"),
                    content: Text("${pkg.pName} 상품을 예약하시겠습니까?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("취소"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("예약이 접수되었습니다!")),
                          );
                        },
                        child: const Text("확인"),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF667EEA),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _daySchedule(int day, String title, List<String> schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(
            width: 4,
            color: Color(0xFF667EEA),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Day $day - $title",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF667EEA),
            ),
          ),
          const SizedBox(height: 8),
          ...schedule.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: const TextStyle(fontSize: 13),
            ),
          )),
        ],
      ),
    );
  }

  Widget _includeItem(IconData icon, String title, String description, bool isIncluded) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isIncluded ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: isIncluded ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyItem(String period, String fee) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            period,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            fee,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}