import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/vm/shorts_provider.dart';
import 'package:video_player/video_player.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 1. 메인 비디오 목록 페이지
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VideosPage extends ConsumerWidget {
  const VideosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortsAsync = ref.watch(shortsStreamProvider);
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "내 비디오",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: shortsAsync.when(
        data: (list) {
          final myVideos =
              list.where((video) => video.uEmail == currentUserEmail).toList();

          if (myVideos.isEmpty) {
            return const Center(
              child: Text("비디오가 없습니다",
                  style: TextStyle(color: Colors.black54)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myVideos.length,
            itemBuilder: (context, i) {
              final video = myVideos[i];
              return VideoListItem(video: video);
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.blue)),
        error: (e, _) => Center(
          child: Text("에러: $e", style: const TextStyle(color: Colors.red)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFD700),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _uploadVideo(context, ref),
      ),
    );
  }

  Future<void> _uploadVideo(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    final result = await Navigator.push<({String title, String country})>(
      context,
      MaterialPageRoute(
        builder: (_) => VideoUploadScreen(videoFile: File(file.path)),
      ),
    );
    if (result == null) return;

    try {
      await ref.read(uploadShortProvider(UploadShortParams(
        file: File(file.path),
        title: result.title,
        country: result.country,
        email: FirebaseAuth.instance.currentUser?.email,
      )).future);

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('업로드 완료!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
      }
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 2. 비디오 목록 아이템
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VideoListItem extends StatelessWidget {
  final dynamic video;
  const VideoListItem({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                url: video.sVideo,
                docId: video.id,
                title: video.sTitle,
                country: video.sCountry,
              ),
            ),
          );
        },
        leading: VideoThumbnail(url: video.sVideo),
        title: Text(video.sTitle.isEmpty ? '제목 없음' : video.sTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(video.sCountry,
            style: const TextStyle(color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black45),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 3. 썸네일
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VideoThumbnail extends StatefulWidget {
  final String url;
  const VideoThumbnail({super.key, required this.url});

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  VideoPlayerController? controller;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller!.initialize();
      if (mounted) setState(() => isReady = true);
    } catch (_) {}
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isReady && controller != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: 60, height: 60, child: VideoPlayer(controller!)),
      );
    }
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.play_arrow, color: Colors.black54),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 4. 업로드 화면
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VideoUploadScreen extends StatefulWidget {
  final File videoFile;
  const VideoUploadScreen({super.key, required this.videoFile});

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  final titleController = TextEditingController();
  final countryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("비디오 업로드",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInput("제목", controller: titleController),
            const SizedBox(height: 16),
            _buildInput("위치", controller: countryController),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(context, (
                    title: titleController.text.trim(),
                    country: countryController.text.trim(),
                  ));
                },
                child: const Text("업로드",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label,
      {required TextEditingController controller}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 5. 비디오 플레이어 화면 (수정/삭제)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String url;
  final String docId;
  final String title;
  final String country;

  const VideoPlayerScreen({
    super.key,
    required this.url,
    required this.docId,
    required this.title,
    required this.country,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late VideoPlayerController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    controller.initialize().then((_) {
      if (mounted) setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("비디오",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _editVideo(),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteVideo(),
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.blue)
            : AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFD700),
        onPressed: () {
          setState(() {
            controller.value.isPlaying ? controller.pause() : controller.play();
          });
        },
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _editVideo() async {
    final result = await showDialog<({String title, String country})>(
      context: context,
      builder: (context) => EditVideoDialog(
        initialTitle: widget.title,
        initialCountry: widget.country,
      ),
    );

    if (result == null) return;
    try {
      await ref.read(updateShortProvider({
        'docId': widget.docId,
        'title': result.title,
        'country': result.country,
      }).future);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("수정 완료")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("수정 실패: $e")));
      }
    }
  }

  Future<void> _deleteVideo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('삭제 확인',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: const Text('정말 삭제하시겠습니까?',
            style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(deleteShortProvider(widget.docId).future);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("삭제 완료")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("삭제 실패: $e")));
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 6. 수정 다이얼로그
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class EditVideoDialog extends StatefulWidget {
  final String initialTitle;
  final String initialCountry;

  const EditVideoDialog({
    super.key,
    required this.initialTitle,
    required this.initialCountry,
  });

  @override
  State<EditVideoDialog> createState() => _EditVideoDialogState();
}

class _EditVideoDialogState extends State<EditVideoDialog> {
  late TextEditingController titleController;
  late TextEditingController countryController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle);
    countryController = TextEditingController(text: widget.initialCountry);
  }

  @override
  void dispose() {
    titleController.dispose();
    countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('비디오 수정',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInput("제목", controller: titleController),
          const SizedBox(height: 16),
          _buildInput("위치", controller: countryController),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소', style: TextStyle(color: Colors.black)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, (
              title: titleController.text.trim(),
              country: countryController.text.trim(),
            ));
          },
          child: const Text('수정', style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }

  Widget _buildInput(String label,
      {required TextEditingController controller}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }
}
