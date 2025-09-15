import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/vm/shorts_provider.dart';
import 'package:video_player/video_player.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 1. 메인 비디오 목록 페이지
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VideosPage extends ConsumerWidget {
  const VideosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortsAsync = ref.watch(shortsStreamProvider);
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(title: const Text("내 비디오")),
      body: shortsAsync.when(
        data: (list) {
          final myVideos = list
              .where((video) => video.uEmail == currentUserEmail)
              .toList();

          if (myVideos.isEmpty) {
            return const Center(child: Text("비디오가 없습니다"));
          }

          return ListView.builder(
            itemCount: myVideos.length,
            itemBuilder: (context, i) {
              final video = myVideos[i];
              return VideoListItem(video: video);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("에러: $e")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _uploadVideo(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 비디오 업로드
  Future<void> _uploadVideo(BuildContext context, WidgetRef ref) async {
    // 1. 비디오 선택
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null) return;

    // 2. 정보 입력
    final result = await Navigator.push<({String title, String country})>(
      context,
      MaterialPageRoute(
        builder: (_) => VideoUploadScreen(videoFile: File(file.path)),
      ),
    );
    if (result == null) return;

    // 3. 업로드
    try {
      await ref.read(uploadShortProvider(UploadShortParams(
        file: File(file.path),
        title: result.title,
        country: result.country,
        email: FirebaseAuth.instance.currentUser?.email,
      )).future);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('업로드 완료!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 실패: $e')),
        );
      }
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 2. 비디오 목록 아이템
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VideoListItem extends StatelessWidget {
  final dynamic video; // ShortsModel
  
  const VideoListItem({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: VideoThumbnail(url: video.sVideo),
        title: Text(video.sTitle.isEmpty ? '제목 없음' : video.sTitle),
        subtitle: Text(video.sCountry),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                url: video.sVideo, 
                docId: video.id,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 3. 썸네일
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
    } catch (e) {
      // 에러 무시
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isReady && controller != null) {
      return SizedBox(
        width: 60,
        height: 60,
        child: VideoPlayer(controller!),
      );
    }
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[300],
      child: const Icon(Icons.play_arrow),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 4. 업로드 화면
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
      appBar: AppBar(title: const Text("비디오 업로드")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "제목"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: countryController,
              decoration: const InputDecoration(labelText: "위치"),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, (
                  title: titleController.text.trim(),
                  country: countryController.text.trim(),
                ));
              },
              child: const Text("업로드"),
            ),
          ],
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 5. 비디오 플레이어 화면 (수정/삭제)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String url;
  final String docId;
  
  const VideoPlayerScreen({super.key, required this.url, required this.docId});

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
      appBar: AppBar(
        title: const Text("비디오"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
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
            ? const CircularProgressIndicator()
            : AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            controller.value.isPlaying ? controller.pause() : controller.play();
          });
        },
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  // 수정
  Future<void> _editVideo() async {
    final result = await showDialog<({String title, String country})>(
      context: context,
      builder: (context) => EditVideoDialog(docId: widget.docId),
    );

    if (result == null) return;

    try {
      await ref.read(updateShortProvider({
        'docId': widget.docId,
        'title': result.title,
        'country': result.country,
      }).future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("수정 완료")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("수정 실패: $e")),
        );
      }
    }
  }

  // 삭제
  Future<void> _deleteVideo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("삭제 완료")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("삭제 실패: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 6. 수정 다이얼로그
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class EditVideoDialog extends StatefulWidget {
  final String docId;
  
  const EditVideoDialog({super.key, required this.docId});

  @override
  State<EditVideoDialog> createState() => _EditVideoDialogState();
}

class _EditVideoDialogState extends State<EditVideoDialog> {
  final titleController = TextEditingController();
  final countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  // 현재 데이터 불러오기
  Future<void> _loadCurrentData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shorts')
          .doc(widget.docId)
          .get();
      
      if (doc.exists && mounted) {
        final data = doc.data()!;
        titleController.text = data['STitle'] ?? '';
        countryController.text = data['SCountry'] ?? '';
        setState(() {});
      }
    } catch (e) {
      // 에러 무시
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('비디오 수정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: '제목'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: countryController,
            decoration: const InputDecoration(labelText: '위치'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, (
              title: titleController.text.trim(),
              country: countryController.text.trim(),
            ));
          },
          child: const Text('수정'),
        ),
      ],
    );
  }
}