import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/Model/ShortMeta.dart'; // ShortMeta
import 'package:travel_app/vm/shorts_provider.dart';

import 'package:video_player/video_player.dart';

class ShortsReelsPage extends ConsumerStatefulWidget {
  const ShortsReelsPage({super.key});

  @override
  ConsumerState<ShortsReelsPage> createState() => _ShortsReelsPageState();
}

class _ShortsReelsPageState extends ConsumerState<ShortsReelsPage> {
  final PageController _pageController = PageController();
  final Map<int, VideoPlayerController> _controllers = {};
  final Set<int> _initializing = {}; // ✅ 중복 초기화 방지
  int _currentIndex = 0;
  bool _muted = true;
  bool _bootstrapped = false; // ✅ 첫 자동재생 1회만

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    for (final c in _controllers.values.toList()) {
      c.dispose();
    }
    _controllers.clear();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _ensureController(int index, String url) async {
    if (_controllers[index] != null || _initializing.contains(index)) return;
    _initializing.add(index);
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(_muted ? 0 : 1);
      _controllers[index] = c; // ✅ 초기화 끝난 뒤 Map에 넣기
    } finally {
      _initializing.remove(index);
    }
  }

  Future<void> _playIndex(int index, List<ShortMeta> items) async {
    if (index < 0 || index >= items.length) return;

    // 현재, 이전, 다음만 유지해서 메모리 절약
    final keep = {index - 1, index, index + 1};
    for (final k in _controllers.keys.toList()) {
      if (!keep.contains(k)) {
        _controllers[k]?.dispose();
        _controllers.remove(k);
      }
    }

    // 준비 & 재생
    await _ensureController(index, items[index].sVideo);

    // ✅ 순회 스냅샷으로 안전하게 재생/일시정지
    for (final entry in _controllers.entries.toList()) {
      final c = entry.value;
      if (entry.key == index) {
        if (!c.value.isPlaying) await c.play();
      } else {
        if (c.value.isPlaying) await c.pause();
      }
    }

    // 이웃 프리로드 (루프 이후 실행)
    if (index + 1 < items.length) {
      _ensureController(index + 1, items[index + 1].sVideo);
    }
    if (index - 1 >= 0) {
      _ensureController(index - 1, items[index - 1].sVideo);
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    for (final c in _controllers.values.toList()) {
      c.setVolume(_muted ? 0 : 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortsAsync = ref.watch(shortsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: shortsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('에러: $e', style: const TextStyle(color: Colors.white))),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('영상이 없습니다', style: TextStyle(color: Colors.white)),
            );
          }

          // ✅ 첫 빌드 때 한 번만 자동 재생
          if (!_bootstrapped) {
            _bootstrapped = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _playIndex(_currentIndex, items);
            });
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: items.length,
                onPageChanged: (i) {
                  _currentIndex = i;
                  _playIndex(i, items);
                  setState(() {});
                },
                itemBuilder: (context, index) {
                  final item = items[index];
                  final c = _controllers[index];

                  return GestureDetector(
                    onTap: () {
                      if (c == null) return;
                      if (c.value.isPlaying) {
                        c.pause();
                      } else {
                        c.play();
                      }
                      setState(() {});
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 비디오 영역 (전체화면 커버)
                        if (c == null || !c.value.isInitialized)
                          const Center(child: CircularProgressIndicator())
                        else
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: c.value.size.width,
                              height: c.value.size.height,
                              child: VideoPlayer(c),
                            ),
                          ),

                        // 상하 그라데이션
                        const _TopBottomGradient(),

                        // 우측 액션 버튼
                        Positioned(
                          right: 12,
                          bottom: 80,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _IconTextButton(
                                icon: Icons.favorite_border,
                                label: '${item.sLikeCount}',
                                onTap: () {
                                  // TODO: 좋아요 Firestore 연동
                                },
                              ),
                              const SizedBox(height: 16),
                              _IconTextButton(
                                icon: Icons.share,
                                label: '공유',
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: item.sVideo));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('링크 복사됨')),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _IconTextButton(
                                icon: _muted ? Icons.volume_off : Icons.volume_up,
                                label: _muted ? '음소거' : '소리',
                                onTap: _toggleMute,
                              ),
                            ],
                          ),
                        ),

                        // 좌하단 메타 정보
                        Positioned(
                          left: 12,
                          bottom: 24,
                          right: 96,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.sTitle.isEmpty ? '제목 없음' : item.sTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.sCountry.isEmpty ? '' : item.sCountry,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // 상단 바
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: const [
                      Text(
                        'Shorts',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IconTextButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _IconTextButton({required this.icon, required this.label, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TopBottomGradient extends StatelessWidget {
  const _TopBottomGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        children: [
          Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
          const Spacer(),
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
