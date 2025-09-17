import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:travel_web/view/package/insert_package.dart';
import 'package:travel_web/view/package/update_package.dart';

class TravelPackageMain extends StatefulWidget {
  TravelPackageMain({Key? key}) : super(key: key);

  @override
  State<TravelPackageMain> createState() => _TravelMainState();
}

class _TravelMainState extends State<TravelPackageMain> {
  // --- Dashboard와 동일한 색상 팔레트 ---
  final Color primaryColor = Color(0xFF2C5AA0);
  final Color secondaryColor = Color(0xFF5B8A2A);
  final Color tertiaryColor = Color(0xFFE67E22);
  final Color lightGray = Color(0xFFF8F9FA);
  final Color mediumGray = Color(0xFFDEE2E6);
  final Color darkText = Color(0xFF2C3E50);

  // 삭제 작업을 위한 Future 변수
  Future<void>? _deleteFuture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: Text(
          '여행 패키지 관리',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: primaryColor,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextButton.icon(
              onPressed: openInsert,
              icon: Icon(Icons.add, color: Colors.white, size: 20),
              label: Text('새 패키지', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Stack(
          children: [
            // 메인 StreamBuilder - 패키지 목록
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('package')
                      .orderBy('pDate', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return buildLoadingState();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return buildEmptyState();
                }

                return buildPackageGrid(snapshot.data!.docs);
              },
            ),

            // 삭제 작업 FutureBuilder - 오버레이로 표시
            if (_deleteFuture != null)
              FutureBuilder<void>(
                future: _deleteFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.black26,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryColor,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                '패키지를 삭제하는 중...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: darkText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.done) {
                    // 작업 완료 후 Future 초기화
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _deleteFuture = null;
                      });

                      // 결과에 따른 스낵바 표시
                      if (snapshot.hasError) {
                        _showSnackBar(
                          '삭제 중 오류가 발생했습니다: ${snapshot.error}',
                          Colors.red[600]!,
                          Icons.error,
                        );
                      } else {
                        _showSnackBar(
                          '패키지가 성공적으로 삭제되었습니다',
                          secondaryColor,
                          Icons.check_circle,
                        );
                      }
                    });
                  }

                  return SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: openInsert,
      //   backgroundColor: secondaryColor,
      //   foregroundColor: Colors.white,
      //   elevation: 6,
      //   icon: Icon(Icons.add),
      //   label: Text(
      //     '패키지 추가',
      //     style: TextStyle(fontWeight: FontWeight.w600),
      //   ),
      // ),
    );
  }

  // --- 스낵바 표시 헬퍼 메서드 ---
  void _showSnackBar(String message, Color backgroundColor, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // --- 오류 상태 ---
  Widget buildErrorState(String error) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mediumGray, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              spreadRadius: 3,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 64),
            SizedBox(height: 16),
            Text(
              '데이터 로딩 오류',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}), // StreamBuilder 자동 재시작
              icon: Icon(Icons.refresh),
              label: Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 로딩 상태 ---
  Widget buildLoadingState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mediumGray, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              spreadRadius: 3,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              '패키지 목록을 불러오는 중...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 빈 상태 ---
  Widget buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mediumGray, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              spreadRadius: 3,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_takeoff, size: 64, color: Colors.grey[500]),
            SizedBox(height: 16),
            Text(
              '등록된 패키지가 없습니다',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '첫 번째 여행 패키지를 추가해보세요',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: openInsert,
              icon: Icon(Icons.add),
              label: Text('첫 패키지 추가하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 4,
                shadowColor: secondaryColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 패키지 그리드 ---
  Widget buildPackageGrid(List<QueryDocumentSnapshot> docs) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: docs.length,
      itemBuilder: (_, index) => buildPackageCard(docs[index]),
    );
  }

  // --- 반응형 그리드 열 수 계산 ---
  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  // --- 패키지 카드 (기존과 동일) ---
  Widget buildPackageCard(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      final packageName = data['pName']?.toString() ?? '이름 없음';
      final agencyName = data['tName']?.toString() ?? '';
      final airlineCode = data['aId']?.toString() ?? '';
      final packageState = data['pState']?.toString() ?? '';
      final packagePrice = data['pPrice']?.toString() ?? '';
      final startDate = data['pStart']?.toString() ?? '';
      final endDate = data['pEnd']?.toString() ?? '';
      final groupCount = data['pCount']?.toString() ?? '';

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mediumGray, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              spreadRadius: 3,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 제목과 상태
              Row(
                children: [
                  Expanded(
                    child: Text(
                      packageName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStateColor(packageState).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStateColor(packageState),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      packageState,
                      style: TextStyle(
                        color: _getStateColor(packageState),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // 중간: 정보
              Expanded(
                child: Column(
                  children: [
                    if (agencyName.isNotEmpty)
                      buildInfoRow(Icons.business, '여행사', agencyName),
                    if (airlineCode.isNotEmpty)
                      buildInfoRow(Icons.flight, '항공편', airlineCode),
                    if (packagePrice.isNotEmpty)
                      buildInfoRow(
                        Icons.attach_money,
                        '가격',
                        '${formatPrice(packagePrice)}원',
                      ),
                    if (startDate.isNotEmpty && endDate.isNotEmpty)
                      buildInfoRow(
                        Icons.date_range,
                        '기간',
                        '${formatDate(startDate)} ~ ${formatDate(endDate)}',
                      ),
                    if (groupCount.isNotEmpty)
                      buildInfoRow(Icons.group, '인원', '${groupCount}명'),
                  ],
                ),
              ),

              // 하단: 액션 버튼
              Divider(color: mediumGray),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openUpdate(doc),
                      icon: Icon(Icons.edit, size: 16),
                      label: Text('수정'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tertiaryColor,
                        side: BorderSide(color: tertiaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => confirmDelete(doc),
                      icon: Icon(Icons.delete, size: 16),
                      label: Text('삭제'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        side: BorderSide(color: Colors.red[600]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[300]!, width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 32),
              SizedBox(height: 8),
              Text(
                '데이터 오류',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
              Text(
                '문서 ID: ${doc.id}',
                style: TextStyle(color: Colors.red[600], fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }
  }

  // --- 정보 행 ---
  Widget buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: darkText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- 상태별 색상 ---
  Color _getStateColor(String state) {
    switch (state) {
      case '모집중':
        return secondaryColor;
      case '모집마감':
        return tertiaryColor;
      case '출발확정':
        return primaryColor;
      default:
        return Colors.grey;
    }
  }

  // --- 가격 포맷팅 ---
  String formatPrice(String price) {
    try {
      int priceInt = int.parse(price);
      return priceInt.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return price;
    }
  }

  // --- 날짜 포맷팅 ---
  String formatDate(String date) {
    try {
      if (date.length >= 10) {
        return date.substring(0, 10);
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  // --- 패키지 추가 ---
  void openInsert() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InsertPackage()),
    ).then((_) => setState(() {}));
  }

  // --- 패키지 수정 ---
  void openUpdate(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UpdatePackage(packageDoc: doc)),
    ).then((_) => setState(() {}));
  }

  // --- 삭제 확인 ---
  void confirmDelete(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['pName'] ?? '이름 없음';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[600]),
                SizedBox(width: 12),
                Text(
                  '패키지 삭제',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
              ],
            ),
            content: Text(
              '"$name" 패키지를 삭제하시겠습니까?\n\n삭제된 데이터는 복구할 수 없습니다.',
              style: TextStyle(color: darkText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('취소'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // FutureBuilder를 위한 Future 설정
                  setState(() {
                    _deleteFuture = deletePackage(doc);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('삭제'),
              ),
            ],
          ),
    );
  }

  // --- 패키지 삭제 (mounted 제거) ---
  Future<void> deletePackage(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final imageUrls = List<String>.from(data['images'] ?? []);

    // 이미지 삭제
    for (String url in imageUrls) {
      if (url.startsWith('https://firebasestorage')) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (e) {
          // 이미지 삭제 실패는 무시
        }
      }
    }

    // 문서 삭제
    await doc.reference.delete();
  }
}
