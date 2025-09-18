// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_web/view/inquiry/inquiry_main.dart';
import 'package:travel_web/view/package/travel_package_main.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  
  // [1단계] 앱에서 사용할 색깔 정의
  final Color blueColor = Color(0xFF2C5AA0);        // 파란색
  final Color greenColor = Color(0xFF5B8A2A);       // 초록색  
  final Color orangeColor = Color(0xFFE67E22);      // 주황색
  final Color backgroundGray = Color(0xFFF8F9FA);   // 배경 회색
  final Color borderGray = Color(0xFFDEE2E6);       // 테두리 회색
  final Color textBlack = Color(0xFF2C3E50);        // 글자 검은색
  
  TabController? tabController;
  
  // [2단계] 화면에 표시할 데이터 변수들
  String thisMonthBookings = '0명';      // 이달 예약 명수
  String averagePrice = '0원';           // 평균 예약 금액
  String thisMonthSales = '0원';         // 이달 매출
  String cancelRate = '0%';              // 취소율
  
  // 패키지 현황 숫자들
  int totalPackageCount = 0;     // 총 패키지 수
  int recruitingCount = 0;       // 모집중 패키지 수
  int closedCount = 0;           // 모집마감 패키지 수
  int departedCount = 0;         // 출발확정 패키지 수
  
  // 문의 현황 숫자들
  int totalInquiryCount = 0;     // 총 문의 수
  int waitingCount = 0;          // 대기중 문의 수
  int answeredCount = 0;         // 답변완료 문의 수
  
  // TOP3 순위 리스트
  List<Map<String, dynamic>> topSalesData = [];
  bool isDataLoading = true;

  @override
  void initState() {
    super.initState();
    // [3단계] 앱 시작할 때 필요한 설정
    tabController = TabController(length: 2, vsync: this);
    loadAllDataFromFirebase();
  }

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  // [4단계] Firebase에서 모든 데이터 가져오기
  void loadAllDataFromFirebase() {
    loadBookingData();      // 예약 데이터 가져오기
    loadPackageData();      // 패키지 데이터 가져오기  
    loadInquiryData();      // 문의 데이터 가져오기
  }

  @override
  Widget build(BuildContext context) {
    // 탭컨트롤러가 준비 안됐으면 로딩 표시
    if (tabController == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: backgroundGray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // [5단계] 맨 위에 로고 만들기
              buildHeaderLogo(),
              SizedBox(height: 24),
              
              // [6단계] 첫 번째 줄 - 4개 정보 카드
              SizedBox(height: 80, child: buildTopStatsCards()),
              SizedBox(height: 16),
              
              // [7단계] 두 번째 줄 - 차트와 TOP3
              SizedBox(height: 320, child: buildMiddleSection()),
              SizedBox(height: 16),
              
              // [8단계] 세 번째 줄 - 관리 메뉴 3개
              SizedBox(height: 320, child: buildBottomMenus()),
            ],
          ),
        ),
      ),
    );
  }

  // [로고 영역] AirTravel 로고 만들기
  Widget buildHeaderLogo() {
    return Row(
      children: [
        // 비행기 아이콘
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: blueColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
        ),
        SizedBox(width: 12),
        // AirTravel 글자
        Text('AirTravel', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 22,
            color: textBlack
          )
        ),
        Spacer(),
      ],
    );
  }

  // [첫 번째 줄] 4개 정보 카드 만들기
  Widget buildTopStatsCards() {
    return Row(
      children: [
        Expanded(child: buildSingleStatsCard("이달 예약 명수", thisMonthBookings)),
        SizedBox(width: 12),
        Expanded(child: buildSingleStatsCard("평균 예약 금액", averagePrice)),
        SizedBox(width: 12),
        Expanded(child: buildSingleStatsCard("이달 매출", thisMonthSales)),
        SizedBox(width: 12),
        Expanded(child: buildSingleStatsCard("취소율", cancelRate)),
      ],
    );
  }

  // [정보 카드] 하나의 정보 카드 만들기
  Widget buildSingleStatsCard(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGray, width: 1.5),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 카드 제목 (회색으로 작게)
          Text(
            title, 
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600]
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          // 카드 값 (검은색으로 크게)
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textBlack,
            ),
          ),
        ],
      ),
    );
  }

  // [두 번째 줄] 차트와 TOP3 영역 만들기
  Widget buildMiddleSection() {
    return Row(
      children: [
        // 왼쪽 차트 영역 (넓게)
        Expanded(flex: 3, child: buildChartArea()),
        SizedBox(width: 16),
        // 오른쪽 TOP3 영역 (좁게)
        Expanded(flex: 2, child: buildTop3Area()),
      ],
    );
  }

  // [차트 영역] 예약 추이 차트 영역
  Widget buildChartArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray, width: 1.5),
        // ignore: deprecated_member_use
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 3, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("예약 추이", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textBlack)),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: backgroundGray, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text("예약 추이 차트 (구현 예정)", style: TextStyle(color: Colors.grey[600], fontSize: 16))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [TOP3 영역] 매출 TOP3 영역
  Widget buildTop3Area() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray, width: 1.5),
        // ignore: deprecated_member_use
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 3, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
          // TOP3 제목과 탭 버튼들
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("이달 매출 TOP3", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textBlack)),
                    SizedBox(width: 8),
                    if (isDataLoading) SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                SizedBox(height: 12),
                // 패키지/항공편 탭
                TabBar(
                  controller: tabController,
                  labelColor: textBlack,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: blueColor,
                  tabs: [
                    Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.card_travel, size: 16), SizedBox(width: 4), Text("패키지", style: TextStyle(fontSize: 14))])),
                    Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.flight, size: 16), SizedBox(width: 4), Text("항공편", style: TextStyle(fontSize: 14))])),
                  ],
                ),
              ],
            ),
          ),
          // 탭 내용들
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [buildPackageTab(), buildFlightTab()],
            ),
          ),
        ],
      ),
    );
  }

  // [패키지 탭] 패키지 TOP3 리스트
  Widget buildPackageTab() {
    List<Map<String, dynamic>> packageList = topSalesData.where((item) => item['type'] == 'package').toList();
    
    if (isDataLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (packageList.isEmpty) {
      return Center(child: Text("패키지 데이터가 없습니다", style: TextStyle(color: Colors.grey[600], fontSize: 14)));
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ListView.builder(
        itemCount: packageList.length,
        itemBuilder: (context, index) {
          return buildRankingItem(index + 1, packageList[index], greenColor);
        },
      ),
    );
  }

  // [항공편 탭] 항공편 TOP3 리스트
  Widget buildFlightTab() {
    List<Map<String, dynamic>> flightList = topSalesData.where((item) => item['type'] == 'airline').toList();
    
    if (isDataLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (flightList.isEmpty) {
      return Center(child: Text("항공편 데이터가 없습니다", style: TextStyle(color: Colors.grey[600], fontSize: 14)));
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ListView.builder(
        itemCount: flightList.length,
        itemBuilder: (context, index) {
          return buildRankingItem(index + 1, flightList[index], blueColor);
        },
      ),
    );
  }

  // [순위 아이템] 1위, 2위, 3위 아이템 만들기
  Widget buildRankingItem(int ranking, Map<String, dynamic> itemData, Color itemColor) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          // ignore: deprecated_member_use
          color: Colors.grey.withOpacity(0.2),
          width: 0.5
        ),
      ),
      child: Row(
        children: [
          // 순위 번호 (1., 2., 3.)
          Text(
            "$ranking.", 
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: itemColor,
            )
          ),
          SizedBox(width: 12),
          
          // 이름과 가격을 양쪽 끝에 배치
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 상품 이름
                Flexible(
                  child: Text(
                    itemData['name'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                // 매출 금액
                Text(
                  "${formatNumberWithComma(itemData['sales'] ?? 0)}원",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: itemColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // [세 번째 줄] 하단 3개 관리 메뉴
  Widget buildBottomMenus() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: buildCustomerAnalysisMenu()),
        SizedBox(width: 16),
        Expanded(child: buildPackageManageMenu()),
        SizedBox(width: 16),
        Expanded(child: buildInquiryMenu()),
      ],
    );
  }

  // [고객분석 메뉴] 파란색 테두리
  Widget buildCustomerAnalysisMenu() {
    return GestureDetector(
      onTap: () => print("고객분석 메뉴 클릭됨"),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // ignore: deprecated_member_use
          border: Border.all(color: blueColor.withOpacity(0.6), width: 1.5),
          // ignore: deprecated_member_use
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 3, blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 메뉴 제목
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: blueColor, size: 20),
                  SizedBox(width: 8),
                  Text("고객분석", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: blueColor)),
                ],
              ),
              SizedBox(height: 16),
              // 차트 영역
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: backgroundGray, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text("고객 분석 차트 (구현 예정)", style: TextStyle(color: Colors.grey[600], fontSize: 14))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [패키지관리 메뉴] 초록색 테두리
  Widget buildPackageManageMenu() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TravelPackageMain())),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // ignore: deprecated_member_use
          border: Border.all(color: greenColor.withOpacity(0.6), width: 1.5),
          // ignore: deprecated_member_use
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 3, blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 메뉴 제목
              Row(
                children: [
                  Icon(Icons.card_travel, color: greenColor, size: 20),
                  SizedBox(width: 8),
                  Text("패키지관리", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: greenColor)),
                ],
              ),
              SizedBox(height: 16),
              // 패키지 현황 정보
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color: backgroundGray, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildStatusInfoRow("모집중", recruitingCount),
                      SizedBox(height: 10),
                      buildStatusInfoRow("모집마감", closedCount),
                      SizedBox(height: 10),
                      buildStatusInfoRow("출발확정", departedCount),
                      SizedBox(height: 16),
                      Container(height: 1, color: borderGray),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("총 패키지", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textBlack)),
                          Text("$totalPackageCount개", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textBlack)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [문의 메뉴] 주황색 테두리
  Widget buildInquiryMenu() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InquiryMain())),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // ignore: deprecated_member_use
          border: Border.all(color: orangeColor.withOpacity(0.6), width: 1.5),
          // ignore: deprecated_member_use
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 3, blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 메뉴 제목
              Row(
                children: [
                  Icon(Icons.help_outline, color: orangeColor, size: 20),
                  SizedBox(width: 8),
                  Text("문의", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: orangeColor)),
                ],
              ),
              SizedBox(height: 16),
              // 문의 현황 정보
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color: backgroundGray, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildStatusInfoRow("대기중", waitingCount),
                      SizedBox(height: 10),
                      buildStatusInfoRow("답변완료", answeredCount),
                      SizedBox(height: 10),
                      
                      // 패키지 메뉴와 높이 맞추기 위한 빈 공간
                      SizedBox(height: 20),
                      
                      SizedBox(height: 16),
                      Container(height: 1, color: borderGray),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("총 문의", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textBlack)),
                          Text("$totalInquiryCount개", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textBlack)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [상태 정보 줄] 상태와 개수를 한 줄에 표시
  Widget buildStatusInfoRow(String statusName, int count) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(statusName, style: TextStyle(fontSize: 15, color: textBlack)),
          Text("$count개", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textBlack)),
        ],
      ),
    );
  }

  // [도구 함수] 숫자에 콤마 넣기 (1000 → 1,000)
  String formatNumberWithComma(int number) {
    if (number == 0) return '0';
    String numberText = number.toString();
    String result = '';
    int digitCount = 0;
    for (int i = numberText.length - 1; i >= 0; i--) {
      if (digitCount > 0 && digitCount % 3 == 0) {
        result = ',' + result;
      }
      result = numberText[i] + result;
      digitCount++;
    }
    return result;
  }

  // ================== Firebase 데이터 로딩 함수들 ==================

  // 예약 데이터를 Firebase에서 가져와서 화면에 표시할 값들 계산
  Future<void> loadBookingData() async {
    setState(() => isDataLoading = true);
    
    try {
      final today = DateTime.now();
      final thisMonth = '${today.year}-${today.month.toString().padLeft(2, '0')}';
      
      final bookingSnapshot = await FirebaseFirestore.instance.collection('booking').get();
      final allBookings = bookingSnapshot.docs;
      
      List<QueryDocumentSnapshot> thisMonthBookingList = [];
      for (var booking in allBookings) {
        final bookingData = booking.data();
        String bookingDate = bookingData['bDate']?.toString() ?? '';
        
        if (bookingDate.startsWith(thisMonth)) {
          thisMonthBookingList.add(booking);
        }
      }
      
      int completedBookingCount = 0;
      int canceledBookingCount = 0;
      int totalSalesAmount = 0;
      
      for (var booking in thisMonthBookingList) {
        final bookingData = booking.data() as Map<String, dynamic>;
        
        String status = bookingData['bState']?.toString() ?? '';
        int price = int.tryParse(bookingData['aPrice']?.toString() ?? '0') ?? 0;
        
        if (status == '결제완료') {
          completedBookingCount++;
          totalSalesAmount += price;
        } else if (status == '취소') {
          canceledBookingCount++;
        }
      }
      
      // 화면에 표시할 값들 계산
      thisMonthBookings = '$completedBookingCount명';
      thisMonthSales = '${formatNumberWithComma(totalSalesAmount)}원';
      
      if (completedBookingCount > 0) {
        int avgAmount = (totalSalesAmount / completedBookingCount).round();
        averagePrice = '${formatNumberWithComma(avgAmount)}원';
      } else {
        averagePrice = '0원';
      }
      
      if (thisMonthBookingList.isNotEmpty) {
        double cancelPercent = (canceledBookingCount / thisMonthBookingList.length * 100);
        cancelRate = '${cancelPercent.toStringAsFixed(1)}%';
      } else {
        cancelRate = '0.0%';
      }
      
      await calculateTop3Sales(thisMonthBookingList);
      
    } catch (error) {
      print("예약 데이터 로드 실패: $error");
      thisMonthBookings = '0명';
      thisMonthSales = '0원';
      averagePrice = '0원';
      cancelRate = '0.0%';
      topSalesData = [];
    }
    
    setState(() => isDataLoading = false);
  }

  // TOP3 매출 순위 계산
  Future<void> calculateTop3Sales(List<QueryDocumentSnapshot> bookingList) async {
    Map<String, int> packageSalesMap = {};
    Map<String, int> flightSalesMap = {};
    
    for (var booking in bookingList) {
      final bookingData = booking.data() as Map<String, dynamic>;
      String status = bookingData['bState']?.toString() ?? '';
      
      if (status == '결제완료') {
        String productType = bookingData['what']?.toString() ?? '';
        int price = int.tryParse(bookingData['aPrice']?.toString() ?? '0') ?? 0;
        
        if (productType == '패키지') {
          String packageName = await getPackageNameFromId(bookingData);
          packageSalesMap[packageName] = (packageSalesMap[packageName] ?? 0) + price;
        } else if (productType == '항공기') {
          String flightRoute = await getFlightRouteFromId(bookingData);
          flightSalesMap[flightRoute] = (flightSalesMap[flightRoute] ?? 0) + price;
        }
      }
    }
    
    var sortedPackages = packageSalesMap.entries.toList();
    sortedPackages.sort((a, b) => b.value.compareTo(a.value));
    
    var sortedFlights = flightSalesMap.entries.toList();
    sortedFlights.sort((a, b) => b.value.compareTo(a.value));
    
    topSalesData.clear();
    
    for (int i = 0; i < sortedPackages.length && i < 3; i++) {
      topSalesData.add({
        'name': sortedPackages[i].key,
        'sales': sortedPackages[i].value,
        'type': 'package'
      });
    }
    
    for (int i = 0; i < sortedFlights.length && i < 3; i++) {
      topSalesData.add({
        'name': sortedFlights[i].key,
        'sales': sortedFlights[i].value,
        'type': 'airline'
      });
    }
  }

  Future<String> getPackageNameFromId(Map<String, dynamic> bookingData) async {
    try {
      String packageId = bookingData['aid']?.toString() ?? '';
      if (packageId.isEmpty) return '알 수 없는 패키지';
      
      final packageDoc = await FirebaseFirestore.instance.collection('package').doc(packageId).get();
      
      if (packageDoc.exists) {
        final packageInfo = packageDoc.data() as Map<String, dynamic>;
        return packageInfo['pName']?.toString() ?? '패키지명 없음';
      }
      return '알 수 없는 패키지';
    } catch (e) {
      return '패키지 정보 오류';
    }
  }

  Future<String> getFlightRouteFromId(Map<String, dynamic> bookingData) async {
    try {
      String airlineId = bookingData['aid']?.toString() ?? '';
      if (airlineId.isEmpty) return '항공편 정보 없음';
      
      final airlineDoc = await FirebaseFirestore.instance.collection('airplane_start').doc(airlineId).get();
      
      if (airlineDoc.exists) {
        final airlineInfo = airlineDoc.data() as Map<String, dynamic>;
        String destination = airlineInfo['목적지']?.toString() ?? '';
        
        String departure = getAirportName('ICN');
        String arrival = getAirportName(destination);
        
        return '$departure→$arrival';
      }
      return '항공편 정보 없음';
    } catch (e) {
      return '항공편 정보 오류';
    }
  }

  String getAirportName(String airportCode) {
    Map<String, String> airportNames = {
      'ICN': '인천', 'GMP': '김포', 'CJU': '제주', 'PUS': '부산', 'TAE': '대구',
      'FUK': '후쿠오카', 'NRT': '도쿄', 'HND': '도쿄', 'KIX': '오사카', 'NGO': '나고야',
      'BKK': '방콕', 'SGN': '호치민', 'DAD': '다낭', 'SIN': '싱가포르', 'KUL': '쿠알라룸푸르',
      'CDG': '파리', 'LHR': '런던', 'FRA': '프랑크푸르트', 'LAX': '로스앤젤레스', 'JFK': '뉴욕',
      'ADD': '아디스아바바', 'TAO': '청도',
    };
    return airportNames[airportCode] ?? airportCode;
  }

  Future<void> loadPackageData() async {
    try {
      final packageSnapshot = await FirebaseFirestore.instance.collection('package').get();
      final packageList = packageSnapshot.docs;
      
      totalPackageCount = packageList.length;
      recruitingCount = 0;
      closedCount = 0;
      departedCount = 0;
      
      for (var package in packageList) {
        final packageInfo = package.data();
        String status = packageInfo['pState']?.toString() ?? '';
        
        if (status == '모집중'){
          recruitingCount++;
        } 
        else if (status == '모집마감') {
          closedCount++;
        }
        else if (status == '출발확정') {
          departedCount++;
        }
      }
      
      setState(() {});
    } catch (error) {
      print("패키지 데이터 로드 실패: $error");
    }
  }

  Future<void> loadInquiryData() async {
    try {
      final inquirySnapshot = await FirebaseFirestore.instance.collection('inquery').get();
      final inquiryList = inquirySnapshot.docs;
      
      totalInquiryCount = inquiryList.length;
      waitingCount = 0;
      answeredCount = 0;
      
      for (var inquiry in inquiryList) {
        final inquiryInfo = inquiry.data();
        String status = inquiryInfo['state']?.toString() ?? '';
        
        if (status == '대기중') {
          waitingCount++;
        } else if (status == '답변완료') {
          answeredCount++;
        }
      }
      
      setState(() {});
    } catch (error) {
      print("문의 데이터 로드 실패: $error");
    }
  }
}
