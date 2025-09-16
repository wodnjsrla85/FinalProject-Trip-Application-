import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/vm/shorts_provider.dart';
import 'package:video_player/video_player.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 메인 쇼츠 페이지 - 세로 스크롤로 비디오 리스트를 보여줌
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
        loading: () => _buildLoadingView(),
        error: (e, _) => _buildErrorView(e),
        data: (videos) => videos.isEmpty 
            ? _buildEmptyView() 
            : _buildVideoList(videos),
      ),
    );
  }

  // 로딩 화면
  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  // 에러 화면
  Widget _buildErrorView(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.white, size: 50),
          const SizedBox(height: 16),
          Text(
            '영상을 불러올 수 없습니다\n$error',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 비디오가 없을 때 화면
  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, color: Colors.white, size: 80),
          SizedBox(height: 16),
          Text(
            '업로드된 영상이 없습니다',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  // 비디오 리스트 화면
  Widget _buildVideoList(List videos) {
    return Stack(
      children: [
        // 세로 스크롤 비디오 페이지
        PageView.builder(
          controller: pageController,
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          onPageChanged: (index) => setState(() => currentIndex = index),
          itemBuilder: (context, index) {
            return VideoItem(
              video: videos[index],
              isCurrentPage: index == currentIndex,
            );
          },
        ),
        // 상단 타이틀
        _buildTopTitle(),
      ],
    );
  }

  // 상단 "Shorts" 제목
  Widget _buildTopTitle() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Shorts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 개별 비디오 아이템 - 한 화면에 보이는 하나의 비디오
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VideoItem extends StatefulWidget {
  final dynamic video;          // 비디오 데이터
  final bool isCurrentPage;     // 현재 화면에 보이는 비디오인지

  const VideoItem({
    super.key,
    required this.video,
    required this.isCurrentPage,
  });

  @override
  State<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<VideoItem> {
  // 비디오 재생 관련
  VideoPlayerController? controller;
  bool isPlaying = false;
  bool isLoading = true;
  bool hasError = false;

  // 좋아요 관련
  bool isLiked = false;
  int likeCount = 0;
  bool isLikeLoading = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _loadLikeStatus();
  }

  @override
  void didUpdateWidget(VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 페이지가 바뀌면 재생/일시정지 처리
    if (widget.isCurrentPage != oldWidget.isCurrentPage) {
      _handlePageChange();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────────────────
  // 비디오 초기화 및 재생 제어
  // ────────────────────────────────────────────────────────────────────────────────────────

  // 비디오 플레이어 초기화
  Future<void> _initVideo() async {
    try {
      controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.sVideo));
      await controller!.initialize();
      await controller!.setLooping(true);
      
      setState(() {
        isLoading = false;
        hasError = false;
      });

      if (widget.isCurrentPage) _play();
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  // 페이지 변경 시 재생/정지 처리
  void _handlePageChange() {
    if (controller == null) return;
    widget.isCurrentPage ? _play() : _pause();
  }

  // 재생
  void _play() async {
    if (controller != null && !controller!.value.isPlaying) {
      await controller!.play();
      setState(() => isPlaying = true);
    }
  }

  // 일시정지
  void _pause() async {
    if (controller != null && controller!.value.isPlaying) {
      await controller!.pause();
      setState(() => isPlaying = false);
    }
  }

  // 재생/일시정지 토글
  void _togglePlayPause() {
    isPlaying ? _pause() : _play();
  }

  // ────────────────────────────────────────────────────────────────────────────────────────
  // 좋아요 기능
  // ────────────────────────────────────────────────────────────────────────────────────────

  // 좋아요 상태 불러오기
  Future<void> _loadLikeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 내가 좋아요 했는지 확인
      final likeDoc = await FirebaseFirestore.instance
          .collection('likes')
          .doc('${widget.video.id}_${user.uid}')
          .get();

      // 전체 좋아요 수 확인
      final likesQuery = await FirebaseFirestore.instance
          .collection('likes')
          .where('videoId', isEqualTo: widget.video.id)
          .get();

      if (mounted) {
        setState(() {
          isLiked = likeDoc.exists;
          likeCount = likesQuery.docs.length;
        });
      }
    } catch (e) {
      // 에러 무시
    }
  }

  // 좋아요 추가/제거
  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || isLikeLoading) return;

    setState(() => isLikeLoading = true);

    try {
      final likeDocRef = FirebaseFirestore.instance
          .collection('likes')
          .doc('${widget.video.id}_${user.uid}');

      if (isLiked) {
        // 좋아요 취소
        await likeDocRef.delete();
        setState(() {
          isLiked = false;
          likeCount--;
        });
      } else {
        // 좋아요 추가
        await likeDocRef.set({
          'videoId': widget.video.id,
          'userId': user.uid,
          'userEmail': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          isLiked = true;
          likeCount++;
        });
      }

      HapticFeedback.lightImpact(); // 진동 피드백
    } catch (e) {
      _showError('좋아요 실패');
    } finally {
      setState(() => isLikeLoading = false);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────────────────
  // 링크 복사 기능
  // ────────────────────────────────────────────────────────────────────────────────────────

  Future<void> _copyLink() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.video.sVideo));
      HapticFeedback.selectionClick();
      _showSuccess('링크가 복사되었습니다');
    } catch (e) {
      _showError('복사 실패');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────────────────
  // 유틸리티 메서드
  // ────────────────────────────────────────────────────────────────────────────────────────

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────────────────
  // UI 빌드 메서드들
  // ────────────────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoPlayer(),      // 비디오 플레이어
          _buildGradients(),        // 상하단 그라데이션
          _buildVideoInfo(),        // 비디오 정보 (제목, 위치)
          _buildActionButtons(),    // 우측 액션 버튼들
          _buildPlayPauseIcon(),    // 재생/일시정지 아이콘
        ],
      ),
    );
  }

  // 비디오 플레이어
  Widget _buildVideoPlayer() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
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
              Text('비디오를 재생할 수 없습니다', style: TextStyle(color: Colors.white)),
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

  // 상하단 그라데이션 (텍스트 가독성을 위함)
  Widget _buildGradients() {
    return Column(
      children: [
        // 상단 그라데이션
        Container(
          height: 100,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
        ),
        const Spacer(),
        // 하단 그라데이션
        Container(
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }

  // 비디오 정보 (좌하단)
  Widget _buildVideoInfo() {
    return Positioned(
      left: 16,
      bottom: 80,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 비디오 제목
          Text(
            widget.video.sTitle?.isEmpty ?? true ? '제목 없음' : widget.video.sTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // 촬영 위치
          if (widget.video.sCountry?.isNotEmpty ?? false)
            Text(
              widget.video.sCountry,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
        ],
      ),
    );
  }

  // 우측 액션 버튼들
  Widget _buildActionButtons() {
    return Positioned(
      right: 16,
      bottom: 80,
      child: Column(
        children: [
          // 좋아요 버튼
          _buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: likeCount > 0 ? likeCount.toString() : '좋아요',
            color: isLiked ? Colors.red : Colors.white,
            onTap: _toggleLike,
            isLoading: isLikeLoading,
          ),
          const SizedBox(height: 16),
          // 링크 복사 버튼
          _buildActionButton(
            icon: Icons.copy,
            label: '복사',
            onTap: _copyLink,
          ),
        ],
      ),
    );
  }

  // 개별 액션 버튼
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Column(
        children: [
          // 버튼 아이콘
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(icon, color: color ?? Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          // 버튼 라벨
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 가운데 재생/일시정지 아이콘 (일시정지일 때만 표시)
  Widget _buildPlayPauseIcon() {
    return Center(
      child: AnimatedOpacity(
        opacity: !isPlaying ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
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