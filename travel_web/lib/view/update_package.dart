import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
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
  late TextEditingController packageName;
  late TextEditingController agencyName;
  late TextEditingController airlineCode;
  late TextEditingController packagePrice;
  late TextEditingController bookingNumber;
  late TextEditingController packagePlan;
  late TextEditingController groupCount;
  late TextEditingController startDate;
  late TextEditingController endDate;

  final ImagePicker picker = ImagePicker();
  final int minCount = 4;
  final int maxCount = 4;

  List<String> savedImageUrls = [];
  List<XFile> newImages = [];

  late String status;
  final List<String> statusOptions = ['모집중', '모집마감'];

  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.packageDoc.data() as Map<String, dynamic>;
    packageName = TextEditingController(text: data['pName'] ?? '');
    agencyName = TextEditingController(text: data['tName'] ?? '');
    airlineCode = TextEditingController(text: data['aId'] ?? '');
    packagePrice = TextEditingController(text: data['pPrice'] ?? '');
    bookingNumber = TextEditingController(text: data['pNum'] ?? '');
    packagePlan = TextEditingController(text: data['pPlan'] ?? '');
    groupCount = TextEditingController(text: data['pCount'] ?? '');
    startDate = TextEditingController(text: data['pStart'] ?? '');
    endDate = TextEditingController(text: data['pEnd'] ?? '');
    savedImageUrls = List<String>.from(data['images'] ?? []);
    status = data['pState'] ?? statusOptions.first;
  }

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
              decoration: BoxDecoration(color: Colors.blue[600], borderRadius: BorderRadius.circular(6)),
              child: Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text('AirTravel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('여행 패키지 수정', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('패키지 정보를 수정하고 저장하세요. 새 이미지 선택 시 기존 이미지가 완전히 교체됩니다.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
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
                              Expanded(child: buildTextField(packageName, '패키지명', '예: 산토리니')),
                              SizedBox(width: 20),
                              Expanded(child: buildTextField(agencyName, '여행사명', '예: 좋은여행사')),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: buildTextField(airlineCode, '항공편 번호', '예: GT123')),
                              SizedBox(width: 20),
                              Expanded(child: buildTextField(bookingNumber, '패키지 예매번호', '예: PKG456')),
                            ],
                          ),
                          SizedBox(height: 20),
                          buildTextField(packagePlan, '패키지 설명', '여행 패키지를 자세히 설명해주세요...', maxLines: 5),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: buildNumField(packagePrice, '가격 (원)', '예: 2500000')),
                              SizedBox(width: 20),
                              Expanded(child: buildNumField(groupCount, '최대 인원', '예: 50')),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: buildTextField(startDate, '출발일', '2025.09.10.')),
                              SizedBox(width: 20),
                              Expanded(child: buildTextField(endDate, '도착일', '2025.09.14.')),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(children: [SizedBox(width: 20), Expanded(child: buildDropdown())]),
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
                          Text('패키지 이미지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 24),
                          imageUploadBtn(),
                          SizedBox(height: 20),
                          imageGrid(),
                          SizedBox(height: 16),
                          Text('최소 $minCount장 이미지 필요', style: TextStyle(fontSize: 12, color: Colors.blue[600])),
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
                  onPressed: isUploading ? null : updateAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
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

  Widget buildTextField(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blue[600]!, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget buildNumField(TextEditingController ctrl, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blue[600]!, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            fillColor: Colors.white,
            filled: true,
            suffixIcon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(onTap: () => increment(ctrl), child: Icon(Icons.keyboard_arrow_up, size: 16)),
                GestureDetector(onTap: () => decrement(ctrl), child: Icon(Icons.keyboard_arrow_down, size: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('패키지 상태', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
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

  Widget imageUploadBtn() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: newImages.isNotEmpty ? Colors.orange[300]! : Colors.grey[300]!, width: newImages.isNotEmpty ? 2 : 1),
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
              color: isUploading ? Colors.grey[400] : (newImages.isNotEmpty ? Colors.orange[600] : Colors.blue[600]),
            ),
            SizedBox(height: 8),
            Text(
              newImages.isNotEmpty ? '새 이미지 ${newImages.length}개 선택됨' : '클릭하여 새 이미지 업로드',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isUploading ? Colors.grey[400] : Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

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
              loadingBuilder: (c, child, loading) => loading == null ? child : Container(color: Colors.blue[100], child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              errorBuilder: (_, __, ___) => Container(
                color: Colors.orange[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.wifi_off, color: Colors.orange, size: 20), Text('CORS\n오류', style: TextStyle(fontSize: 8, color: Colors.orange), textAlign: TextAlign.center)],
                ),
              ),
            ),
          ),
        ),
        Positioned(top: 6, right: 6, child: GestureDetector(onTap: isUploading ? null : () => setState(() => savedImageUrls.removeAt(index)), child: closeBtn())),
      ],
    );
  }

  Widget buildNewImage(XFile image, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200], border: Border.all(color: Colors.orange[400]!, width: 2)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? FutureBuilder<List<int>>(
                    future: image.readAsBytes(),
                    builder: (_, snap) => snap.hasData ? Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover, width: double.infinity, height: double.infinity) : Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : Image.file(File(image.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          ),
        ),
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(color: Colors.orange[600], borderRadius: BorderRadius.circular(6)),
            child: Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ),
        Positioned(top: 6, right: 6, child: GestureDetector(onTap: isUploading ? null : () => setState(() => newImages.removeAt(index)), child: closeBtn())),
      ],
    );
  }

  Widget emptySlot() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
      child: Icon(Icons.image_outlined, color: Colors.grey, size: 24),
    );
  }

  Widget closeBtn() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: Colors.grey[600], shape: BoxShape.circle),
      child: Icon(Icons.close, color: Colors.white, size: 12),
    );
  }

  void increment(TextEditingController ctrl) {
    int val = int.tryParse(ctrl.text) ?? 0;
    ctrl.text = (val + 1).toString();
  }

  void decrement(TextEditingController ctrl) {
    int val = int.tryParse(ctrl.text) ?? 0;
    if (val > 0) ctrl.text = (val - 1).toString();
  }

  Future<void> pickImages() async {
    try {
      final picked = await picker.pickMultiImage();
      if (picked != null) {
        setState(() {
          newImages.clear();
          newImages.addAll(picked.take(maxCount));
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${newImages.length}개 새 이미지 선택됨'), backgroundColor: Colors.orange[600]));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 선택 오류'), backgroundColor: Colors.red[600]));
    }
  }

  Future<void> updateAction() async {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지가 성공적으로 교체되었습니다'), backgroundColor: Colors.green[600]));
      } else {
        finalImageUrls = savedImageUrls;
      }

      await widget.packageDoc.reference.update({
        'pName': packageName.text.trim(),
        'tName': agencyName.text.trim(),
        'aId': airlineCode.text.trim(),
        'pPrice': packagePrice.text.trim(),
        'pNum': bookingNumber.text.trim(),
        'pPlan': packagePlan.text.trim(),
        'pCount': groupCount.text.trim(),
        'pStart': startDate.text.trim(),
        'pEnd': endDate.text.trim(),
        'pState': status,
        'images': finalImageUrls,
      });

      setState(() => isUploading = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(
            children: [Icon(Icons.check_circle, color: Colors.green[600]), SizedBox(width: 8), Text('수정 완료')],
          ),
          content: Text(newImages.isNotEmpty ? '패키지 수정 및 이미지 교체가 완료되었습니다.' : '패키지 정보가 수정되었습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('확인', style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 중 오류가 발생했습니다'), backgroundColor: Colors.red));
    }
  }

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
