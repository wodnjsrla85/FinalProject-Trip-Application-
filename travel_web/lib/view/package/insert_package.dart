// ignore_for_file: prefer_const_constructors_in_immutables

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TextInputFormatter를 위해 추가
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class InsertPackage extends StatefulWidget {
  InsertPackage({super.key});

  @override
  State<InsertPackage> createState() => _InsertPackageState();
}

class _InsertPackageState extends State<InsertPackage> {
  // --- Dashboard와 동일한 색상 팔레트 추가 ---
  final Color primaryColor = Color(0xFF2C5AA0);      // 진한 파란색
  final Color secondaryColor = Color(0xFF5B8A2A);    // 진한 초록색
  final Color tertiaryColor = Color(0xFFE67E22);     // 진한 주황색
  final Color lightGray = Color(0xFFF8F9FA);         // 밝은 배경
  final Color mediumGray = Color(0xFFDEE2E6);        // 진한 경계선
  final Color darkText = Color(0xFF2C3E50);          // 진한 텍스트

  // --- 입력 필드 컨트롤러들 (기존 Firebase 필드명 유지) ---
  TextEditingController packageName = TextEditingController();    // 패키지명 (pName)
  TextEditingController agencyName = TextEditingController();     // 여행사명 (tName)
  TextEditingController airlineName = TextEditingController();    // 항공사명 (airlineName)
  TextEditingController airlineCode = TextEditingController();    // 항공편번호 (aId) - 기존 필드명 유지
  TextEditingController packagePrice = TextEditingController();   // 패키지 가격 (pPrice)
  TextEditingController bookingNumber = TextEditingController();  // 예매번호 (pNum)
  TextEditingController packagePlan = TextEditingController();    // 패키지 설명 (pPlan)
  TextEditingController groupCount = TextEditingController();     // 최대 인원수 (pCount)
  TextEditingController startDate = TextEditingController();      // 출발일 (pStart)
  TextEditingController endDate = TextEditingController();        // 도착일 (pEnd)

  // --- 항공사 검색 관련 변수들 ---
  final List<String> allAirlines = [
    '에티하드 항공', '일본항공', '중화항공', '유나이티드항공', '아시아나항공', 
    '에어캐나다', '에티오피아항공', '진에어', '웨스트젯', '말레이시아 항공', 
    '타이항공', '델타항공', '전일본공수', '대한항공', '싱가포르항공', '샤먼항공'
  ];
  
  // --- 항공사별 코드 매핑 테이블 ---
  final Map<String, String> airlineCodeMap = {
    '대한항공': 'KE-',
    '아시아나항공': 'OZ-',
    '진에어': 'LJ-',
    '일본항공': 'JL-',
    '전일본공수': 'NH-',
    '싱가포르항공': 'SQ-',
    '타이항공': 'TG-',
    '말레이시아 항공': 'MH-',
    '중화항공': 'CI-',
    '델타항공': 'DL-',
    '유나이티드항공': 'UA-',
    '에어캐나다': 'AC-',
    '웨스트젯': 'WS-',
    '에티하드 항공': 'EY-',
    '에티오피아항공': 'ET-',
    '샤먼항공': 'MF-',
  };
  
  List<String> filteredAirlines = [];              // 검색 결과 항공사 목록
  bool showAirlineDropdown = false;                // 드롭다운 표시 여부
  final FocusNode airlineFocusNode = FocusNode();  // 포커스 관리용
  
  // --- 드롭다운 오버레이 관련 변수들 ---
  OverlayEntry? _overlayEntry;                     // 오버레이 엔트리
  final LayerLink _layerLink = LayerLink();        // 위치 연결용

  // --- 이미지 업로드 관련 변수들 ---
  List<XFile> selectedImages = [];              // 선택된 이미지 목록
  final ImagePicker picker = ImagePicker();     // 이미지 선택기
  final int minImages = 4;                      // 최소 이미지 개수
  final int maxImages = 4;                      // 최대 이미지 개수

  // --- 패키지 상태 관련 변수들 ---
  String currentStatus = '모집중';                      // 현재 선택된 상태
  final List<String> statusOptions = ['모집중', '모집마감']; // 상태 옵션 목록
  bool isUploading = false;                            // 업로드 진행 상태

