import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:travel_web/view/insert_package.dart';
import 'package:travel_web/view/update_package.dart';

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
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: openInsert,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('package')
            .orderBy('pDate', descending: true)
            .snapshots(),
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 64),
                  Text('데이터 로딩 오류: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('다시 시도'),
                  )
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text('등록된 패키지가 없습니다'));
          }
          return ListView.separated(
            padding: EdgeInsets.all(16),
            separatorBuilder: (_, __) => SizedBox(height: 8),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              return buildCard(docs[i]);
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

  Widget buildCard(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['pName'] ?? '';
      final agency = data['tName'] ?? '';
      final airline = data['aId'] ?? '';
      final state = data['pState'] ?? '';
      String thumb = '';
      if (data['images'] is List && (data['images'] as List).isNotEmpty) {
        thumb = data['images'][0];
      } else if (data['image'] != null) {
        thumb = data['image'];
      }

      return Card(
        child: ListTile(
          leading: SizedBox(
            width: 70,
            height: 60,
            child: buildThumbnail(thumb),
          ),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$agency · $airline'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state, style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.orange),
                onPressed: () => openUpdate(doc),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => confirmDelete(doc),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      return Card(
        color: Colors.red[100],
        child: ListTile(
          leading: Icon(Icons.error, color: Colors.red),
          title: Text('데이터 오류'),
          subtitle: Text('문서 ID: ${doc.id}'),
        ),
      );
    }
  }

  Widget buildThumbnail(String url) {
    if (url.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Icon(Icons.flight_takeoff, color: Colors.grey),
      );
    }

    if (url.startsWith('https://firebasestorage')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.blue[100],
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (_, __, ___) {
          return Container(
            color: Colors.orange[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: Colors.orange, size: 20),
                Text(
                  'CORS\n오류',
                  style: TextStyle(fontSize: 8, color: Colors.orange),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          );
        },
      );
    }

    return Container(
      color: Colors.purple[200],
      child: Icon(Icons.help_outline, color: Colors.purple),
    );
  }

  void openInsert() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InsertPackage()),
    ).then((_) => setState(() {}));
  }

  void openUpdate(DocumentSnapshot doc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UpdatePackage(packageDoc: doc)),
    ).then((_) => setState(() {}));
  }

  void confirmDelete(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['pName'] ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('패키지 삭제'),
        content: Text('"$name" 패키지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await deletePackage(doc);
              setState(() {});
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
      final urls = List<String>.from(data['images'] ?? []);
      for (var url in urls) {
        if (url.startsWith('https://firebasestorage')) {
          try {
            await FirebaseStorage.instance.refFromURL(url).delete();
          } catch (_) {}
        }
      }
      await doc.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('삭제 완료'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('삭제 오류: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
