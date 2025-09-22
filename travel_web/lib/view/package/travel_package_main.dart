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
  final Color primaryColor = Color(0xFF2C5AA0);      // 진한 파란색
  final Color secondaryColor = Color(0xFF5B8A2A);    // 진한 초록색
  final Color tertiaryColor = Color(0xFFE67E22);     // 진한 주황색
  final Color lightGray = Color(0xFFF8F9FA);         // 밝은 배경
  final Color mediumGray = Color(0xFFDEE2E6);        // 진한 경계선
  final Color darkText = Color(0xFF2C3E50);          // 진한 텍스트

  // --- 삭제 작업을 위한 Future 변수 ---
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
          // --- 새 패키지 추가 버튼 ---
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
            // --- 메인 StreamBuilder - 패키지 목록 ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
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

            // --- 삭제 작업 FutureBuilder - 오버레이로 표시 ---
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
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
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
                    // --- 작업 완료 후 Future 초기화 ---
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _deleteFuture = null;
                      });

                      // --- 결과에 따른 스낵바 표시 ---
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

  // --- 오류 상태 위젯 생성 메서드 ---
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

  // --- 로딩 상태 위젯 생성 메서드 ---
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

  // --- 빈 상태 위젯 생성 메서드 ---
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

  // --- 패키지 그리드 생성 메서드 ---
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

  // --- 반응형 그리드 열 수 계산 메서드 ---
  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  // --- 패키지 카드 생성 메서드 (airlineName 필드 추가 및 개선된 데이터 표시) ---
  Widget buildPackageCard(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // --- 패키지 데이터 추출 (기존 필드명 유지) ---
      final packageName = data['pName']?.toString() ?? '이름 없음';
      final agencyName = data['tName']?.toString() ?? '';
      final airlineName = data['airlineName']?.toString() ?? '';      // 항공사명 필드 (새로 추가)
      final airlineCode = data['aId']?.toString() ?? '';              // 항공편번호 (기존 aId 필드)
      final packageState = data['pState']?.toString() ?? '';
      final packagePrice = data['pPrice']?.toString() ?? '';
      final startDate = data['pStart']?.toString() ?? '';
      final endDate = data['pEnd']?.toString() ?? '';
      final groupCount = data['pCount']?.toString() ?? '';

      // --- 향상된 항공사 정보 조합 (항공사명 + 항공편번호) ---
      String enhancedAirlineInfo = _buildEnhancedAirlineInfo(airlineName, airlineCode);

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
              // --- 상단: 제목과 상태 배지 ---
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

              // --- 중간: 패키지 정보 (향상된 데이터 표시) ---
              Expanded(
                child: Column(
                  children: [
                    // --- 여행사 정보 ---
                    if (agencyName.isNotEmpty)
                      buildInfoRow(Icons.business, '여행사', agencyName),
                    
                    // --- 향상된 항공편 정보 (항공사명 + 항공편번호) ---
                    if (enhancedAirlineInfo.isNotEmpty)
                      buildInfoRow(Icons.flight, '항공편', enhancedAirlineInfo),
                    
                    // --- 가격 정보 (콤마 포맷팅 적용) ---
                    if (packagePrice.isNotEmpty)
                      buildInfoRow(
                        Icons.attach_money,
                        '가격',
                        '${formatPriceWithCommas(packagePrice)}원',
                      ),
                    
                    // --- 여행 기간 정보 ---
                    if (startDate.isNotEmpty && endDate.isNotEmpty)
                      buildInfoRow(
                        Icons.date_range,
                        '기간',
                        '${formatDate(startDate)} ~ ${formatDate(endDate)}',
                      ),
                    
                    // --- 최대 인원 정보 (콤마 포맷팅 적용) ---
                    if (groupCount.isNotEmpty)
                      buildInfoRow(Icons.group, '인원', '${formatNumberWithCommas(groupCount)}명'),
                  ],
                ),
              ),

              // --- 하단: 액션 버튼들 ---
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
      // --- 데이터 오류 시 에러 카드 표시 ---
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

  // --- 향상된 항공사 정보 생성 메서드 ---
  String _buildEnhancedAirlineInfo(String airlineName, String airlineCode) {
    if (airlineName.isNotEmpty && airlineCode.isNotEmpty) {
      // --- 항공사명과 항공편번호가 모두 있는 경우: "대한항공 (KE-1234)" ---
      return '$airlineName ($airlineCode)';
    } else if (airlineName.isNotEmpty) {
      // --- 항공사명만 있는 경우: "대한항공" ---
      return airlineName;
    } else if (airlineCode.isNotEmpty) {
      // --- 항공편번호만 있는 경우: "KE-1234" ---
      return airlineCode;
    }
    // --- 둘 다 없는 경우 빈 문자열 반환 ---
    return '';
  }

  // --- 정보 행 생성 메서드 ---
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

  // --- 상태별 색상 반환 메서드 ---
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

  // --- 가격 포맷팅 메서드 (기존 데이터 호환성 유지) ---
  String formatPriceWithCommas(String price) {
    try {
      // --- 이미 콤마가 있는 경우와 없는 경우 모두 처리 ---
      String cleanPrice = price.replaceAll(',', '');
      int priceInt = int.parse(cleanPrice);
      return priceInt.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return price; // 파싱 실패 시 원본 반환
    }
  }

  // --- 일반 숫자 포맷팅 메서드 (인원수 등에 사용) ---
  String formatNumberWithCommas(String number) {
    try {
      // --- 이미 콤마가 있는 경우와 없는 경우 모두 처리 ---
      String cleanNumber = number.replaceAll(',', '');
      int numberInt = int.parse(cleanNumber);
      
      // --- 인원수는 보통 큰 수가 아니므로 필요한 경우만 콤마 적용 ---
      if (numberInt >= 1000) {
        return numberInt.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
      } else {
        return numberInt.toString();
      }
    } catch (e) {
      return number; // 파싱 실패 시 원본 반환
    }
  }

  // --- 날짜 포맷팅 메서드 ---
  String formatDate(String date) {
    try {
      // --- 날짜 형식이 "2025.09.10." 형태인 경우 처리 ---
      if (date.length >= 10) {
        return date.substring(0, 10); // "2025.09.10" 부분만 반환
      }
      return date;
    } catch (e) {
      return date; // 오류 시 원본 반환
    }
  }

  // --- 패키지 추가 페이지 열기 메서드 ---
  void openInsert() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InsertPackage()),
    ).then((_) => setState(() {}));
  }

  // --- 패키지 수정 페이지 열기 메서드 ---
  void openUpdate(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UpdatePackage(packageDoc: doc)),
    ).then((_) => setState(() {}));
  }

  // --- 삭제 확인 다이얼로그 표시 메서드 ---
  void confirmDelete(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['pName'] ?? '이름 없음';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
              // --- FutureBuilder를 위한 Future 설정 ---
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

  // --- 패키지 삭제 실행 메서드 ---
  Future<void> deletePackage(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final imageUrls = List<String>.from(data['images'] ?? []);

    // --- Firebase Storage에서 이미지 삭제 ---
    for (String url in imageUrls) {
      if (url.startsWith('https://firebasestorage')) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (e) {
          // --- 이미지 삭제 실패는 무시하고 계속 진행 ---
        }
      }
    }

    // --- Firestore에서 패키지 문서 삭제 ---
    await doc.reference.delete();
  }
}