  @override
  void initState() {
    super.initState();
    // --- 항공사명 텍스트 변경 감지 리스너 추가 ---
    airlineName.addListener(onAirlineTextChanged);
    // --- 포커스 변경 감지 리스너 추가 ---
    airlineFocusNode.addListener(onAirlineFocusChanged);
  }

  @override
  void dispose() {
    // --- 메모리 누수 방지를 위한 컨트롤러 및 리스너 해제 ---
    _hideOverlay(); // 오버레이 정리
    airlineName.removeListener(onAirlineTextChanged);
    airlineFocusNode.removeListener(onAirlineFocusChanged);
    
    packageName.dispose();
    agencyName.dispose();
    airlineName.dispose();
    airlineCode.dispose();
    packagePrice.dispose();
    bookingNumber.dispose();
    packagePlan.dispose();
    groupCount.dispose();
    startDate.dispose();
    endDate.dispose();
    airlineFocusNode.dispose();
    super.dispose();
  }

  // --- 오버레이 드롭다운 생성 메서드 ---
  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width * 0.26,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, 56.0),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: filteredAirlines.length,
                itemBuilder: (context, index) {
                  final airline = filteredAirlines[index];
                  final airlinePrefix = airlineCodeMap[airline] ?? '';
                  return InkWell(
                    onTap: () => selectAirline(airline),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: index < filteredAirlines.length - 1 
                                ? Colors.grey[200]! 
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flight, color: primaryColor, size: 16),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              airline,
                              style: TextStyle(
                                fontSize: 14,
                                color: darkText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // --- 항공사 코드 미리보기 표시 ---
                          if (airlinePrefix.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: primaryColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                airlinePrefix,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
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
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }

  // --- 오버레이 숨기기 메서드 ---
  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // --- 항공사명 입력 변경 시 호출되는 메서드 ---
  void onAirlineTextChanged() {
    final query = airlineName.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        filteredAirlines = [];
        showAirlineDropdown = false;
      });
      _hideOverlay();
      return;
    }

    // --- 입력된 텍스트로 항공사 목록 필터링 ---
    setState(() {
      filteredAirlines = allAirlines
          .where((airline) => airline.toLowerCase().contains(query))
          .toList();
      showAirlineDropdown = filteredAirlines.isNotEmpty;
    });
    
    if (showAirlineDropdown && filteredAirlines.isNotEmpty) {
      _showOverlay(); // 오버레이로 드롭다운 표시
    } else {
      _hideOverlay();
    }
  }

  // --- 항공사명 필드 포커스 변경 시 호출되는 메서드 ---
  void onAirlineFocusChanged() {
    if (!airlineFocusNode.hasFocus) {
      // --- 포커스를 잃으면 드롭다운 숨김 (약간의 지연 후) ---
      Future.delayed(Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            showAirlineDropdown = false;
          });
          _hideOverlay();
        }
      });
    }
  }

  // --- 항공사 선택 시 호출되는 메서드 (코드 자동 입력 기능 추가) ---
  void selectAirline(String airline) {
    setState(() {
      airlineName.text = airline;
      showAirlineDropdown = false;
      
      // --- 선택된 항공사에 맞는 코드를 항공편 번호 필드에 자동 입력 ---
      if (airlineCodeMap.containsKey(airline)) {
        airlineCode.text = airlineCodeMap[airline]!;
        
        // --- 사용자에게 자동 입력을 알려주는 스낵바 표시 ---
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$airline 선택됨 - 항공편 번호에 "${airlineCodeMap[airline]}" 자동 입력'),
            backgroundColor: secondaryColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    });
    _hideOverlay(); // 오버레이 숨기기
    airlineFocusNode.unfocus(); // 포커스 해제
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            // --- 앱 로고 아이콘 ---
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text('AirTravel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 페이지 제목 및 설명 ---
              Text('새로운 여행 패키지 추가', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkText)),
              SizedBox(height: 8),
              Text('새로운 여행 패키지를 생성하기 위해 아래 세부정보를 입력하세요.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              SizedBox(height: 40),
              
              // --- 메인 콘텐츠 영역 (좌: 입력 폼, 우: 이미지 업로드) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 왼쪽: 입력 폼 영역 ---
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.only(right: 40),
                      child: Column(
                        children: [
                          // --- 첫 번째 행: 패키지명, 여행사명 ---
                          Row(
                            children: [
                              Expanded(child: buildTextField(packageName, '패키지명', '예: 산토리니 여행')),
                              SizedBox(width: 20),
                              Expanded(child: buildTextField(agencyName, '여행사명', '예: 좋은여행사')),
                            ],
                          ),
                          SizedBox(height: 20),
                          
                          // --- 두 번째 행: 항공사명(검색), 항공편 번호(자동입력), 예매번호 ---
                          Row(
                            children: [
                              Expanded(child: buildAirlineSearchField()), // 검색 가능한 항공사명 필드
                              SizedBox(width: 20),
                              Expanded(child: buildAutoFilledAirlineCodeField()), // 자동 입력되는 항공편 번호 필드
                              SizedBox(width: 20),
                              Expanded(child: buildTextField(bookingNumber, '예매번호', '예: PKG-98765')),
                            ],
                          ),
                          SizedBox(height: 20),
                          
                          // --- 세 번째 행: 패키지 설명 (여러 줄 입력) ---
                          buildTextField(packagePlan, '패키지 설명', '여행 패키지를 자세히 설명해주세요...', maxLines: 5),
                          SizedBox(height: 20),
                          
                          // --- 네 번째 행: 가격, 최대 인원 (콤마 포맷팅이 적용된 숫자 입력 필드) ---
                          Row(
                            children: [
                              Expanded(child: buildFormattedNumberField(packagePrice, '가격 (원)', '예: 2,500,000', isPrice: true)),
                              SizedBox(width: 20),
                              Expanded(child: buildFormattedNumberField(groupCount, '최대 인원', '예: 50', isPrice: false)),
                            ],
                          ),
                          SizedBox(height: 20),
                          
                          // --- 다섯 번째 행: 출발일, 도착일 (날짜 포맷팅 적용) ---
                          Row(
                            children: [
                              Expanded(child: buildFormattedDateField(startDate, '출발일', '예: 2025.09.10.')),
                              SizedBox(width: 20),
                              Expanded(child: buildFormattedDateField(endDate, '도착일', '예: 2025.09.15.')),
                            ],
                          ),
                          SizedBox(height: 20),
                          
                          // --- 여섯 번째 행: 패키지 상태 드롭다운 ---
                          buildStatusDropdown(),
                        ],
                      ),
                    ),
                  ),
                  
                  // --- 오른쪽: 이미지 업로드 영역 ---
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('패키지 이미지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
                          SizedBox(height: 24),
                          buildImageUploadButton(),    // 이미지 업로드 버튼
                          SizedBox(height: 20),
                          buildImageGrid(),            // 선택된 이미지 그리드
                          SizedBox(height: 16),
                          Text('최소 ${minImages}장 이미지 업로드', style: TextStyle(fontSize: 12, color: primaryColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              
              // --- 하단: 등록 버튼 ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading ? null : insertAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('등록 중...'),
                          ],
                        )
                      : Text('여행 패키지 등록하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 검색 가능한 항공사명 입력 필드 생성 메서드 (오버레이 방식) ---
  Widget buildAirlineSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('항공사명', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkText)),
        SizedBox(height: 8),
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: airlineName,
            focusNode: airlineFocusNode,
            decoration: InputDecoration(
              hintText: '예: 대한항공 (검색하여 선택)',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), 
                borderSide: BorderSide(color: Colors.grey[300]!)
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), 
                borderSide: BorderSide(color: primaryColor, width: 2)
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              fillColor: Colors.white,
              filled: true,
              suffixIcon: airlineName.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        setState(() {
                          airlineName.clear();
                          airlineCode.clear(); // 항공사 지울 때 항공편 번호도 초기화
                          showAirlineDropdown = false;
                        });
                        _hideOverlay(); // 오버레이 숨기기
                      },
                    )
                  : Icon(Icons.search, color: Colors.grey[400]),
            ),
            onChanged: (value) {
              // onAirlineTextChanged 리스너에서 자동으로 처리됨
            },
          ),
        ),
      ],
    );
  }

  // --- 자동 입력되는 항공편 번호 필드 생성 메서드 ---
  Widget buildAutoFilledAirlineCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('항공편 번호', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkText)),
            SizedBox(width: 4),
            // --- 자동 입력 안내 아이콘 ---
            Tooltip(
              message: '항공사 선택 시 자동으로 입력됩니다',
              child: Icon(Icons.auto_awesome, color: primaryColor, size: 16),
            ),
          ],
        ),
        SizedBox(height: 8),
        TextField(
          controller: airlineCode,
          decoration: InputDecoration(
            hintText: '예: KE-1234 (자동 입력)',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), 
              borderSide: BorderSide(color: Colors.grey[300]!)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), 
              borderSide: BorderSide(color: primaryColor, width: 2)
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
            // --- 자동 입력된 코드가 있을 때 배경색 변경으로 시각적 피드백 ---
            prefixIcon: airlineCode.text.isNotEmpty && airlineCode.text.contains('-')
                ? Icon(Icons.check_circle, color: secondaryColor, size: 20)
                : Icon(Icons.flight, color: Colors.grey[400], size: 20),
          ),
          onChanged: (value) {
            setState(() {}); // 입력 변경 시 UI 업데이트
          },
        ),
      ],
    );
  }

  // --- 일반 텍스트 입력 필드 생성 메서드 ---
  Widget buildTextField(TextEditingController controller, String label, String placeholder, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkText)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  // --- 실시간 콤마 포맷팅이 적용된 숫자 입력 필드 생성 메서드 ---
  Widget buildFormattedNumberField(TextEditingController controller, String label, String placeholder, {required bool isPrice}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkText)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          // --- 실시간 콤마 포맷팅을 위한 InputFormatter 추가 ---
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // 숫자만 입력 허용
            NumberFormatter(), // 커스텀 콤마 포맷터
          ],
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), 
              borderSide: BorderSide(color: Colors.grey[300]!)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), 
              borderSide: BorderSide(color: primaryColor, width: 2)
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
            // --- 가격과 인원에 맞는 아이콘 적용 ---
            prefixIcon: isPrice 
                ? Icon(Icons.attach_money, color: Colors.grey[400], size: 20)
                : Icon(Icons.group, color: Colors.grey[400], size: 20),
          ),
          onChanged: (value) {
            setState(() {}); // 입력 변경 시 UI 업데이트
          },
        ),
      ],
    );
  }

  // --- 실시간 날짜 포맷팅이 적용된 날짜 입력 필드 생성 메서드 ---
  Widget buildFormattedDateField(TextEditingController controller, String label, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkText)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          // --- 실시간 날짜 포맷팅을 위한 InputFormatter 추가 ---
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // 숫자만 입력 허용
            DateFormatter(), // 커스텀 날짜 포맷터
          ],
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), 
              borderSide: BorderSide(color: Colors.grey[300]!)
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), 
              borderSide: BorderSide(color: primaryColor, width: 2)
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
            // --- 날짜 아이콘과 유효성 검사 표시 ---
            prefixIcon: Icon(Icons.calendar_today, color: Colors.grey[400], size: 20),
            suffixIcon: _isValidDate(controller.text) 
                ? Icon(Icons.check_circle, color: secondaryColor, size: 20)
                : null,
          ),
          onChanged: (value) {
            setState(() {}); // 입력 변경 시 UI 업데이트
          },
        ),
      ],
    );
  }

  // --- 날짜 유효성 검사 헬퍼 메서드 ---
  bool _isValidDate(String dateString) {
    if (dateString.length != 11) return false; // "2025.09.10." 형식 체크
    if (!dateString.endsWith('.')) return false;
    
    try {
      // "2025.09.10." -> "2025-09-10" 변환
      String cleanDate = dateString.replaceAll('.', '');
      if (cleanDate.length != 8) return false;
      
      String year = cleanDate.substring(0, 4);
      String month = cleanDate.substring(4, 6);
      String day = cleanDate.substring(6, 8);
      
      DateTime date = DateTime.parse('$year-$month-$day');
      return date.year.toString() == year && 
             date.month.toString().padLeft(2, '0') == month &&
             date.day.toString().padLeft(2, '0') == day;
    } catch (e) {
      return false;
    }
  }

  // --- 상태 선택 드롭다운 생성 메서드 ---
  Widget buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('패키지 상태', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkText)),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8), color: Colors.white),
          child: DropdownButton<String>(
            value: currentStatus,
            isExpanded: true,
            underline: Container(),
            items: statusOptions.map((String status) {
              return DropdownMenuItem<String>(value: status, child: Text(status));
            }).toList(),
            onChanged: (String? newStatus) {
              if (newStatus != null) {
                setState(() {
                  currentStatus = newStatus;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  // --- 이미지 업로드 버튼 생성 메서드 ---
  Widget buildImageUploadButton() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: InkWell(
        onTap: isUploading ? null : () => getImageFromGallery(ImageSource.gallery),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 32, color: isUploading ? Colors.grey[400] : primaryColor),
            SizedBox(height: 8),
            Text('클릭하여 업로드', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isUploading ? Colors.grey[400] : darkText)),
          ],
        ),
      ),
    );
  }

  // --- 이미지 그리드 생성 메서드 ---
  Widget buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1),
      itemCount: maxImages,
      itemBuilder: (context, index) {
        if (index < selectedImages.length) {
          return buildImageItem(selectedImages[index], index);
        } else {
          return buildEmptyImageSlot();
        }
      },
    );
  }

  // --- 빈 이미지 슬롯 생성 메서드 ---
  Widget buildEmptyImageSlot() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
      child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 24),
    );
  }

  // --- 선택된 이미지 아이템 생성 메서드 ---
  Widget buildImageItem(XFile image, int index) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? FutureBuilder<List<int>>(
                    future: image.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(Uint8List.fromList(snapshot.data!), fit: BoxFit.cover);
                      }
                      return CircularProgressIndicator();
                    },
                  )
                : Image.file(File(image.path), fit: BoxFit.cover),
          ),
        ),
        // --- 이미지 삭제 버튼 ---
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: isUploading ? null : () => removeImage(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: Colors.grey[600], shape: BoxShape.circle),
              child: Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }

  // --- 갤러리에서 이미지 선택 메서드 ---
  getImageFromGallery(ImageSource imageSource) async {
    try {
      final List<XFile>? pickedImages = await picker.pickMultiImage();
      if (pickedImages != null) {
        setState(() {
          selectedImages.clear();
          selectedImages.addAll(pickedImages.take(maxImages));
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${selectedImages.length}개 이미지가 선택되었습니다.'), backgroundColor: secondaryColor));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다.'), backgroundColor: Colors.red[600]));
    }
  }

  // --- 이미지 제거 메서드 ---
  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  // --- 패키지 등록 실행 메서드 ---
  insertAction() async {
    // --- Firebase 인증 확인 ---
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (authError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firebase 인증 실패: 네트워크를 확인해주세요.'), backgroundColor: Colors.red[600]));
      return;
    }

    // --- 필수 필드 검증 ---
    if (packageName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('패키지명을 입력해주세요.'), backgroundColor: Colors.red[600]));
      return;
    }

    if (selectedImages.length < minImages) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('최소 ${minImages}개 이미지를 선택해주세요.'), backgroundColor: Colors.red[600]));
      return;
    }

    // --- 업로드 상태 시작 ---
    setState(() {
      isUploading = true;
    });

    try {
      // --- 이미지 업로드 실행 ---
      List<String> imageUrls = await uploadImages();

      // --- 콤마가 포함된 가격과 인원수를 숫자로 변환 ---
      String cleanPrice = packagePrice.text.replaceAll(',', '');
      String cleanCount = groupCount.text.replaceAll(',', '');

      // --- 기존 Firebase 필드명 유지하여 Firestore에 패키지 데이터 저장 ---
      DocumentReference docRef = await FirebaseFirestore.instance.collection('package').add({
        "pName": packageName.text.trim(),              // 패키지명
        "tName": agencyName.text.trim(),               // 여행사명  
        "airlineName": airlineName.text.trim(),        // 항공사명
        "aId": airlineCode.text.trim(),                // 항공편번호 (기존 필드명 유지)
        "pPrice": cleanPrice,                          // 콤마 제거된 순수 숫자
        "pNum": bookingNumber.text.trim(),             // 예매번호
        "pPlan": packagePlan.text.trim(),              // 패키지 설명
        "pCount": cleanCount,                          // 콤마 제거된 순수 숫자
        "pStart": startDate.text.trim(),               // 출발일
        "pEnd": endDate.text.trim(),                   // 도착일
        "pDate": DateTime.now().toString().substring(0, 19), // 등록 일시
        "pState": currentStatus,                       // 패키지 상태
        "images": imageUrls,                           // 이미지 URL 목록
      });

      // --- 업로드 상태 종료 ---
      setState(() {
        isUploading = false;
      });

      showSuccessDialog();
    } catch (e) {
      // --- 오류 발생 시 상태 초기화 ---
      setState(() {
        isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('등록 중 오류가 발생했습니다.'), backgroundColor: Colors.red[600]));
    }
  }

  // --- 이미지 Firebase Storage 업로드 메서드 ---
  Future<List<String>> uploadImages() async {
    List<String> imageUrls = [];

    for (int i = 0; i < selectedImages.length; i++) {
      try {
        final bytes = await selectedImages[i].readAsBytes();
        if (bytes.isEmpty) continue;

        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String fileName = "travel_image_${i}_$timestamp.jpg";

        final storageRef = FirebaseStorage.instance.ref().child('images').child(fileName);

        await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        String downloadUrl = await storageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (e) {
        continue;
      }
    }

    if (imageUrls.isEmpty) {
      throw Exception('모든 이미지 업로드에 실패했습니다.');
    }

    return imageUrls;
  }

  // --- 성공 다이얼로그 표시 메서드 ---
  showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("등록 완료"),
        content: Text('여행 패키지가 성공적으로 등록되었습니다!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('확인', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
          ),
        ],
      ),
    );
  }
}

