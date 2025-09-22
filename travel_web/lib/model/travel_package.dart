/// 여행 패키지 정보를 담는 모델 클래스
/// 다이어그램의 Package 엔티티에 해당
class TravelPackage {
  final String pName;       // 패키지이름
  final String tName;       // 여행사명 (TName)
  final String aId;         // 항공편 번호 (Aid)
  final String pPrice;      // 가격 (PPrice)
  final String pNum;        // 패키지 예매번호 (PNum)
  final String pPlan;       // 패키지플랜 (PPlan)
  final String pCount;      // 모집인원 (PCount)
  final String pStart;      // 출발일자 (PStart)
  final String pEnd;        // 도착일자 (PEnd)
  final String pDate;       // 패키지 등록일자 (PDate)
  final String pState;      // 패키지 상태 (PState)

  /// TravelPackage 생성자
  /// 다이어그램의 모든 속성을 포함
  TravelPackage({
    required this.pName,
    required this.tName,
    required this.aId,
    required this.pPrice,
    required this.pNum,
    required this.pPlan,
    required this.pCount,
    required this.pStart,
    required this.pEnd,
    required this.pDate,
    required this.pState,
  });

  // /// 객체를 Map<String, dynamic> 형태로 변환
  // /// Firestore에 데이터를 저장할 때 사용
  // Map<String, dynamic> toJson() {
  //   return {
  //     'pName': pName,
  //     'tName': tName,
  //     'aId': aId,
  //     'pPrice': pPrice,
  //     'pNum': pNum,
  //     'pPlan': pPlan,
  //     'pCount': pCount,
  //     'pStart': pStart,
  //     'pEnd': pEnd,
  //     'pDate': pDate,
  //     'pState': pState,
  //     'uEmail': uEmail,
  //   };
  // }

  // /// Map<String, dynamic>에서 TravelPackage 객체로 변환
  // /// Firestore에서 데이터를 불러올 때 사용
  // factory TravelPackage.fromMap(Map<String, dynamic> map) {
  //   return TravelPackage(
  //     pName: map['pName'] ?? '',
  //     tName: map['tName'] ?? '',
  //     aId: map['aId'] ?? '',
  //     pPrice: map['pPrice'] ?? '',
  //     pNum: map['pNum'] ?? '',
  //     pPlan: map['pPlan'] ?? '',
  //     pCount: map['pCount'] ?? '',
  //     pStart: map['pStart'] ?? '',
  //     pEnd: map['pEnd'] ?? '',
  //     pDate: map['pDate'] ?? '',
  //     pState: map['pState'] ?? '',
  //     uEmail: map['uEmail'] ?? '',
  //   );
  // }
}
