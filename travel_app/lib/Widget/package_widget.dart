import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/view/home_booking/package_detail.dart';
import 'package:travel_app/vm/pacakge_provider.dart';

class PackageWidget extends ConsumerWidget {
  const PackageWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(packageProvider);

    return packagesAsync.when(
      data: (packages) {
        if (packages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(Icons.card_travel, size: 40, color: Color(0xFF003366)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No packages available",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Travel packages will appear here",
                    style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366), // 메인 블루
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.card_travel, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Travel Packages",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003366),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${packages.length}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 패키지 목록 (가로 스크롤)
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final pkg = packages[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PackageDetailPage(package: pkg),
                          ),
                        );
                      },
                      child: Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 이미지
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: Image.network(
                                    pkg.images.isNotEmpty
                                        ? pkg.images.first
                                        : "https://via.placeholder.com/220x140/003366/FFFFFF?text=Travel+Package",
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 140,
                                        width: double.infinity,
                                        color: const Color(0xFF003366),
                                        child: const Icon(Icons.image, color: Colors.white, size: 40),
                                      );
                                    },
                                  ),
                                ),
                                // 상태 배지
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(pkg.pState),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pkg.pState,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // 패키지 정보
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pkg.pName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A202C),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        Icon(
                                          _getStatusIcon(pkg.pState),
                                          size: 14,
                                          color: _getStatusColor(pkg.pState),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Status: ${pkg.pState}",
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Spacer(),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "From",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF718096),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "₩${pkg.pPrice}",
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF003366), // 블루 강조
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 36,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => PackageDetailPage(package: pkg),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFFD700), // 옐로우 버튼
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 20),
                                            ),
                                            child: const Text(
                                              "Book",
                                              style: TextStyle(
                                                color: Color(0xFF003366), // 블루 텍스트
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
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
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF003366), strokeWidth: 3),
      ),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE11D48)),
            const SizedBox(height: 16),
            Text(
              "Failed to load packages\nError: $err",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
      case '이용가능':
        return const Color(0xFF22C55E); // 초록
      case 'sold out':
      case '매진':
        return const Color(0xFFE11D48); // 빨강
      case 'pending':
      case '대기중':
        return const Color(0xFFF59E0B); // 주황
      default:
        return const Color(0xFF003366); // 기본 블루
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
      case '이용가능':
        return Icons.check_circle;
      case 'sold out':
      case '매진':
        return Icons.cancel;
      case 'pending':
      case '대기중':
        return Icons.access_time;
      default:
        return Icons.info;
    }
  }
}
