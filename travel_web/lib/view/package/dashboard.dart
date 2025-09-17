import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_web/view/inquiry/inquiry_main.dart';
import 'package:travel_web/view/package/travel_package_main.dart';

/// 여행사 관리자 대시보드 화면
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  
  // --- 강화된 테마 컬러 설정 ---
  final Color primaryColor = Color(0xFF2C5AA0);      // 진한 파란색 (고객분석)
  final Color secondaryColor = Color(0xFF5B8A2A);    // 진한 초록색 (패키지관리)
  final Color tertiaryColor = Color(0xFFE67E22);     // 진한 주황색 (문의)
  final Color lightGray = Color(0xFFF8F9FA);         // 밝은 배경
  final Color mediumGray = Color(0xFFDEE2E6);        // 진한 경계선
  final Color darkText = Color(0xFF2C3E50);          // 진한 텍스트
  
  // --- 상단 카드 데이터 ---
  String thisMonthGuest = '0명';
  String thisMonthMoney = '0원';
  String cancelPercent = '0%';
  String returnPercent = '0%';
  
  // --- 패키지 개수 데이터 ---  
  int allPackage = 0;
  int openPackage = 0;
  int closePackage = 0;
  int goPackage = 0;
  
  // --- 문의 개수 데이터 ---
  int allInquiry = 0;
  int waitingInquiry = 0;
  int completeInquiry = 0;
  
  // --- TOP5 리스트 ---
  List<Map<String, dynamic>> top5List = [];

  @override
  void initState() {
    super.initState();
    getPackageData();
    getBookingData();
    getInquiryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: Text(
          "대시보드",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.3),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. 상단 4개 카드
            makeTopCards(),
            SizedBox(height: 32),
            
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
        Text(
          title, 
          style: TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.w600, 
            color: darkText
          )
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mediumGray, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                spreadRadius: 2,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- 중간 영역 만들기 ---
  Widget makeMiddleArea() {
    return Row(
      children: [
        Expanded(flex: 2, child: makeChartArea()),
        SizedBox(width: 16),
        Expanded(flex: 1, child: makeTop5Area()),
      ],
    );
  }

  // --- 차트 영역 만들기 ---
  Widget makeChartArea() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "예약 추이", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkText)
          ),
          SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  "예약 추이 차트 (구현 예정)", 
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16)
                ),
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
      padding: EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "이달 매출 TOP5", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkText)
          ),
          SizedBox(height: 12),
          Expanded(
            child: top5List.isEmpty
              ? Center(child: Text("데이터 계산 중...", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)))
              : makeTop5List(),
          ),
        ],
      ),
    );
  }

  // --- TOP5 리스트 만들기 ---
  Widget makeTop5List() {
    return ListView.separated(
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemCount: top5List.length > 5 ? 5 : top5List.length,
      itemBuilder: (_, index) {
        final item = top5List[index];
        final colors = [
          primaryColor.withOpacity(0.2),
          primaryColor.withOpacity(0.15),
          primaryColor.withOpacity(0.1),
          lightGray,
          lightGray,
        ];
        
        return Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: colors[index],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkText)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['name']?.toString() ?? '',
                  style: TextStyle(fontSize: 14, height: 1.1),
                  overflow: TextOverflow.ellipsis,
                )
              ),
              Text("${addComma(item['sales'] ?? 0)}원", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkText)),
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
        Expanded(child: makeCustomerMenu()),
        SizedBox(width: 16),
        Expanded(child: makePackageMenu()),
        SizedBox(width: 16),
        Expanded(child: makeInquiryMenu()),
      ],
    );
  }

  // --- 고객분석 메뉴 만들기 ---
  Widget makeCustomerMenu() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("고객분석", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkText)),
          SizedBox(height: 14),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text("고객 분석 차트 (구현 예정)", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ),
            ),
          ),
          SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: primaryColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('고객분석', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // --- 패키지관리 메뉴 만들기 (overflow 완전 해결) ---
  Widget makePackageMenu() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("패키지관리", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkText)),
          SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("패키지 현황", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: darkText)),
                  SizedBox(height: 8),
                  makeStatusLine("모집중", openPackage),
                  SizedBox(height: 3),
                  makeStatusLine("모집마감", closePackage),
                  SizedBox(height: 3),
                  makeStatusLine("출발확정", goPackage),
                  SizedBox(height: 8),
                  Divider(height: 8, color: mediumGray, thickness: 1.2),
                  SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("총 패키지", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText)),
                      Text("$allPackage개", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => TravelPackageMain()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: secondaryColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('패키지관리', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // --- 문의 메뉴 만들기 (overflow 완전 해결) ---
  Widget makeInquiryMenu() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("문의", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkText)),
          SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("문의 현황", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: darkText)),
                  SizedBox(height: 8),
                  makeStatusLine("대기중", waitingInquiry),
                  SizedBox(height: 3),
                  makeStatusLine("답변완료", completeInquiry),
                  SizedBox(height: 8),
                  Divider(height: 8, color: mediumGray, thickness: 1.2),
                  SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("총 문의", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText)),
                      Text("$allInquiry개", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkText)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => InquiryMain()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tertiaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: tertiaryColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('문의', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
          Text(label, style: TextStyle(fontSize: 13, color: darkText)),
          Text("${count}개", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: darkText)),
        ],
      ),
    );
  }

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

  // --- 문의 데이터 가져오기 ---
  Future<void> getInquiryData() async {
    try {
      final firebaseResponse = await FirebaseFirestore.instance.collection('inquery').get();
      final allInquiryDocs = firebaseResponse.docs;
      
      allInquiry = allInquiryDocs.length;
      waitingInquiry = 0;
      completeInquiry = 0;
      
      for (int docIndex = 0; docIndex < allInquiryDocs.length; docIndex++) {
        final currentInquiryDoc = allInquiryDocs[docIndex];
        final inquiryData = currentInquiryDoc.data();
        
        String inquiryState = '';
        if (inquiryData['state'] != null) {
          inquiryState = inquiryData['state'].toString();
        }
        
        if (inquiryState == '대기중') {
          waitingInquiry = waitingInquiry + 1;
        } else if (inquiryState == '답변완료') {
          completeInquiry = completeInquiry + 1;
        }
      }
      
      setState(() {});
      
    } catch (error) {
      allInquiry = 0;
      waitingInquiry = 0;
      completeInquiry = 0;
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
