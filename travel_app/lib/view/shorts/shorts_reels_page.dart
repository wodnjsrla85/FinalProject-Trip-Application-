import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/vm/shorts_provider.dart';
import 'package:video_player/video_player.dart';

class ShortsReelsPage extends ConsumerStatefulWidget {
  const ShortsReelsPage({super.key});

  @override
  ConsumerState<ShortsReelsPage> createState() => _ShortsReelsPageState();
}

class _ShortsReelsPageState extends ConsumerState<ShortsReelsPage> {
  PageController pageController = PageController();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final shortsAsync = ref.watch(shortsStreamProvider);

    return Scaffold(
  backgroundColor: Colors.black,
  body: shortsAsync.when(
    loading: () => const Center(
      child: CircularProgressIndicator(color: Colors.white),
    ),
    error: (e, _) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.white, size: 50),
          const SizedBox(height: 16),
          Text(
            '영상을 불러올 수 없습니다\n$e',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
    data: (videos) {
      if (videos.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, 
                   color: Colors.white, size: 80),
              SizedBox(height: 16),
              Text(
                '업로드된 영상이 없습니다',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        );
      }

      return Stack(  // Stack으로 감싸기
        children: [
          PageView.builder(
            controller: pageController,
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            onPageChanged: (index) {
              setState(() => currentIndex = index);
            },
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoItem(
                video: video,
                isCurrentPage: index == currentIndex,
              );
            },
          ),
          // 상단 "Shorts" 텍스트
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 개별 비디오 아이템
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VideoItem extends StatefulWidget {
  final dynamic video;
  final bool isCurrentPage;

  const VideoItem({
    super.key,
    required this.video,
    required this.isCurrentPage,
  });

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  VideoPlayerController? controller;
  bool isPlaying = false;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentPage != oldWidget.isCurrentPage) {
      _handlePageChange();
    }
  }

  Future<void> _initVideo() async {
    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.sVideo),
      );
      
      await controller!.initialize();
      await controller!.setLooping(true);
      
      setState(() {
        isLoading = false;
        hasError = false;
      });

      // 현재 페이지면 자동 재생
      if (widget.isCurrentPage) {
        _play();
      }
    } catch (e) {
      print('비디오 로드 에러: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  void _handlePageChange() {
    if (controller == null) return;
    
    if (widget.isCurrentPage) {
      _play();
    } else {
      _pause();
    }
  }

  void _play() async {
    if (controller != null && !controller!.value.isPlaying) {
      await controller!.play();
      setState(() => isPlaying = true);
    }
  }

  void _pause() async {
    if (controller != null && controller!.value.isPlaying) {
      await controller!.pause();
      setState(() => isPlaying = false);
    }
  }

  void _togglePlayPause() {
    if (isPlaying) {
      _pause();
    } else {
      _play();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 비디오 화면
          _buildVideoPlayer(),
          
          // 상단 그라데이션
          _buildTopGradient(),
          
          // 하단 그라데이션
          _buildBottomGradient(),
          
          // 비디오 정보
          _buildVideoInfo(),
          
          // 우측 버튼들
          _buildSideButtons(),
          
          // 재생/일시정지 아이콘
          if (!isLoading && !hasError)
            _buildPlayPauseIcon(),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    if (hasError || controller == null) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 50),
              SizedBox(height: 10),
              Text(
                '비디오를 재생할 수 없습니다',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller!.value.size.width,
        height: controller!.value.size.height,
        child: VideoPlayer(controller!),
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 100,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 200,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Positioned(
      left: 16,
      bottom: 80,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.sTitle.isEmpty ? '제목 없음' : widget.video.sTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (widget.video.sCountry.isNotEmpty)
            Text(
              widget.video.sCountry,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSideButtons() {
    return Positioned(
      right: 16,
      bottom: 80,
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.favorite_border,
            label: '좋아요',
            onTap: () {
              // TODO: 좋아요 기능
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('좋아요!')),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.share,
            label: '공유',
            onTap: () {
              // TODO: 공유 기능
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('공유하기')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseIcon() {
    return Center(
      child: AnimatedOpacity(
        opacity: !isPlaying ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }
}