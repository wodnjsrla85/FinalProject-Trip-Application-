// ignore_for_file: prefer_const_constructors_in_immutables

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
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

  TextEditingController packageName = TextEditingController();
  TextEditingController agencyName = TextEditingController();
  TextEditingController airlineCode = TextEditingController();
  TextEditingController packagePrice = TextEditingController();
  TextEditingController bookingNumber = TextEditingController();
  TextEditingController packagePlan = TextEditingController();
  TextEditingController groupCount = TextEditingController();
  TextEditingController startDate = TextEditingController();
  TextEditingController endDate = TextEditingController();

  List<XFile> selectedImages = [];
  final ImagePicker picker = ImagePicker();
  final int minImages = 4;
  final int maxImages = 4;

  String currentStatus = '모집중';
  final List<String> statusOptions = ['모집중', '모집마감'];
  bool isUploading = false;

  @override
  void dispose() {
    packageName.dispose();
    agencyName.dispose();
    airlineCode.dispose();
    packagePrice.dispose();
    bookingNumber.dispose();
    packagePlan.dispose();
    groupCount.dispose();
    startDate.dispose();
    endDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor, // 색상 변경
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text('AirTravel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkText, // 색상 변경
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('새로운 여행 패키지 추가', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkText)), // 색상 변경
              SizedBox(height: 8),
              Text('새로운 여행 패키지를 생성하기 위해 아래 세부정보를 입력하세요.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              SizedBox(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.only(right: 40),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: buildTextField(packageName, '패키지명', '예: 산토리니 여행')),
                              SizedBox(width: 20),
                              Expanded(child: buildTextField(agencyName, '여행사명', '예: 좋은여행사')),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: buildTextField(airlineCode, '항공편 번호', '예: GT-1234')),
                              SizedBox(width: 20),
                              Expanded(child: buildTextField(bookingNumber, '예매번호', '예: PKG-98765')),
                            ],
                          ),
                          SizedBox(height: 20),
                          buildTextField(packagePlan, '패키지 설명', '여행 패키지를 자세히 설명해주세요...', maxLines: 5),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: buildNumberField(packagePrice, '가격 (원)', '예: 2500000')),
                              SizedBox(width: 20),
                              Expanded(child: buildNumberField(groupCount, '최대 인원', '예: 50')),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: buildTextField(startDate, '출발일', '2025.09.10.')),
                              SizedBox(width: 20),
                              Expanded(child: buildTextField(endDate, '도착일', '2025.09.15.')),
                            ],
                          ),
                          SizedBox(height: 20),
                          buildStatusDropdown(),
                        ],
                      ),
                    ),
                  ),
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
                          Text('패키지 이미지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText)), // 색상 변경
                          SizedBox(height: 24),
                          buildImageUploadButton(),
                          SizedBox(height: 20),
                          buildImageGrid(),
                          SizedBox(height: 16),
                          Text('최소 ${minImages}장 이미지 업로드', style: TextStyle(fontSize: 12, color: primaryColor)), // 색상 변경
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading ? null : insertAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, // 색상 변경
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

  Widget buildTextField(TextEditingController controller, String label, String placeholder, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkText)), // 색상 변경
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor, width: 2)), // 색상 변경
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget buildNumberField(TextEditingController controller, String label, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkText)), // 색상 변경
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor, width: 2)), // 색상 변경
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
            suffixIcon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(onTap: () => incrementValue(controller), child: Icon(Icons.keyboard_arrow_up, size: 16)),
                GestureDetector(onTap: () => decrementValue(controller), child: Icon(Icons.keyboard_arrow_down, size: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('패키지 상태', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: darkText)), // 색상 변경
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
            Icon(Icons.cloud_upload_outlined, size: 32, color: isUploading ? Colors.grey[400] : primaryColor), // 색상 변경
            SizedBox(height: 8),
            Text('클릭하여 업로드', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isUploading ? Colors.grey[400] : darkText)), // 색상 변경
          ],
        ),
      ),
    );
  }

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

  Widget buildEmptyImageSlot() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
      child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 24),
    );
  }

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

  getImageFromGallery(ImageSource imageSource) async {
    try {
      final List<XFile>? pickedImages = await picker.pickMultiImage();
      if (pickedImages != null) {
        setState(() {
          selectedImages.clear();
          selectedImages.addAll(pickedImages.take(maxImages));
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${selectedImages.length}개 이미지가 선택되었습니다.'), backgroundColor: secondaryColor)); // 색상 변경
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다.'), backgroundColor: Colors.red[600]));
    }
  }

  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  void incrementValue(TextEditingController controller) {
    int currentValue = int.tryParse(controller.text) ?? 0;
    controller.text = (currentValue + 1).toString();
  }

  void decrementValue(TextEditingController controller) {
    int currentValue = int.tryParse(controller.text) ?? 0;
    if (currentValue > 0) {
      controller.text = (currentValue - 1).toString();
    }
  }

  insertAction() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (authError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firebase 인증 실패: 네트워크를 확인해주세요.'), backgroundColor: Colors.red[600]));
      return;
    }

    if (packageName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('패키지명을 입력해주세요.'), backgroundColor: Colors.red[600]));
      return;
    }

    if (selectedImages.length < minImages) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('최소 ${minImages}개 이미지를 선택해주세요.'), backgroundColor: Colors.red[600]));
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      List<String> imageUrls = await uploadImages();

      DocumentReference docRef = await FirebaseFirestore.instance.collection('package').add({
        "pName": packageName.text.trim(),
        "tName": agencyName.text.trim(),
        "aId": airlineCode.text.trim(),
        "pPrice": packagePrice.text.trim(),
        "pNum": bookingNumber.text.trim(),
        "pPlan": packagePlan.text.trim(),
        "pCount": groupCount.text.trim(),
        "pStart": startDate.text.trim(),
        "pEnd": endDate.text.trim(),
        "pDate": DateTime.now().toString().substring(0, 19),
        "pState": currentStatus,
        "images": imageUrls,
      });

      setState(() {
        isUploading = false;
      });

      showSuccessDialog();
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('등록 중 오류가 발생했습니다.'), backgroundColor: Colors.red[600]));
    }
  }

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
            child: Text('확인', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)), // 색상 변경
          ),
        ],
      ),
    );
  }
}
