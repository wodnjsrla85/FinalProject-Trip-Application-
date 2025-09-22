import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_web/view/package/travel_package_main.dart';

/// 여행사 관리자 대시보드 화면
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  
  // --- 테마 컬러 설정 (눈이 편한 색상) ---
  final Color primaryColor = Color(0xFF4A90E2);      // 부드러운 파란색 (메인 컬러)
  final Color secondaryColor = Color(0xFF7ED321);    // 부드러운 초록색 (보조 컬러)
  final Color lightGray = Color(0xFFF5F7FA);         // 연한 회색 (배경용)
  final Color mediumGray = Color(0xFFE1E8ED);        // 중간 회색 (테두리용)
  
  // --- 상단 카드 데이터 ---
  String thisMonthGuest = '0명';      // 이달 예약 고객수
  String thisMonthMoney = '0원';      // 이달 매출액
  String cancelPercent = '0%';        // 취소율
  String returnPercent = '0%';        // 재구매율
  
  // --- 패키지 개수 데이터 ---  
  int allPackage = 0;                 // 전체 패키지
  int openPackage = 0;                // 모집중 패키지
  int closePackage = 0;               // 모집마감 패키지
  int goPackage = 0;                  // 출발확정 패키지
  
  // --- TOP5 리스트 ---
  List<Map<String, dynamic>> top5List = [];

  @override
  void initState() {
    super.initState();
    getPackageData();
    getBookingData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,    // 전체 배경을 연한 회색으로
      appBar: AppBar(
        title: Text("패키지 관리 대시보드"),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,    // 제목 색상을 파란색으로
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. 상단 4개 카드
            makeTopCards(),
            SizedBox(height: 36),
            
            // 2. 중간 차트와 TOP5
            makeMiddleArea(), 
            SizedBox(height: 24),
            
            // 3. 하단 관리 메뉴
            makeBottomMenu(),
          ],
        ),
      ),
    );
  }

  // ------ 위젯 함수들 ------

  // --- 상단 4개 카드 만들기 ---
  Widget makeTopCards() {
    return Row(
      children: [
        Expanded(child: makeCard("이달 예약 명수", thisMonthGuest)),
        SizedBox(width: 16),
        Expanded(child: makeCard("이달 매출", thisMonthMoney)),
        SizedBox(width: 16),  
        Expanded(child: makeCard("취소율", cancelPercent)),
        SizedBox(width: 16),
        Expanded(child: makeCard("재구매율", returnPercent)),
      ],
    );
  }

  // --- 카드 하나 만들기 ---
  Widget makeCard(String title, String value) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,               // 카드 배경은 흰색
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: mediumGray, width: 1),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  // --- 중간 영역 만들기 (flex 비율 설명 추가) ---
  Widget makeMiddleArea() {
    return Row(
      children: [
        // 왼쪽: 차트 영역 (더 넓음)
        // flex: 2 = 전체 공간의 2/3 (약 67%) 차지
        Expanded(
          flex: 2,
          child: makeChartArea(),
        ),
        SizedBox(width: 16),
        
        // 오른쪽: TOP5 영역 (좁음)  
        // flex: 1 = 전체 공간의 1/3 (약 33%) 차지
        // 총 flex 합계: 2 + 1 = 3, 비율 = 2:1
        Expanded(
          flex: 1,  
          child: makeTop5Area(),
        ),
      ],
    );
  }

  // --- 차트 영역 만들기 ---
  Widget makeChartArea() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mediumGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("예약 추이", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
          SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text("예약 추이 차트 (구현 예정)", style: TextStyle(color: Colors.grey.shade600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TOP5 영역 만들기 ---
  Widget makeTop5Area() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mediumGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("이달 매출 TOP5", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
          SizedBox(height: 12),
          Expanded(
            child: top5List.isEmpty
              ? Center(child: Text("데이터 계산 중...", style: TextStyle(color: Colors.grey.shade600)))
              : makeTop5List(),
          ),
        ],
      ),
    );
  }

  // --- TOP5 리스트 만들기 ---
  Widget makeTop5List() {
    return ListView.separated(
      separatorBuilder: (_, __) => SizedBox(height: 6),
      itemCount: top5List.length > 5 ? 5 : top5List.length,
      itemBuilder: (_, index) {
        final item = top5List[index];
        // 순위별 색상 (파란색 계열로 통일)
        final colors = [
          primaryColor.withValues(alpha: 0.2),    // 1위: 진한 파란색
          primaryColor.withValues(alpha: 0.15),   // 2위: 중간 파란색
          primaryColor.withValues(alpha: 0.1),    // 3위: 연한 파란색
          lightGray,                              // 4위: 연한 회색
          lightGray,                              // 5위: 연한 회색
        ];
        
        return Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: colors[index],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['name']?.toString() ?? '',
                  style: TextStyle(fontSize: 14, height: 1.1),
                  overflow: TextOverflow.ellipsis,
                )
              ),
              Text(
                "${addComma(item['sales'] ?? 0)}원",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 하단 관리 메뉴 만들기 ---
  Widget makeBottomMenu() {
    return Row(
      children: [
        Expanded(child: makeCustomerMenu()),    // 고객분석
        SizedBox(width: 16),
        Expanded(child: makePackageMenu()),     // 패키지관리
        SizedBox(width: 16),
        Expanded(child: makeInquiryMenu()),     // 문의
      ],
    );
  }

  // --- 고객분석 메뉴 만들기 ---
  Widget makeCustomerMenu() {
    return Container(
      height: 320,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mediumGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("고객분석", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
          SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text("고객 분석 차트 (구현 예정)", style: TextStyle(color: Colors.grey.shade600)),
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('고객분석'),
            ),
          ),
        ],
      ),
    );
  }

  // --- 패키지관리 메뉴 만들기 ---
  Widget makePackageMenu() {
    return Container(
      height: 320,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mediumGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("패키지관리", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
          SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("패키지 현황", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                  SizedBox(height: 12),
                  makeStatusLine("모집중", openPackage),
                  SizedBox(height: 6),
                  makeStatusLine("모집마감", closePackage),
                  SizedBox(height: 6),
                  makeStatusLine("출발확정", goPackage),
                  Spacer(),
                  Divider(height: 16, color: mediumGray),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("총 패키지", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor)),
                      Text("$allPackage개", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => TravelPackageMain()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('패키지관리'),
            ),
          ),
        ],
      ),
    );
  }

  // --- 문의 메뉴 만들기 ---
  Widget makeInquiryMenu() {
    return Container(
      height: 320,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mediumGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("문의", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
          SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text("문의 현황 (구현 예정)", style: TextStyle(color: Colors.grey.shade600)),
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text('문의'),
            ),
          ),
        ],
      ),
    );
  }

  // --- 상태 줄 만들기 ---
  Widget makeStatusLine(String label, int count) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: secondaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13)),
            ],
          ),
          Text("${count}개", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // ------ 일반 함수들 ------

  // --- 숫자에 콤마 넣는 함수 ---
  String addComma(int number) {
    if (number == 0) return '0';
    
    String numText = number.toString();
    String result = '';
    int digitCount = 0;
    
    for (int i = numText.length - 1; i >= 0; i--) {
      if (digitCount > 0 && digitCount % 3 == 0) {
        result = ',' + result;
      }
      result = numText[i] + result;
      digitCount++;
    }
    
    return result;
  }

  // --- 패키지 데이터 가져오기 ---
  Future<void> getPackageData() async {
    try {
      final firebaseResponse = await FirebaseFirestore.instance.collection('package').get();
      final allPackageDocs = firebaseResponse.docs;
      
      allPackage = allPackageDocs.length;
      openPackage = 0;
      closePackage = 0;
      goPackage = 0;
      
      for (int docIndex = 0; docIndex < allPackageDocs.length; docIndex++) {
        final currentPackageDoc = allPackageDocs[docIndex];
        final packageData = currentPackageDoc.data();
        
        String packageState = '';
        
        if (packageData['pState'] != null) {
          packageState = packageData['pState'].toString();
        }
        
        if (packageState == '모집중') {
          openPackage = openPackage + 1;
        } else if (packageState == '모집마감') {
          closePackage = closePackage + 1;
        } else if (packageState == '출발확정') {
          goPackage = goPackage + 1;
        }
      }
      
      setState(() {});
      
    } catch (error) {
      allPackage = 0;
      openPackage = 0;
      closePackage = 0;
      goPackage = 0;
      setState(() {});
    }
  }

  // --- 예약 데이터 가져오기 ---
  Future<void> getBookingData() async {
    try {
      final currentDate = DateTime.now();
      final thisMonthString = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}';
      
      final firebaseResponse = await FirebaseFirestore.instance.collection('booking').get();
      final allBookingDocs = firebaseResponse.docs;
      
      List<QueryDocumentSnapshot> thisMonthBookings = [];
      for (var bookingDoc in allBookingDocs) {
        final bookingData = bookingDoc.data() as Map<String, dynamic>;
        
        String bookingDate = '';
        if (bookingData['bDate'] != null) {
          bookingDate = bookingData['bDate'].toString();
        }
        
        if (bookingDate.startsWith(thisMonthString)) {
          thisMonthBookings.add(bookingDoc);
        }
      }
      
      int completedCount = 0;
      int canceledCount = 0;
      int totalSalesAmount = 0;
      
      for (int bookingIndex = 0; bookingIndex < thisMonthBookings.length; bookingIndex++) {
        final currentBookingDoc = thisMonthBookings[bookingIndex];
        final bookingData = currentBookingDoc.data() as Map<String, dynamic>;
        
        String bookingState = '';
        int bookingPrice = 0;
        
        if (bookingData['bState'] != null) {
          bookingState = bookingData['bState'].toString();
        }
        
        if (bookingData['aPrice'] != null) {
          final priceString = bookingData['aPrice'].toString();
          bookingPrice = int.tryParse(priceString) ?? 0;
        }
        
        if (bookingState == '결제완료') {
          completedCount = completedCount + 1;
          totalSalesAmount = totalSalesAmount + bookingPrice;
        } else if (bookingState == '취소') {
          canceledCount = canceledCount + 1;
        }
      }
      
      thisMonthGuest = '${completedCount}명';
      thisMonthMoney = '${addComma(totalSalesAmount)}원';
      
      if (thisMonthBookings.length > 0) {
        final cancelRateNumber = (canceledCount / thisMonthBookings.length * 100);
        final cancelRateString = cancelRateNumber.toStringAsFixed(1);
        cancelPercent = '${cancelRateString}%';
      } else {
        cancelPercent = '0%';
      }
      
      returnPercent = '0%';
      top5List = [];
      
      setState(() {});
      
    } catch (error) {
      thisMonthGuest = '0명';
      thisMonthMoney = '0원';
      cancelPercent = '0%';
      returnPercent = '0%';
      top5List = [];
      setState(() {});
    }
  }

}
