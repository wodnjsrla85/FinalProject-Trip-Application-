import 'package:flutter_riverpod/flutter_riverpod.dart';

// 제목 상태
final inqueryTitleProvider = StateProvider<String>((ref) => "");

// 내용 상태
final inqueryContentProvider = StateProvider<String>((ref) => "");

// 로딩 상태
final inqueryLoadingProvider = StateProvider<bool>((ref) => false);

// to 상태 (어플, 항공사, 여행사)
final inqueryToProvider = StateProvider<String>((ref) => "어플");

// 패키지 선택 Provider
final selectedPackageProvider = StateProvider<String?>((ref) => null);

// 선택된 항공편/패키지 refId 저장
final inqueryRefIdProvider = StateProvider<String>((ref) => "");
