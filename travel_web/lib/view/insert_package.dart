import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// 새로운 여행 패키지를 등록하는 페이지입니다
class InsertPackage extends StatefulWidget {
  InsertPackage({super.key});

  @override
  State<InsertPackage> createState() => _InsertPackageState();
}

class _InsertPackageState extends State<InsertPackage> {
  // ✨ 1단계: 입력 필드를 위한 컨트롤러들 선언
  // 컨트롤러는 TextField의 내용을 관리하는 도구입니다
  TextEditingController packageNameInput = TextEditingController();
  TextEditingController agencyNameInput = TextEditingController();
  TextEditingController airlineCodeInput = TextEditingController();
  TextEditingController packagePriceInput = TextEditingController();
  TextEditingController bookingNumberInput = TextEditingController();
  TextEditingController packagePlanInput = TextEditingController();
  TextEditingController groupCountInput = TextEditingController();
  TextEditingController startDateInput = TextEditingController();
  TextEditingController endDateInput = TextEditingController();

  // ✨ 2단계: 이미지 관리를 위한 변수들 선언
  List<XFile> selectedImages = []; // 선택된 이미지들을 저장하는 리스트
  final ImagePicker picker = ImagePicker(); // 이미지를 선택할 수 있는 도구
  final int minImages = 4; // 최소 업로드해야 할 이미지 개수
  final int maxImages = 4; // 최대 업로드할 수 있는 이미지 개수

  // ✨ 3단계: 앱 상태를 관리하는 변수들
  String currentStatus = '모집중'; // 현재 선택된 패키지 상태
  final List<String> statusOptions = ['모집중', '모집마감']; // 선택 가능한 상태 옵션들
  bool isUploading = false; // 현재 업로드 중인지 확인하는 변수

  // ✨ 4단계: 메모리 정리 함수 (페이지가 종료될 때 자동 실행)
  @override
  void dispose() {
    // 컨트롤러들을 메모리에서 해제합니다 (메모리 누수 방지)
    packageNameInput.dispose();
    agencyNameInput.dispose();
    airlineCodeInput.dispose();
    packagePriceInput.dispose();
    bookingNumberInput.dispose();
    packagePlanInput.dispose();
    groupCountInput.dispose();
    startDateInput.dispose();
    endDateInput.dispose();
    super.dispose();
  }

  // ✨ 5단계: 화면을 그리는 메인 함수
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 전체 배경색 설정
      
