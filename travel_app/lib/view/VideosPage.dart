import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_app/vm/shorts_provider.dart';
import 'package:video_player/video_player.dart';

// 모델/프로바이더
import 'package:travel_app/Model/ShortMeta.dart'; // ShortMeta
       // shortsStreamProvider, uploadShortProvider, uploadProgressProvider

class VideosPage extends ConsumerWidget {
  const VideosPage({super.key});

  Future<File?> _pickVideo() async {
    final x = await ImagePicker().pickVideo(source: ImageSource.gallery);
    return x == null ? null : File(x.path);
  }

  Future<({String? title, String? country})?> _askMeta(
      BuildContext context) async {
    final titleC = TextEditingController();
    final countryC = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16, bottom: bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('메타데이터 입력', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: titleC,
                decoration: const InputDecoration(
                  labelText: '제목 (STitle)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countryC,
                decoration: const InputDecoration(
                  labelText: '나라 (SCountry)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (titleC.text.trim().isEmpty ||
                            countryC.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('제목과 나라를 입력해 주세요')),
                          );
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('확인'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (ok != true) return null;
    return (title: titleC.text.trim(), country: countryC.text.trim());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortsAsync = ref.watch(shortsStreamProvider);      // ✅ shorts 컬렉션 구독
    final uploadPct   = ref.watch(uploadProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shorts')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.cloud_upload),
        label: const Text('업로드'),
        onPressed: () async {
          final file = await _pickVideo();
          if (file == null) return;

          final meta = await _askMeta(context);
          if (meta == null) return;

          // ⬆️ 업로드 + Firestore 저장 (SDate는 서버시간으로 자동, providers에서 처리)
          ref.read(uploadShortProvider(
            UploadShortParams(
              file: file,
              title: meta.title!,
              country: meta.country!,
              // docId: '기존 문서 갱신하려면 넣기(옵션)'
            ),
          ).future).then((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('업로드 완료')),
              );
            }
          }).catchError((e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('업로드 실패: $e')),
            );
          });
        },
      ),
      body: Column(
        children: [
          if (uploadPct != null) LinearProgressIndicator(value: uploadPct.clamp(0, 1)),
          Expanded(
            child: shortsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('영상이 없습니다.'));
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final v = list[i]; // ShortMeta
                    final created = v.sDate?.toLocal().toString().split('.').first ?? '';
                    return ListTile(
                      leading: const Icon(Icons.movie),
                      title: Text(
                        v.sTitle.isEmpty ? '제목 없음' : v.sTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('${v.sCountry} • $created'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => VideoPlayerScreen(url: v.sVideo)),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: v.sVideo));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('URL 복사됨')),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('에러: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  const VideoPlayerScreen({super.key, required this.url});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerController _c;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _c.value.isInitialized;
    return Scaffold(
      appBar: AppBar(title: const Text('재생')),
      body: Center(
        child: ready
            ? AspectRatio(aspectRatio: _c.value.aspectRatio, child: VideoPlayer(_c))
            : const CircularProgressIndicator(),
      ),
      bottomNavigationBar: ready
          ? SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_c.value.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      _c.value.isPlaying ? _c.pause() : _c.play();
                      setState(() {});
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: () async {
                      await _c.pause();
                      await _c.seekTo(Duration.zero);
                      setState(() {});
                    },
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
