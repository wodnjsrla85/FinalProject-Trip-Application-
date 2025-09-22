import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:travel_web/view/package/insert_package.dart';
import 'package:travel_web/view/package/update_package.dart';

class TravelPackageMain extends StatefulWidget {
  TravelPackageMain({Key? key}) : super(key: key);

  @override
  State<TravelPackageMain> createState() => _TravelMainState();
}

class _TravelMainState extends State<TravelPackageMain> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('여행 패키지 관리'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: openInsert),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('package').orderBy('pDate', descending: true).snapshots(),
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 64),
                  SizedBox(height: 16),
                  Text('데이터 로딩 오류', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  ElevatedButton(onPressed: () => setState(() {}), child: Text('다시 시도')),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('데이터 로딩 중...'),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flight_takeoff, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('등록된 패키지가 없습니다', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  SizedBox(height: 16),
                  ElevatedButton.icon(icon: Icon(Icons.add), label: Text('첫 패키지 추가하기'), onPressed: openInsert),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16),
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              return buildPackageCard(docs[i]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.add),
        label: Text('패키지 추가'),
        backgroundColor: Colors.green[600],
        onPressed: openInsert,
      ),
    );
  }

  Widget buildPackageCard(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      final packageName = data['pName']?.toString() ?? '이름 없음';
      final agencyName = data['tName']?.toString() ?? '';
      final airlineCode = data['aId']?.toString() ?? '';
      final packageState = data['pState']?.toString() ?? '';
      final packagePrice = data['pPrice']?.toString() ?? '';
      final startDate = data['pStart']?.toString() ?? '';
      final endDate = data['pEnd']?.toString() ?? '';
      final groupCount = data['pCount']?.toString() ?? '';

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(packageName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: packageState == '모집중' ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      packageState,
                      style: TextStyle(
                        color: packageState == '모집중' ? Colors.green[700] : Colors.orange[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (agencyName.isNotEmpty) buildInfoRow(Icons.business, '여행사', agencyName),
                        if (airlineCode.isNotEmpty) buildInfoRow(Icons.flight, '항공편', airlineCode),
                        if (packagePrice.isNotEmpty) buildInfoRow(Icons.attach_money, '가격', '${packagePrice}원'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (startDate.isNotEmpty) buildInfoRow(Icons.flight_takeoff, '출발', startDate),
                        if (endDate.isNotEmpty) buildInfoRow(Icons.flight_land, '도착', endDate),
                        if (groupCount.isNotEmpty) buildInfoRow(Icons.group, '인원', '${groupCount}명'),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.edit, size: 18),
                    label: Text('수정'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange[600]),
                    onPressed: () => openUpdate(doc),
                  ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    icon: Icon(Icons.delete, size: 18),
                    label: Text('삭제'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
                    onPressed: () => confirmDelete(doc),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('데이터 오류', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700])),
                    Text('문서 ID: ${doc.id}', style: TextStyle(color: Colors.red[600], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  void openInsert() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => InsertPackage())).then((_) => setState(() {}));
  }

  void openUpdate(DocumentSnapshot doc) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => UpdatePackage(packageDoc: doc))).then((_) => setState(() {}));
  }

  void confirmDelete(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['pName'] ?? '이름 없음';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('패키지 삭제'),
          ],
        ),
        content: Text('"$name" 패키지를 삭제하시겠습니까?\n\n삭제된 데이터는 복구할 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await deletePackage(doc);
            },
            child: Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> deletePackage(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final imageUrls = List<String>.from(data['images'] ?? []);

      for (String url in imageUrls) {
        if (url.startsWith('https://firebasestorage')) {
          try {
            await FirebaseStorage.instance.refFromURL(url).delete();
          } catch (e) {}
        }
      }

      await doc.reference.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('패키지가 성공적으로 삭제되었습니다'),
              ],
            ),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('삭제 중 오류가 발생했습니다'),
              ],
            ),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }
}
