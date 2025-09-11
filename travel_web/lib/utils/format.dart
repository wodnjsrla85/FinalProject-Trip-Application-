// lib/utils/format.dart
String won(num v) {
  final s = v.toInt().toString();
  final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
  return s.replaceAll(reg, ',');
}