// --- 실시간 콤마 포맷팅을 위한 커스텀 TextInputFormatter 클래스 ---
class NumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // --- 입력된 텍스트가 비어있으면 그대로 반환 ---
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // --- 숫자만 추출 ---
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // --- 숫자를 콤마 포맷으로 변환 ---
    String formatted = _addCommas(digitsOnly);
    
    // --- 커서 위치 계산 (콤마 추가로 인한 위치 조정) ---
    int cursorPosition = formatted.length;
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
  
  // --- 천 단위마다 콤마 추가하는 헬퍼 메서드 ---
  String _addCommas(String value) {
    if (value.isEmpty) return '';
    
    // --- 정수 파트에 콤마 추가 ---
    return value.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }
}

// --- 실시간 날짜 포맷팅을 위한 커스텀 TextInputFormatter 클래스 ---
class DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // --- 입력된 텍스트가 비어있으면 그대로 반환 ---
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // --- 숫자만 추출 (최대 8자리) ---
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }
    
    // --- 날짜 포맷팅: "20250910" -> "2025.09.10." ---
    String formatted = _formatDate(digitsOnly);
    
    // --- 커서 위치를 맨 끝으로 설정 ---
    int cursorPosition = formatted.length;
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
  
  // --- 날짜 포맷팅 헬퍼 메서드 ---
  String _formatDate(String digits) {
    if (digits.isEmpty) return '';
    
    // --- 연도 (최대 4자리) ---
    if (digits.length <= 4) {
      return digits;
    }
    
    String year = digits.substring(0, 4);
    
    // --- 월 (2자리) ---
    if (digits.length <= 6) {
      String month = digits.substring(4);
      return '$year.$month';
    }
    
    String month = digits.substring(4, 6);
    
    // --- 일 (2자리) ---
    String day = digits.substring(6);
    String result = '$year.$month.$day';
    
    // --- 8자리가 모두 입력되면 마지막에 점 추가 ---
    if (digits.length == 8) {
      result += '.';
    }
    
    return result;
  }
}
