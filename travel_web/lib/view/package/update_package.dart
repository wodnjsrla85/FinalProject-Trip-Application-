// ignore_for_file: use_build_context_synchronously, deprecated_member_use, empty_catches

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TextInputFormatter를 위해 추가
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class UpdatePackage extends StatefulWidget {
  final DocumentSnapshot packageDoc;
  const UpdatePackage({super.key, required this.packageDoc});

  @override
  State<UpdatePackage> createState() => _UpdatePackageState();
}

class _UpdatePackageState extends State<UpdatePackage> {
  // --- Dashboard와 동일한 색상 팔레트 추가 ---
  final Color primaryColor = Color(0xFF2C5AA0);      // 진한 파란색
  final Color secondaryColor = Color(0xFF5B8A2A);    // 진한 초록색
  final Color tertiaryColor = Color(0xFFE67E22);     // 진한 주황색
  final Color lightGray = Color(0xFFF8F9FA);         // 밝은 배경
  final Color mediumGray = Color(0xFFDEE2E6);        // 진한 경계선
  final Color darkText = Color(0xFF2C3E50);          // 진한 텍스트

  // --- 입력 필드 컨트롤러들 (기존 Firebase 필드명 유지) ---
  late TextEditingController packageName;      // 패키지명 (pName)
  late TextEditingController agencyName;       // 여행사명 (tName)
  late TextEditingController airlineName;      // 항공사명 (airlineName)
  late TextEditingController airlineCode;      // 항공편번호 (aId) - 기존 필드명 유지
  late TextEditingController packagePrice;     // 패키지 가격 (pPrice)
  late TextEditingController bookingNumber;    // 예매번호 (pNum)
  late TextEditingController packagePlan;      // 패키지 설명 (pPlan)
  late TextEditingController groupCount;       // 최대 인원수 (pCount)
  late TextEditingController startDate;        // 출발일 (pStart)
  late TextEditingController endDate;          // 도착일 (pEnd)

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
    '에티오피아항공': 'ET-',
    '샤먼항공': 'MF-',
    '에티하드 항공': 'EY-',
  };

  List<String> filteredAirlines = [];              // 검색 결과 항공사 목록
  bool showAirlineDropdown = false;                // 드롭다운 표시 여부
  final FocusNode airlineFocusNode = FocusNode();  // 포커스 관리용
  
  // --- 드롭다운 오버레이 관련 변수들 ---
  OverlayEntry? _overlayEntry;                     // 오버레이 엔트리
  final LayerLink _layerLink = LayerLink();        // 위치 연결용

  // --- 이미지 관련 변수들 ---
  final ImagePicker picker = ImagePicker();
  final int minCount = 4;                    // 최소 이미지 개수
  final int maxCount = 4;                    // 최대 이미지 개수

  List<String> savedImageUrls = [];          // 기존 저장된 이미지 URL
  List<XFile> newImages = [];                // 새로 선택된 이미지

  // --- 패키지 상태 관련 변수들 ---
  late String status;                                  // 현재 패키지 상태
  final List<String> statusOptions = ['모집중', '모집마감']; // 상태 옵션 목록

  bool isUploading = false;                   // 업로드 진행 상태

  @override
  void initState() {
    super.initState();
    
    // --- 기존 패키지 데이터를 컨트롤러에 로드 ---
    final data = widget.packageDoc.data() as Map<String, dynamic>;
    packageName = TextEditingController(text: data['pName'] ?? '');
    agencyName = TextEditingController(text: data['tName'] ?? '');
    airlineName = TextEditingController(text: data['airlineName'] ?? '');  // 항공사명 필드
    airlineCode = TextEditingController(text: data['aId'] ?? '');          // 기존 aId 필드 사용
    
    // --- 가격과 인원수 포맷팅 적용 ---
    String priceText = data['pPrice'] ?? '';
    if (priceText.isNotEmpty) {
      packagePrice = TextEditingController(text: _formatNumberWithCommas(priceText));
    } else {
      packagePrice = TextEditingController();
    }
    
    String countText = data['pCount'] ?? '';
    if (countText.isNotEmpty) {
      groupCount = TextEditingController(text: _formatNumberWithCommas(countText));
    } else {
      groupCount = TextEditingController();
    }

    bookingNumber = TextEditingController(text: data['pNum'] ?? '');
    packagePlan = TextEditingController(text: data['pPlan'] ?? '');
    startDate = TextEditingController(text: data['pStart'] ?? '');
    endDate = TextEditingController(text: data['pEnd'] ?? '');
    savedImageUrls = List<String>.from(data['images'] ?? []);
    status = data['pState'] ?? statusOptions.first;

    // --- 항공사명 텍스트 변경 감지 리스너 추가 ---
    airlineName.addListener(onAirlineTextChanged);
    // --- 포커스 변경 감지 리스너 추가 ---
    airlineFocusNode.addListener(onAirlineFocusChanged);
  }

  // --- 기존 숫자를 콤마 포맷으로 변환하는 헬퍼 메서드 ---
  String _formatNumberWithCommas(String number) {
    if (number.isEmpty) return '';
    try {
      int value = int.parse(number.replaceAll(',', ''));
      return value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match match) => '${match[1]},',
      );
    } catch (e) {
      return number;
    }
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

  // --- 항공사 선택 시 호출되는 메서드 ---
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
              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(6)),
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
              Text('여행 패키지 수정', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkText)),
              SizedBox(height: 8),
              Text('패키지 정보를 수정하고 저장하세요. 새 이미지 선택 시 기존 이미지가 완전히 교체됩니다.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
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
                          
                          // --- 세 번째 행: 패키지 설명 ---
                          buildTextField(packagePlan, '패키지 설명', '여행 패키지를 자세히 설명해주세요...', maxLines: 5),
                          SizedBox(height: 20),
                          
                          // --- 네 번째 행: 가격, 최대 인원 (포맷팅 적용) ---
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
                          Row(children: [SizedBox(width: 20), Expanded(child: buildDropdown())]),
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
                          imageUploadBtn(),        // 이미지 업로드 버튼
                          SizedBox(height: 20),
                          imageGrid(),             // 이미지 그리드
                          SizedBox(height: 16),
                          Text('최소 $minCount장 이미지 필요', style: TextStyle(fontSize: 12, color: primaryColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              
              // --- 하단: 수정 버튼 ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading ? null : updateAction,
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
                            Text('수정 중...'),
                          ],
                        )
                      : Text('여행 패키지 수정하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 검색 가능한 항공사명 입력 필드 생성 메서드 ---
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
                          airlineCode.clear();
                          showAirlineDropdown = false;
                        });
                        _hideOverlay();
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
  Widget buildTextField(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkText)),
        SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
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

  // --- 상태 선택 드롭다운 생성 메서드 ---
  Widget buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('패키지 상태', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkText)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
          child: DropdownButton<String>(
            value: status,
            underline: Container(),
            isExpanded: true,
            items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => status = v ?? status),
          ),
        ),
      ],
    );
  }

  // --- 이미지 업로드 버튼 생성 메서드 ---
  Widget imageUploadBtn() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: newImages.isNotEmpty ? tertiaryColor.withOpacity(0.7) : Colors.grey[300]!, width: newImages.isNotEmpty ? 2 : 1),
        color: Colors.white,
      ),
      child: InkWell(
        onTap: isUploading ? null : pickImages,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              newImages.isNotEmpty ? Icons.swap_horiz : Icons.cloud_upload_outlined,
              size: 32,
              color: isUploading ? Colors.grey[400] : (newImages.isNotEmpty ? tertiaryColor : primaryColor),
            ),
            SizedBox(height: 8),
            Text(
              newImages.isNotEmpty ? '새 이미지 ${newImages.length}개 선택됨' : '클릭하여 새 이미지 업로드',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isUploading ? Colors.grey[400] : darkText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- 이미지 그리드 생성 메서드 ---
  Widget imageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1),
      itemCount: maxCount,
      itemBuilder: (_, i) {
        if (newImages.isNotEmpty) {
          if (i < newImages.length) {
            return buildNewImage(newImages[i], i);
          } else {
            return emptySlot();
          }
        } else {
          if (i < savedImageUrls.length) {
            return buildSavedImage(savedImageUrls[i], i);
          } else {
            return emptySlot();
          }
        }
      },
    );
  }

  // --- 기존 저장된 이미지 표시 위젯 ---
  Widget buildSavedImage(String url, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (c, child, loading) => loading == null ? child : Container(color: primaryColor.withOpacity(0.1), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))),
              errorBuilder: (_, __, ___) => Container(
                color: tertiaryColor.withOpacity(0.2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.wifi_off, color: tertiaryColor, size: 20), Text('CORS\n오류', style: TextStyle(fontSize: 8, color: tertiaryColor), textAlign: TextAlign.center)],
                ),
              ),
            ),
          ),
        ),
        Positioned(top: 6, right: 6, child: GestureDetector(onTap: isUploading ? null : () => setState(() => savedImageUrls.removeAt(index)), child: closeBtn())),
      ],
    );
  }

  // --- 새로 선택된 이미지 표시 위젯 ---
  Widget buildNewImage(XFile image, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200], border: Border.all(color: tertiaryColor, width: 2)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? FutureBuilder<List<int>>(
                    future: image.readAsBytes(),
                    builder: (_, snap) => snap.hasData ? Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover, width: double.infinity, height: double.infinity) : Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor)),
                  )
                : Image.file(File(image.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          ),
        ),
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(color: tertiaryColor, borderRadius: BorderRadius.circular(6)),
            child: Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ),
        Positioned(top: 6, right: 6, child: GestureDetector(onTap: isUploading ? null : () => setState(() => newImages.removeAt(index)), child: closeBtn())),
      ],
    );
  }

  // --- 빈 이미지 슬롯 위젯 ---
  Widget emptySlot() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
      child: Icon(Icons.image_outlined, color: Colors.grey, size: 24),
    );
  }

  // --- 이미지 삭제 버튼 위젯 ---
  Widget closeBtn() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: Colors.grey[600], shape: BoxShape.circle),
      child: Icon(Icons.close, color: Colors.white, size: 12),
    );
  }

  // --- 이미지 선택 메서드 ---
  Future<void> pickImages() async {
    try {
      final picked = await picker.pickMultiImage();
      setState(() {
        newImages.clear();
        newImages.addAll(picked.take(maxCount));
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${newImages.length}개 새 이미지 선택됨'), backgroundColor: tertiaryColor));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 선택 오류'), backgroundColor: Colors.red[600]));
    }
  }

  // --- 패키지 수정 실행 메서드 ---
  Future<void> updateAction() async {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('패키지명을 입력하세요'), backgroundColor: Colors.red));
      return;
    }

    int totalImageCount = newImages.isNotEmpty ? newImages.length : savedImageUrls.length;
    if (totalImageCount < minCount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('최소 $minCount장 이미지가 필요합니다'), backgroundColor: Colors.red));
      return;
    }

    setState(() => isUploading = true);

    try {
      List<String> finalImageUrls = [];

      if (newImages.isNotEmpty) {
        await deleteOldImages();
        finalImageUrls = await uploadNewImages();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지가 성공적으로 교체되었습니다'), backgroundColor: secondaryColor));
      } else {
        finalImageUrls = savedImageUrls;
      }

      // --- 콤마가 포함된 가격과 인원수를 숫자로 변환 ---
      String cleanPrice = packagePrice.text.replaceAll(',', '');
      String cleanCount = groupCount.text.replaceAll(',', '');

      // --- 기존 Firebase 필드명 유지하여 Firestore 데이터 업데이트 ---
      await widget.packageDoc.reference.update({
        'pName': packageName.text.trim(),              // 패키지명
        'tName': agencyName.text.trim(),               // 여행사명
        'airlineName': airlineName.text.trim(),        // 항공사명
        'aId': airlineCode.text.trim(),                // 항공편번호 (기존 필드명 유지)
        'pPrice': cleanPrice,                          // 콤마 제거된 순수 숫자
        'pNum': bookingNumber.text.trim(),             // 예매번호
        'pPlan': packagePlan.text.trim(),              // 패키지 설명
        'pCount': cleanCount,                          // 콤마 제거된 순수 숫자
        'pStart': startDate.text.trim(),               // 출발일
        'pEnd': endDate.text.trim(),                   // 도착일
        'pState': status,                              // 패키지 상태
        'images': finalImageUrls,                      // 이미지 URL 목록
      });

      setState(() => isUploading = false);

      // --- 성공 다이얼로그 표시 ---
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(
            children: [Icon(Icons.check_circle, color: secondaryColor), SizedBox(width: 8), Text('수정 완료')],
          ),
          content: Text(newImages.isNotEmpty ? '패키지 수정 및 이미지 교체가 완료되었습니다.' : '패키지 정보가 수정되었습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('확인', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 중 오류가 발생했습니다'), backgroundColor: Colors.red));
    }
  }

  // --- 기존 이미지 삭제 메서드 ---
  Future<void> deleteOldImages() async {
    for (String url in savedImageUrls) {
      try {
        if (url.startsWith('https://firebasestorage')) {
          final ref = FirebaseStorage.instance.refFromURL(url);
          await ref.delete();
        }
      } catch (e) {}
    }
  }

  // --- 새 이미지 업로드 메서드 ---
  Future<List<String>> uploadNewImages() async {
    List<String> newUrls = [];
    String packageNameSafe = packageName.text.trim().replaceAll(' ', '_');
    if (packageNameSafe.isEmpty) packageNameSafe = 'updated_package';

    for (int i = 0; i < newImages.length; i++) {
      try {
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String fileName = "${packageNameSafe}_new_${i}_$timestamp.jpg";

        final ref = FirebaseStorage.instance.ref().child('images').child(fileName);

        if (kIsWeb) {
          final bytes = await newImages[i].readAsBytes();
          await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        } else {
          await ref.putFile(File(newImages[i].path));
        }

        String downloadUrl = await ref.getDownloadURL();
        newUrls.add(downloadUrl);
      } catch (e) {
        continue;
      }
    }

    if (newUrls.isEmpty && newImages.isNotEmpty) {
      throw Exception('모든 새 이미지 업로드에 실패했습니다.');
    }

    return newUrls;
  }
}

// --- 실시간 콤마 포맷팅을 위한 커스텀 TextInputFormatter 클래스 ---
class NumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = _addCommas(digitsOnly);
    int cursorPosition = formatted.length;
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
  
  String _addCommas(String value) {
    if (value.isEmpty) return '';
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
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }
    
    String formatted = _formatDate(digitsOnly);
    int cursorPosition = formatted.length;
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
  
  String _formatDate(String digits) {
    if (digits.isEmpty) return '';
    
    if (digits.length <= 4) {
      return digits;
    }
    
    String year = digits.substring(0, 4);
    
    if (digits.length <= 6) {
      String month = digits.substring(4);
      return '$year.$month';
    }
    
    String month = digits.substring(4, 6);
    String day = digits.substring(6);
    String result = '$year.$month.$day';
    
    if (digits.length == 8) {
      result += '.';
    }
    
    return result;
  }
}