      // AppBar: 상단 제목 바 구성
      appBar: AppBar(
        title: Row(
          children: [
            // 로고 아이콘 컨테이너
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              'AirTravel',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0, // 그림자 제거
      ),

      // Body: 메인 컨텐츠 영역
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView( // 스크롤 가능한 컨테이너
          padding: EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 페이지 제목 섹션
              Text(
                '새로운 여행 패키지 추가',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '새로운 여행 패키지를 생성하기 위해 아래 세부정보를 입력하세요.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 40),

              // 메인 입력 영역 (좌우 분할 레이아웃)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽: 입력 필드들 (2/3 공간 차지)
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.only(right: 40),
                      child: Column(
                        children: [
                          // 첫 번째 줄: 패키지명과 여행사명
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  packageNameInput,
                                  '패키지명',
                                  '예: 산토리니 여름 휴가',
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: _buildTextField(
                                  agencyNameInput,
                                  '여행사명',
                                  '예: 글로브트로터스 주식회사',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // 두 번째 줄: 항공편 번호와 예매번호
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  airlineCodeInput,
                                  '항공편 번호',
                                  '예: GT-1234',
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: _buildTextField(
                                  bookingNumberInput,
                                  '패키지 예매번호',
                                  '예: PKG-98765',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // 세 번째 줄: 패키지 설명 (여러 줄 텍스트)
                          _buildTextField(
                            packagePlanInput,
                            '패키지 플랜/설명',
                            '여행 패키지를 자세히 설명해주세요...',
                            maxLines: 5, // 5줄까지 입력 가능
                          ),
                          SizedBox(height: 20),

                          // 네 번째 줄: 가격과 인원 (숫자 입력 필드)
                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberField(
                                  packagePriceInput,
                                  '가격 (원)',
                                  '예: 2,500,000',
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: _buildNumberField(
                                  groupCountInput,
                                  '최대 인원',
                                  '예: 50',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // 다섯 번째 줄: 출발일과 도착일
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  startDateInput,
                                  '출발일',
                                  '2025.09.10.',
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: _buildTextField(
                                  endDateInput,
                                  '도착일',
                                  '2025.09.10.',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // 여섯 번째 줄: 패키지 상태 드롭다운
                          Row(
                            children: [
                              SizedBox(width: 20),
                              Expanded(child: _buildStatusDropdown()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 오른쪽: 이미지 업로드 영역 (1/3 공간 차지)
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
                          Text(
                            '패키지 이미지',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 24),

                          _buildImageUploadButton(), // 이미지 업로드 버튼
                          SizedBox(height: 20),
                          _buildImageGrid(), // 선택된 이미지들을 보여주는 그리드
                          SizedBox(height: 16),

                          Text(
                            '최소 ${minImages}장 이미지 업로드',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 40),

              // 등록 버튼 (전체 너비)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading ? null : insertAction, // 업로드 중이면 버튼 비활성화
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isUploading
                      ? Row( // 업로드 중일 때 로딩 표시
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('업로드 중...'),
                          ],
                        )
                      : Text( // 일반 상태일 때
                          '여행 패키지 등록하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ 6단계: 재사용 가능한 UI 위젯들 만들기

  // 일반 텍스트 입력 필드를 만드는 함수
  Widget _buildTextField(
    TextEditingController controller, // 입력 내용을 관리하는 컨트롤러
    String label, // 필드 라벨 (예: '패키지명')
    String placeholder, // 힌트 텍스트 (예: '예: 산토리니 여름 휴가')
    {int maxLines = 1} // 최대 줄 수 (기본값: 1줄)
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 필드 라벨
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        // 실제 입력 필드
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder( // 포커스될 때의 테두리
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true, // 배경색 채우기
          ),
        ),
      ],
    );
  }

  // 숫자 입력 필드를 만드는 함수 (증가/감소 버튼 포함)
  Widget _buildNumberField(
    TextEditingController controller,
    String label,
    String placeholder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number, // 숫자 키보드 표시
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
            // 오른쪽에 증가/감소 버튼 추가
            suffixIcon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _incrementValue(controller), // 값 증가
                  child: Icon(Icons.keyboard_arrow_up, size: 16),
                ),
                GestureDetector(
                  onTap: () => _decrementValue(controller), // 값 감소
                  child: Icon(Icons.keyboard_arrow_down, size: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 드롭다운 선택 필드를 만드는 함수
  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '패키지 상태',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: currentStatus, // 현재 선택된 값
            isExpanded: true, // 전체 너비 사용
            underline: Container(), // 기본 밑줄 제거
            items: statusOptions.map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (String? newStatus) {
              if (newStatus != null) {
                setState(() { // 상태 변경 시 화면 업데이트
                  currentStatus = newStatus;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  // 이미지 업로드 버튼을 만드는 함수
  Widget _buildImageUploadButton() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle.solid,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: InkWell( // 클릭 가능한 위젯
        onTap: isUploading ? null : () => getImageFromGallery(ImageSource.gallery),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 32,
              color: isUploading ? Colors.grey[400] : Colors.blue[600],
            ),
            SizedBox(height: 8),
            Text(
              '클릭하여 업로드',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isUploading ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 선택된 이미지들을 보여주는 그리드를 만드는 함수
  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true, // 필요한 공간만 차지
      physics: NeverScrollableScrollPhysics(), // 스크롤 비활성화
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 한 줄에 2개씩 배치
        crossAxisSpacing: 12, // 가로 간격
        mainAxisSpacing: 12, // 세로 간격
        childAspectRatio: 1, // 정사각형 비율
      ),
      itemCount: maxImages, // 최대 4개 슬롯
      itemBuilder: (context, index) {
        if (index < selectedImages.length) {
          // 이미지가 있는 경우: 이미지 표시
          return _buildImageItem(selectedImages[index], index);
        } else {
          // 이미지가 없는 경우: 빈 슬롯 표시
          return _buildEmptyImageSlot();
        }
      },
    );
  }

  // 빈 이미지 슬롯을 만드는 함수
  Widget _buildEmptyImageSlot() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 24),
    );
  }

  // 선택된 이미지를 표시하는 위젯을 만드는 함수
  Widget _buildImageItem(XFile image, int index) {
    return Stack( // 겹치는 레이아웃 (이미지 위에 삭제 버튼)
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: ClipRRect( // 모서리 둥글게 자르기
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb // 웹 환경과 모바일 환경 구분
                ? FutureBuilder<List<int>>( // 웹: 비동기로 이미지 로드
                    future: image.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(
                          Uint8List.fromList(snapshot.data!),
                          fit: BoxFit.cover, // 컨테이너에 맞게 크기 조정
                        );
                      }
                      return CircularProgressIndicator(); // 로딩 중 표시
                    },
                  )
                : Image.file(File(image.path), fit: BoxFit.cover), // 모바일: 파일 경로로 이미지 로드
          ),
        ),
        // 삭제 버튼 (오른쪽 위 모서리)
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: isUploading ? null : () => _removeImage(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ✨ 7단계: 기능 함수들

  // 갤러리에서 이미지를 선택하는 함수
  getImageFromGallery(ImageSource imageSource) async {
    try {
      // pickMultiImage(): 여러 개의 이미지를 한 번에 선택할 수 있는 함수
      final List<XFile>? pickedImages = await picker.pickMultiImage();

      if (pickedImages != null) {
        setState(() {
          selectedImages.clear(); // 기존 이미지들 제거
          selectedImages.addAll(pickedImages.take(maxImages)); // 최대 4개만 추가
        });

        // 사용자에게 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedImages.length}개 이미지가 선택되었습니다.'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      // 오류 발생 시 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  // 이미지를 제거하는 함수
  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index); // 지정된 인덱스의 이미지 제거
    });
  }

  // 숫자 필드의 값을 1 증가시키는 함수
  void _incrementValue(TextEditingController controller) {
    int currentValue = int.tryParse(controller.text) ?? 0; // 현재 값을 정수로 변환 (실패시 0)
    controller.text = (currentValue + 1).toString();
  }

  // 숫자 필드의 값을 1 감소시키는 함수
  void _decrementValue(TextEditingController controller) {
    int currentValue = int.tryParse(controller.text) ?? 0;
    if (currentValue > 0) { // 0보다 클 때만 감소
      controller.text = (currentValue - 1).toString();
    }
  }

  // ✨ 8단계: 메인 등록 함수 (가장 중요!)
  insertAction() async {
    // 입력값 검증: 패키지명이 비어있는지 확인
    if (packageNameInput.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('패키지명을 입력해주세요.'),
          backgroundColor: Colors.red[600],
        ),
      );
      return; // 함수 종료
    }

    // 입력값 검증: 최소 이미지 개수 확인
    if (selectedImages.length < minImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '최소 ${minImages}개 이미지를 선택해주세요. 현재: ${selectedImages.length}개',
          ),
          backgroundColor: Colors.red[600],
        ),
      );
      return;
    }

    // 업로드 시작: 로딩 상태로 변경
    setState(() {
      isUploading = true;
    });

    try {
      // 1단계: 이미지들을 Firebase Storage에 업로드
      List<String> imageUrls = await _uploadImages();

      // 2단계: Firestore에 패키지 정보 저장
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('package') // 'package' 컬렉션에 저장
          .add({
            "pName": packageNameInput.text.trim(), // 패키지명
            "tName": agencyNameInput.text.trim(), // 여행사명
            "aId": airlineCodeInput.text.trim(), // 항공편 번호
            "pPrice": packagePriceInput.text.trim(), // 가격
            "pNum": bookingNumberInput.text.trim(), // 예매번호
            "pPlan": packagePlanInput.text.trim(), // 플랜 설명
            "pCount": groupCountInput.text.trim(), // 최대 인원
            "pStart": startDateInput.text.trim(), // 출발일
            "pEnd": endDateInput.text.trim(), // 도착일
            "pDate": DateTime.now().toString().substring(0, 19), // 등록일시
            "pState": currentStatus, // 패키지 상태
            "images": imageUrls, // 업로드된 이미지 URL들
          });

      // 업로드 완료: 로딩 상태 해제
      setState(() {
        isUploading = false;
      });

      // 성공 다이얼로그 표시
      _showDialog();
    } catch (e) {
      // 오류 발생 시 처리
      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('등록 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  // Firebase Storage에 이미지들을 업로드하는 함수
  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = []; // 업로드된 이미지 URL들을 저장할 리스트

    // 각 이미지를 하나씩 업로드
    for (int i = 0; i < selectedImages.length; i++) {
      try {
        // 파일 유효성 검사
        bool isValid = false;
        int fileSize = 0;

        if (kIsWeb) {
          // 웹 환경: 바이트 데이터로 처리
          final bytes = await selectedImages[i].readAsBytes();
          fileSize = bytes.length;
          isValid = bytes.isNotEmpty;
        } else {
          // 모바일 환경: 파일 경로로 처리
          final file = File(selectedImages[i].path);
          isValid = await file.exists();
          if (isValid) {
            fileSize = await file.length();
          }
        }

        // 파일이 유효하지 않으면 건너뛰기
        if (!isValid || fileSize == 0) {
          continue;
        }

        // 고유한 파일명 생성 (패키지명_인덱스_타임스탬프.jpg)
        String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        String fileName = "${packageNameInput.text.trim().replaceAll(' ', '_')}_${i}_$timestamp.jpg";

        // Firebase Storage 참조 생성 (images 폴더에 저장)
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('images')
            .child(fileName);

        // 실제 업로드 실행
        if (kIsWeb) {
          final bytes = await selectedImages[i].readAsBytes();
          await storageRef.putData(bytes); // 웹: 데이터로 업로드
        } else {
          await storageRef.putFile(File(selectedImages[i].path)); // 모바일: 파일로 업로드
        }

        // 업로드된 파일의 다운로드 URL 획득
        String downloadUrl = await storageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (e) {
        // 개별 이미지 업로드 실패는 전체를 중단시키지 않고 계속 진행
        continue;
      }
    }

    // 모든 이미지 업로드에 실패했다면 예외 발생
    if (imageUrls.isEmpty) {
      throw Exception('모든 이미지 업로드에 실패했습니다. Firebase Storage 권한을 확인해주세요.');
    }

    return imageUrls;
  }

  // 등록 완료 다이얼로그를 표시하는 함수
  _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 바깥쪽 클릭으로 닫기 방지
      builder: (context) => AlertDialog(
        title: Text("등록 완료"),
        content: Text(
          '여행 패키지가 성공적으로 등록되었습니다!\n이미지 ${selectedImages.length}개가 업로드되었습니다.',
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 이전 페이지로 돌아가기
            },
            child: Text(
              '확인',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
