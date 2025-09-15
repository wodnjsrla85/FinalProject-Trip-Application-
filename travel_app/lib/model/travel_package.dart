class TravelPackage {
  final String id;       // Firestore 문서 ID
  final String aId;
  final List<String> images;
  final String pCount;
  final String pDate;
  final String pEnd;
  final String pName;
  final String pNum;
  final String pPlan;
  final String pPrice;
  final String pStart;
  final String pState;
  final String tName;

  TravelPackage({
    required this.id,
    required this.aId,
    required this.images,
    required this.pCount,
    required this.pDate,
    required this.pEnd,
    required this.pName,
    required this.pNum,
    required this.pPlan,
    required this.pPrice,
    required this.pStart,
    required this.pState,
    required this.tName,
  });

  factory TravelPackage.fromMap(Map<String, dynamic> map, String id) {
    return TravelPackage(
      id: id,
      aId: map['aId'] ?? "",
      images: (map['images'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      pCount: map['pCount'] ?? "",
      pDate: map['pDate'] ?? "",
      pEnd: map['pEnd'] ?? "",
      pName: map['pName'] ?? "",
      pNum: map['pNum'] ?? "",
      pPlan: map['pPlan'] ?? "",
      pPrice: map['pPrice'] ?? "",
      pStart: map['pStart'] ?? "",
      pState: map['pState'] ?? "",
      tName: map['tName'] ?? "",
    );
  }
}
