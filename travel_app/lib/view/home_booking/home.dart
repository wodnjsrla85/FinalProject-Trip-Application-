import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/Widget/flight_result.dart';
import 'package:travel_app/Widget/flight_search.dart';
import 'package:travel_app/Widget/package_widget.dart';
import 'package:travel_app/Widget/user_info.dart';
import 'package:travel_app/vm/home_provider.dart';

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchStateProvider);
    final flights = ref.watch(flightsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
          child: Column(
            children: [
              const UserInfo(),
              const SizedBox(height: 20),
              
              const FlightSearch(),
              const SizedBox(height: 20),
              
              // AnimatedSwitcher로 부드러운 전환 효과
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: searchState
                    ? Container(
                        key: ValueKey(flights.hashCode), // 데이터가 바뀔 때마다 애니메이션 트리거
                        child: const FlightResult(),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('empty'),
                      ),
              ),
              
              const SizedBox(height: 20),
              
              // PackageWidget도 애니메이션 효과 추가
              AnimatedOpacity(
                opacity: searchState ? 0.6 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  transform: Matrix4.translationValues(0, searchState ? 20 : 0, 0),
                  child: PackageWidget(),
                ),
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}