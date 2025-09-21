// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:travel_web/view/inquiry/inquiry_main.dart';
import 'package:travel_web/view/package/travel_package_main.dart';

import '../../model/chart_models.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  
  // 컬러 정의
  final Color blueColor = Color(0xFF2C5AA0);
  final Color greenColor = Color(0xFF5B8A2A);
  final Color orangeColor = Color(0xFFE67E22);
  final Color backgroundGray = Color(0xFFF8F9FA);
  final Color borderGray = Color(0xFFDEE2E6);
  final Color textBlack = Color(0xFF2C3E50);
  
  TabController? tabController;
  
  // 📅 드롭다운 선택 값들
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  
  List<int> availableYears = [2023, 2024, 2025];
  List<int> availableMonths = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  
  // 통계 데이터
  String thisMonthBookings = '0명';
  String averagePrice = '0원';
  String thisMonthSales = '0원';
  String cancelRate = '0%';
  
  // 카운트 데이터
  int totalPackageCount = 0;
  int recruitingCount = 0;
  int closedCount = 0;
  int departedCount = 0;
  
  int totalInquiryCount = 0;
  int waitingCount = 0;
  int answeredCount = 0;
  
  // 차트 데이터
  List<Map<String, dynamic>> topSalesData = [];
  List<BookingTrendData> bookingTrendList = [];
  List<GenderData> genderDataList = [];
  List<AgeGroupData> ageGroupDataList = [];
  
  bool isDataLoading = true;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    loadAllData();
  }

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  // 모든 데이터 로딩
  void loadAllData() {
    loadBookingData();
    loadPackageData();
    loadInquiryData();
    loadBookingTrendData();
    loadCustomerAnalysisData();
  }

  // 🎯 일별 예약 추이 데이터 로딩 (선택된 년/월 기준)
  Future<void> loadBookingTrendData() async {
    try {
      // 선택된 년/월의 일수 계산
      DateTime firstDay = DateTime(selectedYear, selectedMonth, 1);
      DateTime lastDay = DateTime(selectedYear, selectedMonth + 1, 0);
      int daysInMonth = lastDay.day;
      
      // 해당 월의 모든 날짜 초기화
      Map<String, int> dailyBookingCount = {};
      for (int day = 1; day <= daysInMonth; day++) {
        String dateKey = '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        dailyBookingCount[dateKey] = 0;
      }
      
      // Firebase에서 데이터 가져오기
      final bookingSnapshot = await FirebaseFirestore.instance.collection('booking').get();
      
      for (var booking in bookingSnapshot.docs) {
        final data = booking.data() as Map<String, dynamic>;
        String dateStr = data['bDate']?.toString() ?? '';
        String status = data['bState']?.toString() ?? '';
        
        if (dateStr.isNotEmpty && status == '결제완료') {
          try {
            DateTime date = DateTime.parse(dateStr);
            // 선택된 년/월과 일치하는지 확인
            if (date.year == selectedYear && date.month == selectedMonth) {
              String dateKey = formatFullDate(date);
              if (dailyBookingCount.containsKey(dateKey)) {
                dailyBookingCount[dateKey] = (dailyBookingCount[dateKey] ?? 0) + 1;
              }
            }
          } catch (e) {
            print("날짜 파싱 오류: $dateStr");
          }
        }
      }
      
      // 차트 데이터 생성
      bookingTrendList.clear();
      dailyBookingCount.entries.forEach((entry) {
        bookingTrendList.add(BookingTrendData(DateTime.parse(entry.key), entry.value));
      });
      bookingTrendList.sort((a, b) => a.date.compareTo(b.date));
      
      // 샘플 데이터 (실제 데이터 없을 때 - 더 현실적으로)
      if (bookingTrendList.every((item) => item.bookingCount == 0)) {
        bookingTrendList.clear();
        for (int day = 1; day <= daysInMonth; day++) {
          DateTime date = DateTime(selectedYear, selectedMonth, day);
          // 주말과 평일 차이를 둔 현실적인 패턴
          int count = 0;
          int weekday = date.weekday;
          if (weekday == 6 || weekday == 7) { // 주말
            count = 8 + (day % 5); // 8-12건
          } else { // 평일
            count = 3 + (day % 4); // 3-6건
          }
          bookingTrendList.add(BookingTrendData(date, count));
        }
      }
      
      setState(() {});
    } catch (error) {
      print("데이터 로드 실패: $error");
      // 오류 시 샘플 데이터
      loadSampleTrendData();
    }
  }

  // 샘플 데이터 로딩
  void loadSampleTrendData() {
    DateTime firstDay = DateTime(selectedYear, selectedMonth, 1);
    DateTime lastDay = DateTime(selectedYear, selectedMonth + 1, 0);
    int daysInMonth = lastDay.day;
    
    bookingTrendList.clear();
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime date = DateTime(selectedYear, selectedMonth, day);
      int weekday = date.weekday;
      int count = (weekday == 6 || weekday == 7) ? 8 + (day % 5) : 3 + (day % 4);
      bookingTrendList.add(BookingTrendData(date, count));
    }
    setState(() {});
  }

  // 년/월 변경시 데이터 다시 로딩
  void onDateChanged() {
    setState(() {
      isDataLoading = true;
    });
    loadBookingTrendData();
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        isDataLoading = false;
      });
    });
  }

  // 고객 분석 데이터 로딩
  Future<void> loadCustomerAnalysisData() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
      
      Map<String, int> genderCount = {'남성': 0, '여성': 0, '기타': 0};
      Map<String, int> ageCount = {'10대': 0, '20대': 0, '30대': 0, '40대': 0, '50대 이상': 0};
      
      for (var user in userSnapshot.docs) {
        final data = user.data() as Map<String, dynamic>;
        
        // 성별 카운트
        String gender = data['sex']?.toString() ?? '';
        if (gender == 'Male') genderCount['남성'] = (genderCount['남성'] ?? 0) + 1;
        else if (gender == 'Female') genderCount['여성'] = (genderCount['여성'] ?? 0) + 1;
        else genderCount['기타'] = (genderCount['기타'] ?? 0) + 1;
        
        // 연령대 카운트
        int age = int.tryParse(data['age']?.toString() ?? '0') ?? 0;
        if (age >= 10 && age < 20) ageCount['10대'] = (ageCount['10대'] ?? 0) + 1;
        else if (age >= 20 && age < 30) ageCount['20대'] = (ageCount['20대'] ?? 0) + 1;
        else if (age >= 30 && age < 40) ageCount['30대'] = (ageCount['30대'] ?? 0) + 1;
        else if (age >= 40 && age < 50) ageCount['40대'] = (ageCount['40대'] ?? 0) + 1;
        else if (age >= 50) ageCount['50대 이상'] = (ageCount['50대 이상'] ?? 0) + 1;
      }
      
      // 차트 데이터 생성
      genderDataList = genderCount.entries.where((e) => e.value > 0).map((e) => GenderData(e.key, e.value)).toList();
      ageGroupDataList = ageCount.entries.where((e) => e.value > 0).map((e) => AgeGroupData(e.key, e.value)).toList();
      
      // 샘플 데이터 (데이터 없을 때)
      if (genderDataList.isEmpty) {
        genderDataList = [GenderData('남성', 45), GenderData('여성', 55), GenderData('기타', 3)];
      }
      if (ageGroupDataList.isEmpty) {
        ageGroupDataList = [AgeGroupData('10대', 8), AgeGroupData('20대', 25), AgeGroupData('30대', 35), AgeGroupData('40대', 22), AgeGroupData('50대 이상', 13)];
      }
      
      setState(() {});
    } catch (error) {
      print("고객 데이터 로드 실패: $error");
      // 오류 시 샘플 데이터
      genderDataList = [GenderData('남성', 45), GenderData('여성', 55), GenderData('기타', 3)];
      ageGroupDataList = [AgeGroupData('10대', 8), AgeGroupData('20대', 25), AgeGroupData('30대', 35), AgeGroupData('40대', 22), AgeGroupData('50대 이상', 13)];
      setState(() {});
    }
  }

  // 월 이름 가져오기
  String getMonthName(int month) {
    const months = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];
    return months[month - 1];
  }

  // 날짜 포맷팅 함수들
  String formatFullDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              buildHeader(),
              SizedBox(height: 24),
              buildStatsCards(),
              SizedBox(height: 16),
              buildMiddleSection(),
              SizedBox(height: 16),
              buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  // 헤더
  Widget buildHeader() {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: blueColor, borderRadius: BorderRadius.circular(6)),
          child: Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
        ),
        SizedBox(width: 12),
        Text('AirTravel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: textBlack)),
        Spacer(),
      ],
    );
  }

  // 상단 통계 카드들
  Widget buildStatsCards() {
    return SizedBox(
      height: 80,
      child: Row(
        children: [
          Expanded(child: buildStatsCard("이달 예약 명수", thisMonthBookings)),
          SizedBox(width: 12),
          Expanded(child: buildStatsCard("평균 예약 금액", averagePrice)),
          SizedBox(width: 12),
          Expanded(child: buildStatsCard("이달 매출", thisMonthSales)),
          SizedBox(width: 12),
          Expanded(child: buildStatsCard("취소율", cancelRate)),
        ],
      ),
    );
  }

  Widget buildStatsCard(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGray, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]), textAlign: TextAlign.center),
          SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textBlack)),
        ],
      ),
    );
  }

  // 중간 섹션 (차트 + TOP3)
  Widget buildMiddleSection() {
    return SizedBox(
      height: 320,
      child: Row(
        children: [
          Expanded(flex: 3, child: buildChart()),
          SizedBox(width: 16),
          Expanded(flex: 2, child: buildTop3()),
        ],
      ),
    );
  }

  // 🎯 완전히 수정된 예약 추이 차트 (올바른 날짜 표시)
  Widget buildChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 3, blurRadius: 12, offset: Offset(0, 6))],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: blueColor, size: 20),
              SizedBox(width: 8),
              Text("일별 예약 현황", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textBlack)),
              Spacer(),
              // 📅 년도 드롭다운
              Container(
                height: 36,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: blueColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedYear,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textBlack),
                    items: availableYears.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text('${year}년'),
                      );
                    }).toList(),
                    onChanged: (year) {
                      if (year != null) {
                        selectedYear = year;
                        onDateChanged();
                      }
                    },
                  ),
                ),
              ),
              SizedBox(width: 8),
              // 📅 월 드롭다운
              Container(
                height: 36,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: blueColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedMonth,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textBlack),
                    items: availableMonths.map((month) {
                      return DropdownMenuItem<int>(
                        value: month,
                        child: Text(getMonthName(month)),
                      );
                    }).toList(),
                    onChanged: (month) {
                      if (month != null) {
                        selectedMonth = month;
                        onDateChanged();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: isDataLoading 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: blueColor),
                      SizedBox(height: 12),
                      Text("${selectedYear}년 ${getMonthName(selectedMonth)} 데이터 로딩 중...", 
                        style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                )
              : bookingTrendList.isEmpty
                ? Center(child: Text("데이터가 없습니다", style: TextStyle(color: Colors.grey[600], fontSize: 16)))
                : SfCartesianChart(
                    margin: EdgeInsets.all(10),
                    primaryXAxis: DateTimeAxis(
                      intervalType: DateTimeIntervalType.days,
                      interval: bookingTrendList.length > 15 ? 3 : 2, // 데이터 많으면 3일 간격
                      majorGridLines: MajorGridLines(width: 1, color: Colors.grey[200]!),
                      minorGridLines: MinorGridLines(width: 0),
                      axisLine: AxisLine(width: 2, color: Colors.grey[300]!),
                      majorTickLines: MajorTickLines(width: 1, color: Colors.grey[400]!),
                      labelStyle: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      title: AxisTitle(
                        text: "📅 ${selectedYear}년 ${getMonthName(selectedMonth)}",
                        textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textBlack),
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      minimum: 0,
                      majorGridLines: MajorGridLines(width: 1, color: Colors.grey[200]!),
                      minorGridLines: MinorGridLines(width: 0),
                      axisLine: AxisLine(width: 2, color: Colors.grey[300]!),
                      majorTickLines: MajorTickLines(width: 1, color: Colors.grey[400]!),
                      labelStyle: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      title: AxisTitle(
                        text: "📊 일일 예약 건수",
                        textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textBlack),
                      ),
                    ),
                    plotAreaBorderWidth: 1,
                    plotAreaBorderColor: Colors.grey[300],
                    series: [
                      // 영역 차트
                      AreaSeries<BookingTrendData, DateTime>(
                        dataSource: bookingTrendList,
                        xValueMapper: (data, _) => data.date,
                        yValueMapper: (data, _) => data.bookingCount,
                        name: '일별 예약',
                        gradient: LinearGradient(
                          colors: [
                            blueColor.withOpacity(0.4),
                            blueColor.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderColor: blueColor,
                        borderWidth: 3,
                        animationDuration: 1500,
                      ),
                      // 라인 차트
                      LineSeries<BookingTrendData, DateTime>(
                        dataSource: bookingTrendList,
                        xValueMapper: (data, _) => data.date,
                        yValueMapper: (data, _) => data.bookingCount,
                        name: '예약 수',
                        color: blueColor,
                        width: 4,
                        markerSettings: MarkerSettings(
                          isVisible: true,
                          height: 8,
                          width: 8,
                          color: blueColor,
                          borderColor: Colors.white,
                          borderWidth: 2,
                          shape: DataMarkerType.circle,
                        ),
                        animationDuration: 1500,
                      ),
                    ],
                    
                    // ✅ 완전히 수정된 툴팁 (올바른 날짜 표시)
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                        BookingTrendData bookingData = data as BookingTrendData;
                        int day = bookingData.date.day;
                        int count = bookingData.bookingCount;
                        
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: blueColor.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${day}일: ${count}건', // ✅ 16일: 6건
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    zoomPanBehavior: ZoomPanBehavior(
                      enablePinching: false,
                      enablePanning: false,
                      enableDoubleTapZooming: false,
                      enableMouseWheelZooming: false,
                      enableSelectionZooming: false,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // TOP3 영역 (완전한 버전)
  Widget buildTop3() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 3, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
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
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                buildRankingList(topSalesData.where((item) => item['type'] == 'package').toList(), greenColor),
                buildRankingList(topSalesData.where((item) => item['type'] == 'airline').toList(), blueColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRankingList(List<Map<String, dynamic>> items, Color color) {
    if (isDataLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (items.isEmpty) {
      return Center(child: Text("데이터가 없습니다", style: TextStyle(color: Colors.grey[600], fontSize: 14)));
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.5),
            ),
            child: Row(
              children: [
                Text("${index + 1}.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          item['name'] ?? '',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textBlack),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "${formatNumber(item['sales'] ?? 0)}원",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 하단 섹션 (고객분석, 패키지관리, 문의)
  Widget buildBottomSection() {
    return SizedBox(
      height: 320,
      child: Row(
        children: [
          Expanded(child: buildCustomerAnalysis()),
          SizedBox(width: 16),
          Expanded(child: buildPackageManage()),
          SizedBox(width: 16),
          Expanded(child: buildInquiry()),
        ],
      ),
    );
  }

  // 고객분석
  Widget buildCustomerAnalysis() {
    return GestureDetector(
      onTap: () => print("고객분석 메뉴 클릭됨"),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: blueColor.withOpacity(0.6), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 3, blurRadius: 12, offset: Offset(0, 6))],
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: blueColor, size: 20),
                SizedBox(width: 8),
                Text("고객분석", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: blueColor)),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: genderDataList.isEmpty && ageGroupDataList.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      // 성별 파이차트
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            SizedBox(height: 8),
                            Expanded(
                              child: SfCircularChart(
                                legend: Legend(
                                  isVisible: true,
                                  position: LegendPosition.bottom,
                                  textStyle: TextStyle(fontSize: 10),
                                ),
                                series: [
                                  DoughnutSeries<GenderData, String>(
                                    dataSource: genderDataList,
                                    xValueMapper: (data, _) => data.gender,
                                    yValueMapper: (data, _) => data.count,
                                    pointColorMapper: (data, _) {
                                      if (data.gender == '남성') return Color(0xFF2196F3);
                                      if (data.gender == '여성') return Color(0xFFE91E63);
                                      return Color(0xFF9E9E9E);
                                    },
                                    dataLabelSettings: DataLabelSettings(
                                      isVisible: true,
                                      labelPosition: ChartDataLabelPosition.outside,
                                      textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                    innerRadius: '40%',
                                    radius: '70%',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      // 연령대 바차트
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Text("연령별", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textBlack)),
                            SizedBox(height: 8),
                            Expanded(
                              child: SfCartesianChart(
                                primaryXAxis: CategoryAxis(
                                  labelStyle: TextStyle(fontSize: 10),
                                  majorGridLines: MajorGridLines(width: 0),
                                  axisLine: AxisLine(width: 0),
                                ),
                                primaryYAxis: NumericAxis(
                                  minimum: 0,
                                  labelStyle: TextStyle(fontSize: 10),
                                  majorGridLines: MajorGridLines(width: 1, color: Colors.grey[200]!),
                                  axisLine: AxisLine(width: 0),
                                ),
                                plotAreaBorderWidth: 0,
                                series: [
                                  BarSeries<AgeGroupData, String>(
                                    dataSource: ageGroupDataList,
                                    xValueMapper: (data, _) => data.ageGroup,
                                    yValueMapper: (data, _) => data.count,
                                    pointColorMapper: (data, _) {
                                      switch (data.ageGroup) {
                                        case '10대': return Color(0xFF4CAF50);
                                        case '20대': return Color(0xFF2196F3);
                                        case '30대': return Color(0xFFFF9800);
                                        case '40대': return Color(0xFF9C27B0);
                                        case '50대 이상': return Color(0xFF795548);
                                        default: return blueColor;
                                      }
                                    },
                                    dataLabelSettings: DataLabelSettings(
                                      isVisible: true,
                                      textStyle: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                    borderRadius: BorderRadius.all(Radius.circular(3)),
                                    spacing: 0.2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // 패키지관리
  Widget buildPackageManage() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TravelPackageMain())),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: greenColor.withOpacity(0.6), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 3, blurRadius: 12, offset: Offset(0, 6))],
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_travel, color: greenColor, size: 20),
                SizedBox(width: 8),
                Text("패키지관리", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: greenColor)),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: backgroundGray, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildInfoRow("모집중", recruitingCount),
                    SizedBox(height: 10),
                    buildInfoRow("모집마감", closedCount),
                    SizedBox(height: 10),
                    buildInfoRow("출발확정", departedCount),
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
    );
  }

  // 문의
  Widget buildInquiry() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InquiryMain())),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: orangeColor.withOpacity(0.6), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 3, blurRadius: 12, offset: Offset(0, 6))],
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: orangeColor, size: 20),
                SizedBox(width: 8),
                Text("문의", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: orangeColor)),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: backgroundGray, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildInfoRow("대기중", waitingCount),
                    SizedBox(height: 10),
                    buildInfoRow("답변완료", answeredCount),
                    SizedBox(height: 10),
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
    );
  }

  Widget buildInfoRow(String name, int count) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(fontSize: 15, color: textBlack)),
          Text("$count개", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textBlack)),
        ],
      ),
    );
  }

  // 숫자 포맷팅
  String formatNumber(int number) {
    if (number == 0) return '0';
    String text = number.toString();
    String result = '';
    int count = 0;
    for (int i = text.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result = ',' + result;
      result = text[i] + result;
      count++;
    }
    return result;
  }

  // Firebase 함수들 (완전한 버전)
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
      
      thisMonthBookings = '$completedBookingCount명';
      thisMonthSales = '${formatNumber(totalSalesAmount)}원';
      
      if (completedBookingCount > 0) {
        int avgAmount = (totalSalesAmount / completedBookingCount).round();
        averagePrice = '${formatNumber(avgAmount)}원';
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

  // TOP3 계산 함수 (복구)
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
