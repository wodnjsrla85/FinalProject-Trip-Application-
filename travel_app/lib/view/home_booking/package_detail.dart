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

class _PackageDetailPageState extends ConsumerState<PackageDetailPage> {
  @override
  void initState() {
    super.initState();
    // Firestore에서 현재 저장 여부 확인 후 provider에 반영
    SaveProvider().isPackageSaved(widget.package.id).then((saved) {
      ref.read(packageSavedProvider(widget.package.id).notifier).state = saved;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildAppBar(context, pkg),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildImageSlider(pkg),
                  _buildPriceSection(pkg),
                  _buildTabSection(pkg),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(context, pkg),
    );
  }

  // -------------------- 위젯 빌더 --------------------

  Widget _buildAppBar(BuildContext context, TravelPackage pkg) {
    final isSaved = ref.watch(packageSavedProvider(pkg.id));

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
      ),
      child: Row(
        children: [
          _circleBtn(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            pkg.pName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _circleBtn(icon: Icons.share, onTap: () {}),
              const SizedBox(width: 8),
              _circleBtn(
                icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                onTap: () async {
                  final saveProvider = SaveProvider();
                  try {
                    final newState = !isSaved;
                    await saveProvider.togglePackage(pkg.id);
                    ref.read(packageSavedProvider(pkg.id).notifier).state =
                        newState;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(newState ? "저장되었습니다!" : "저장 해제되었습니다."),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("실패: $e")));
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildImageSlider(TravelPackage pkg) {
    return Container(
      height: 250,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child:
            pkg.images.isNotEmpty
                ? cs.CarouselSlider(
                  options: cs.CarouselOptions(
                    height: 250,
                    viewportFraction: 1.0,
                    enableInfiniteScroll: pkg.images.length > 1,
                    autoPlay: pkg.images.length > 1,
                  ),
                  items:
                      pkg.images.map((url) {
                        return Image.network(
                          url,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder:
                              (c, e, s) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, size: 60),
                              ),
                        );
                      }).toList(),
                )
                : Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 60),
                  ),
                ),
      ),
    );
  }

  Widget _buildPriceSection(TravelPackage pkg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "₩${pkg.pPrice}만원",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "1인 기준 • ${pkg.pCount}명 최대",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pkg.pState == "예약가능" ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
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

  Widget _buildTabSection(TravelPackage pkg) {
    return DefaultTabController(
      length: 4,
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: const [
            TabBar(
              labelColor: Color(0xFF667EEA),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF667EEA),
              tabs: [
                Tab(text: "개요"),
                Tab(text: "일정"),
                Tab(text: "포함사항"),
                Tab(text: "약관"),
              ],
            ),
            SizedBox(
              height: 400,
              child: TabBarView(
                children: [
                  Center(child: Text("개요")),
                  Center(child: Text("일정")),
                  Center(child: Text("포함사항")),
                  Center(child: Text("약관")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, TravelPackage pkg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.phone),
                label: const Text("상담"),
                onPressed: () {},
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
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text("예약하기"),
                  onPressed: () async {
                    int passengerCount = 1;

                    // 인원 선택 다이얼로그
                    passengerCount =
                        await showDialog<int>(
                          context: context,
                          builder: (ctx) {
                            int tempCount = 1;
                            return AlertDialog(
                              title: const Text("인원 선택"),
                              content: StatefulBuilder(
                                builder:
                                    (c, setState) => Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("여행 인원을 선택하세요"),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () {
                                                if (tempCount > 1) {
                                                  setState(() => tempCount--);
                                                }
                                              },
                                            ),
                                            Text(
                                              "$tempCount",
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () {
                                                if (tempCount <
                                                    int.parse(pkg.pCount)) {
                                                  setState(() => tempCount++);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(ctx, passengerCount),
                                  child: const Text("취소"),
                                ),
                                ElevatedButton(
                                  onPressed:
                                      () => Navigator.pop(ctx, tempCount),
                                  child: const Text("확인"),
                                ),
                              ],
                            );
                          },
                        ) ??
                        1;

                    // 예약 바텀시트 호출
                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder:
                          (_) => BookingSheet(passengerCount: passengerCount),
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
                        ); // 이 줄 추가!

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("예약이 완료되었습니다!")),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("예약 실패: $e")));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
