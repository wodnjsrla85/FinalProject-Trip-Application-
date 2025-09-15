import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/vm/shorts_provider.dart';
import 'package:video_player/video_player.dart';

class VideosPage extends ConsumerWidget {
  const VideosPage({super.key});

  Future<File?> _pickVideo() async {
    final x = await ImagePicker().pickVideo(source: ImageSource.gallery);
    return x == null ? null : File(x.path);
  }

  Future<({String? title, String? country})?> _showVideoPreviewAndMeta(
    BuildContext context, 
    File videoFile
  ) async {
    return await Navigator.push<({String? title, String? country})>(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPreviewAndMetaScreen(videoFile: videoFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortsAsync = ref.watch(shortsStreamProvider);
    final uploadPct = ref.watch(uploadProgressProvider);
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A202C),
              Color(0xFF2D3748),
              Color(0xFF4A5568),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 헤더 - 패딩 늘림
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF667EEA),
                            Color(0xFF764BA2),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF667EEA).withValues(alpha: 0.3),
                            spreadRadius: 0,
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.video_library,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "My Videos",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Your uploaded content",
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFA0AEC0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 업로드 진행률
              if (uploadPct != null)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  child: LinearProgressIndicator(
                    value: uploadPct.clamp(0, 1),
                    backgroundColor: Color(0xFF4A5568),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                  ),
                ),

              // 메인 컨텐츠 - 마진 조정
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        spreadRadius: 0,
                        blurRadius: 25,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: shortsAsync.when(
                      data: (list) {
                        final myVideos = list.where((video) {
                          return video.uEmail == currentUserEmail;
                        }).toList();

                        if (myVideos.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF667EEA).withValues(alpha: 0.15),
                                        Color(0xFF764BA2).withValues(alpha: 0.15),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.video_library_outlined,
                                    size: 44,
                                    color: Color(0xFF667EEA),
                                  ),
                                ),
                                SizedBox(height: 28),
                                Text(
                                  'No videos yet',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3748),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 40),
                                  child: Text(
                                    'Upload your first video to get started!',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF718096),
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: EdgeInsets.all(20),
                          itemCount: myVideos.length,
                          separatorBuilder: (_, __) => SizedBox(height: 16),
                          itemBuilder: (context, i) {
                            final v = myVideos[i];
                            final created = v.sDate?.toLocal().toString().split('.').first ?? '';
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF667EEA).withValues(alpha: 0.08),
                                    spreadRadius: 0,
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => VideoPlayerScreen(url: v.sVideo),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        // 비디오 썸네일
                                        VideoThumbnail(
                                          url: v.sVideo,
                                          width: 68,
                                          height: 68,
                                        ),
                                        
                                        SizedBox(width: 20),
                                        
                                        // 비디오 정보
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                v.sTitle.isEmpty ? 'Untitled Video' : v.sTitle,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF2D3748),
                                                  letterSpacing: -0.2,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on_outlined,
                                                    size: 16,
                                                    color: Color(0xFF667EEA),
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    v.sCountry,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      color: Color(0xFF667EEA),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                created,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF718096),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // 액션 버튼들
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: Color(0xFFF0F4F8),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.copy_outlined,
                                                  size: 20,
                                                  color: Color(0xFF667EEA),
                                                ),
                                                onPressed: () async {
                                                  await Clipboard.setData(
                                                    ClipboardData(text: v.sVideo),
                                                  );
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('URL copied!'),
                                                        backgroundColor: Color(0xFF48BB78),
                                                        behavior: SnackBarBehavior.floating,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: Color(0xFF48BB78),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF667EEA),
                          strokeWidth: 3,
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Color(0xFFE53E3E).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: 36,
                                color: Color(0xFFE53E3E),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Something went wrong',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3748),
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Error: $e',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF718096),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF667EEA).withValues(alpha: 0.4),
              spreadRadius: 0,
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 22),
          label: Text(
            'Upload',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          onPressed: () async {
            final file = await _pickVideo();
            if (file == null) return;

            if (!context.mounted) return;

            final result = await _showVideoPreviewAndMeta(context, file);
            if (result == null) return;

            ref
                .read(
                  uploadShortProvider(
                    UploadShortParams(
                      file: file,
                      title: result.title!,
                      country: result.country!,
                      email: currentUserEmail,
                    ),
                  ).future,
                )
                .then((_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Upload completed!'),
                        backgroundColor: Color(0xFF48BB78),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                })
                .catchError((e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Upload failed: $e'),
                        backgroundColor: Color(0xFFE53E3E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                });
          },
        ),
      ),
    );
  }
}

// 비디오 썸네일 위젯
class VideoThumbnail extends StatefulWidget {
  final String url;
  final double width;
  final double height;

  const VideoThumbnail({
    super.key,
    required this.url,
    required this.width,
    required this.height,
  });

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeThumbnail();
  }

  Future<void> _initializeThumbnail() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667EEA).withValues(alpha: 0.25),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 썸네일 또는 기본 배경
            if (_isInitialized && !_hasError && _controller != null)
              Container(
                width: widget.width,
                height: widget.height,
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                    ],
                  ),
                ),
                child: _hasError
                    ? Icon(
                        Icons.error_outline,
                        size: 24,
                        color: Colors.white.withValues(alpha: 0.8),
                      )
                    : Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
              ),
            
            // 재생 버튼 오버레이
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      size: 16,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 영상 미리보기 + 메타데이터 입력 통합 화면
class VideoPreviewAndMetaScreen extends StatefulWidget {
  final File videoFile;

  const VideoPreviewAndMetaScreen({super.key, required this.videoFile});

