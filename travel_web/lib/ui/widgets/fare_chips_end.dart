import 'package:flutter/material.dart';
import '../../models/airplane_end.dart';

class FareChipsEnd extends StatelessWidget {
  final AirplaneEnd a;
  final bool peak; // true=성수기, false=비수기
  const FareChipsEnd({super.key, required this.a, this.peak = false});

  String won(int v) => '${v.toString()}원';

  @override
  Widget build(BuildContext context) {
    final eco   = peak ? a.peakEconomy   : a.offpeakEconomy;
    final prem  = peak ? a.peakPremium   : a.offpeakPremium;
    final biz   = peak ? a.peakBusiness  : a.offpeakBusiness;
    final first = peak ? a.peakFirst     : a.offpeakFirst;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        Chip(label: Text('이코노미 ${won(eco)}')),
        Chip(label: Text('프리미엄 ${won(prem)}')),
        Chip(label: Text('비즈니스 ${won(biz)}')),
        Chip(label: Text('퍼스트 ${won(first)}')),
      ],
    );
  }
}