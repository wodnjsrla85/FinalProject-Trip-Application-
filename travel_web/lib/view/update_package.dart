import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UpdatePackage extends StatefulWidget {
  final DocumentSnapshot packageDoc;
  const UpdatePackage({super.key, required this.packageDoc});

  @override
  State<UpdatePackage> createState() => _UpdatePackageState();
}

class _UpdatePackageState extends State<UpdatePackage> {
  late TextEditingController nameCtrl;
  late TextEditingController agencyCtrl;
  late TextEditingController airlineCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController bookingCtrl;
  late TextEditingController planCtrl;
  late TextEditingController countCtrl;
  late TextEditingController startCtrl;
  late TextEditingController endCtrl;

  final ImagePicker picker = ImagePicker();
  final int minCount = 4;
  final int maxCount = 4;

  List<String> savedUrls = [];
  List<XFile> newImages = [];

  late String status;
  final List<String> statusList = ['모집중', '모집마감'];

  bool uploading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.packageDoc.data() as Map<String, dynamic>;
    nameCtrl = TextEditingController(text: data['pName'] ?? '');
    agencyCtrl = TextEditingController(text: data['tName'] ?? '');
    airlineCtrl = TextEditingController(text: data['aId'] ?? '');
    priceCtrl = TextEditingController(text: data['pPrice'] ?? '');
    bookingCtrl = TextEditingController(text: data['pNum'] ?? '');
    planCtrl = TextEditingController(text: data['pPlan'] ?? '');
    countCtrl = TextEditingController(text: data['pCount'] ?? '');
    startCtrl = TextEditingController(text: data['pStart'] ?? '');
    endCtrl = TextEditingController(text: data['pEnd'] ?? '');
    savedUrls = List<String>.from(data['images'] ?? []);
    status = data['pState'] ?? statusList.first;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    agencyCtrl.dispose();
    airlineCtrl.dispose();
    priceCtrl.dispose();
    bookingCtrl.dispose();
    planCtrl.dispose();
    countCtrl.dispose();
    startCtrl.dispose();
    endCtrl.dispose();
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
              decoration:
                  BoxDecoration(color: Colors.blue[600], borderRadius: BorderRadius.circular(6)),
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
              Text('패키지 정보를 수정하고 저장하세요.', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
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
                              Expanded(child: buildTextField(nameCtrl, '패키지명', '예: 산토리니 여름 휴가')),
                              SizedBox(width: 20),
                              Expanded(child: buildTextField(agencyCtrl, '여행사명', '예: 글로브트로터스')),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: buildTextField(airlineCtrl, '항공편 번호', '예: GT-1234')),
                              SizedBox(width: 20),
                              Expanded(child: buildTextField(bookingCtrl, '패키지 예매번호', '예: PKG-98765')),
                            ],
                          ),
                          SizedBox(height: 20),
                          buildTextField(planCtrl, '패키지 설명', '여행 패키지를 자세히 설명해주세요...', maxLines: 5),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: buildNumField(priceCtrl, '가격 (원)', '예: 2,500,000')),
                              SizedBox(width: 20),
                              Expanded(child: buildNumField(countCtrl, '최대 인원', '예: 50')),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: buildTextField(startCtrl, '출발일', '2025.09.10.')),
                              SizedBox(width: 20),
                              Expanded(child: buildTextField(endCtrl, '도착일', '2025.09.14.')),
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
                          border: Border.all(color: Colors.grey[200]!)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('패키지 이미지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 24),
                          imageUploadBtn(),
                          SizedBox(height: 20),
                          imageGrid(),
                          SizedBox(height: 16),
                          Text('최소 $minCount장 이미지 유지', style: TextStyle(fontSize: 12, color: Colors.blue[600])),
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
                  onPressed: uploading ? null : updateAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: uploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('업로드 중...'),
                          ],
                        )
                      : Text('여행 패키지 수정하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
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
            items: statusList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => status = v ?? status),
          ),
        ),
      ],
    );
  }

  Widget imageUploadBtn() {
    return Container(
      height: 120,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!), color: Colors.white),
      child: InkWell(
        onTap: uploading ? null : pickImages,
        borderRadius: BorderRadius.circular(8),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.cloud_upload_outlined, size: 32, color: uploading ? Colors.grey[400] : Colors.blue[600]),
          SizedBox(height: 8),
          Text('클릭하여 업로드', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: uploading ? Colors.grey[400] : Colors.grey[700]))
        ]),
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
        if (i < savedUrls.length) {
          return buildSavedImage(savedUrls[i], i);
        } else if (i - savedUrls.length < newImages.length) {
          return buildNewImage(newImages[i - savedUrls.length], i - savedUrls.length);
        } else {
          return emptySlot();
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
              loadingBuilder: (c, child, loading) => loading == null ? child : Container(color: Colors.blue[100], child: Center(child: CircularProgressIndicator())),
              errorBuilder: (_, __, ___) => Container(color: Colors.orange[200], child: Icon(Icons.wifi_off, color: Colors.orange)),
            ),
          ),
        ),
        Positioned(top: 6, right: 6, child: GestureDetector(onTap: uploading ? null : () => setState(() => savedUrls.removeAt(index)), child: closeBtn())),
      ],
    );
  }

  Widget buildNewImage(XFile image, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? FutureBuilder<List<int>>(
                    future: image.readAsBytes(),
                    builder: (_, snap) =>
                        snap.hasData ? Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover) : Center(child: CircularProgressIndicator()))
                : Image.file(File(image.path), fit: BoxFit.cover),
          ),
        ),
        Positioned(top: 6, right: 6, child: GestureDetector(onTap: uploading ? null : () => setState(() => newImages.removeAt(index)), child: closeBtn())),
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
          newImages.addAll(picked.take(maxCount - savedUrls.length));
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${newImages.length}개 이미지 선택됨'), backgroundColor: Colors.green[600]));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 선택 오류: $e'), backgroundColor: Colors.red[600]));
    }
  }

  Future<void> updateAction() async {
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('패키지명을 입력하세요'), backgroundColor: Colors.red));
      return;
    }
    if ((savedUrls.length + newImages.length) < minCount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('최소 $minCount장 이미지가 필요합니다'), backgroundColor: Colors.red));
      return;
    }

    setState(() => uploading = true);
    try {
      final newUrls = await uploadImages();
      final allUrls = [...savedUrls, ...newUrls];
      await widget.packageDoc.reference.update({
        'pName': nameCtrl.text.trim(),
        'tName': agencyCtrl.text.trim(),
        'aId': airlineCtrl.text.trim(),
        'pPrice': priceCtrl.text.trim(),
        'pNum': bookingCtrl.text.trim(),
        'pPlan': planCtrl.text.trim(),
        'pCount': countCtrl.text.trim(),
        'pStart': startCtrl.text.trim(),
        'pEnd': endCtrl.text.trim(),
        'pState': status,
        'images': allUrls,
      });
      setState(() => uploading = false);
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
                title: Text('수정 완료'),
                content: Text('여행 패키지가 성공적으로 수정되었습니다.'),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Text('확인'))
                ],
              ));
    } catch (e) {
      setState(() => uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 중 오류: $e'), backgroundColor: Colors.red));
    }
  }

  Future<List<String>> uploadImages() async {
    List<String> urls = [];

    String safeName = nameCtrl.text.trim();
    if (safeName.isEmpty) {
      safeName = 'default_name';
    }
    safeName = safeName.replaceAll(' ', '_');

    for (int i = 0; i < newImages.length; i++) {
      try {
        String fileName = '${safeName}_${i}_{DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child('images').child(fileName);
        if (kIsWeb) {
          final bytes = await newImages[i].readAsBytes();
          await ref.putData(bytes);
        } else {
          await ref.putFile(File(newImages[i].path));
        }
        final downloadUrl = await ref.getDownloadURL();
        urls.add(downloadUrl);
      } catch (e) {
        debugPrint('Upload error: $e');
      }
    }
    return urls;
  }
}