  @override
  State<VideoPreviewAndMetaScreen> createState() => _VideoPreviewAndMetaScreenState();
}

class _VideoPreviewAndMetaScreenState extends State<VideoPreviewAndMetaScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  final titleController = TextEditingController();
  final countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('영상을 불러올 수 없습니다: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    titleController.dispose();
    countryController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667EEA).withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF2D3748),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: Color(0xFF667EEA),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Color(0xFFA0AEC0),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: Color(0xFF667EEA),
            size: 22,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Color(0xFF667EEA),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A202C),
              Color(0xFF2D3748),
              Color(0xFF4A5568),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 헤더
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Upload Video",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Preview and add details",
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFFA0AEC0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 메인 컨텐츠
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        spreadRadius: 0,
                        blurRadius: 25,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // 영상 미리보기 섹션
                        Container(
                          height: 220,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                spreadRadius: 0,
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _isInitialized
                                ? AspectRatio(
                                    aspectRatio: _controller.value.aspectRatio,
                                    child: VideoPlayer(_controller),
                                  )
                                : Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF667EEA),
                                      strokeWidth: 3,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // 비디오 컨트롤
                        if (_isInitialized)
                          Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF667EEA),
                                        Color(0xFF764BA2),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF667EEA).withValues(alpha: 0.3),
                                        spreadRadius: 0,
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _controller.value.isPlaying
                                            ? _controller.pause()
                                            : _controller.play();
                                      });
                                    },
                                    icon: Icon(
                                      _controller.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 20),
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE2E8F0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () async {
                                      await _controller.pause();
                                      await _controller.seekTo(Duration.zero);
                                      setState(() {});
                                    },
                                    icon: Icon(
                                      Icons.replay,
                                      color: Color(0xFF667EEA),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: 36),

                        // 메타데이터 입력 섹션
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Video Details",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3748),
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 24),

                            _buildTextField(
                              controller: titleController,
                              label: "Video Title",
                              hint: "Enter a catchy title",
                              icon: Icons.title_outlined,
                            ),

                            _buildTextField(
                              controller: countryController,
                              label: "Location",
                              hint: "Where was this filmed?",
                              icon: Icons.location_on_outlined,
                            ),

                            SizedBox(height: 28),

                            // 업로드 버튼
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFF667EEA),
                                    Color(0xFF764BA2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF667EEA).withValues(alpha: 0.4),
                                    spreadRadius: 0,
                                    blurRadius: 15,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (titleController.text.trim().isEmpty ||
                                      countryController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Please fill in all fields"),
                                        backgroundColor: Color(0xFFE53E3E),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.pop(
                                    context,
                                    (
                                      title: titleController.text.trim(),
                                      country: countryController.text.trim()
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload_outlined,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Upload Video",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            // 취소 버튼
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Color(0xFF718096),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// 개선된 VideoPlayerScreen
class VideoPlayerScreen extends StatefulWidget {
  final String url;
  const VideoPlayerScreen({super.key, required this.url});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _showControls = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    
    // 3초 후 컨트롤 숨기기
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 비디오 플레이어
          Center(
            child: _isLoading
                ? Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF667EEA),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Loading video...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: _toggleControls,
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
          ),

          // 상단 컨트롤 바 (뒤로 가기)
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          'Video Player',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        SizedBox(width: 44), // 균형을 위한 공간
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 하단 컨트롤 바
          if (_showControls && !_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 진행률 바
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: Color(0xFF667EEA),
                            bufferedColor: Colors.grey.withValues(alpha: 0.3),
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // 컨트롤 버튼들
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 되감기 버튼
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  final currentPosition = _controller.value.position;
                                  final newPosition = currentPosition - Duration(seconds: 10);
                                  await _controller.seekTo(
                                    newPosition < Duration.zero ? Duration.zero : newPosition,
                                  );
                                },
                                icon: Icon(
                                  Icons.replay_10,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            
                            SizedBox(width: 20),
                            
                            // 재생/일시정지 버튼
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFF667EEA),
                                    Color(0xFF764BA2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF667EEA).withValues(alpha: 0.4),
                                    spreadRadius: 0,
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _controller.value.isPlaying
                                        ? _controller.pause()
                                        : _controller.play();
                                  });
                                  _hideControlsAfterDelay();
                                },
                                icon: Icon(
                                  _controller.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                            
                            SizedBox(width: 20),
                            
                            // 빨리감기 버튼
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  final currentPosition = _controller.value.position;
                                  final duration = _controller.value.duration;
                                  final newPosition = currentPosition + Duration(seconds: 10);
                                  await _controller.seekTo(
                                    newPosition > duration ? duration : newPosition,
                                  );
                                },
                                icon: Icon(
                                  Icons.forward_10,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 12),
                        
                        // 추가 컨트롤 버튼들
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 처음으로 버튼
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  await _controller.pause();
                                  await _controller.seekTo(Duration.zero);
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.restart_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            
                            // 음소거 버튼
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _controller.setVolume(
                                      _controller.value.volume > 0 ? 0.0 : 1.0,
                                    );
                                  });
                                },
                                icon: Icon(
                                  _controller.value.volume > 0
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            
                            // 전체화면 버튼 (placeholder)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  // 전체화면 기능 구현 가능
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Fullscreen feature'),
                                      backgroundColor: Color(0xFF667EEA),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 중앙 재생 버튼 (비디오가 멈춰있을 때)
          if (_showControls && !_isLoading && !_controller.value.isPlaying)
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF667EEA).withValues(alpha: 0.9),
                      Color(0xFF764BA2).withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF667EEA).withValues(alpha: 0.4),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    _controller.play();
                    setState(() {});
                    _hideControlsAfterDelay();
                  },
                  icon: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}