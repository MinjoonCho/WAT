import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

// --- 폴더 기반 데이터 관리 ---
class FolderManagerScreen extends StatefulWidget {
  const FolderManagerScreen({super.key});

  @override
  State<FolderManagerScreen> createState() => _FolderManagerScreenState();
}

class _FolderManagerScreenState extends State<FolderManagerScreen> {
  List<Directory> subjectFolders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final dir = await getApplicationDocumentsDirectory();
    setState(() => subjectFolders = dir.listSync().whereType<Directory>().toList());
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: subjectFolders.length,
      itemBuilder: (ctx, i) {
        final folder = subjectFolders[i];
        final name = folder.path.split('/').last;
        return ListTile(
          leading: const Icon(Icons.folder, color: Colors.amber),
          title: Text("등록번호: $name"),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FileViewer(dir: folder)),
          ),
        );
      },
    );
  }
}

// --- 파일 뷰어 ---
class FileViewer extends StatelessWidget {
  final Directory dir;
  const FileViewer({super.key, required this.dir});

  @override
  Widget build(BuildContext context) {
    final files = dir.listSync();
    final player = AudioPlayer();
    return Scaffold(
      appBar: AppBar(title: Text(dir.path.split('/').last)),
      body: ListView.builder(
        itemCount: files.length,
        itemBuilder: (ctx, i) {
          final f = files[i];
          final name = f.path.split('/').last;
          return ListTile(
            title: Text(name),
            onTap: () async {
              if (name.endsWith('.m4a')) {
                await player.play(DeviceFileSource(f.path));
              } else {
                final content = await File(f.path).readAsString();
                showDialog(
                  context: ctx,
                  builder: (_) => AlertDialog(
                    content: SingleChildScrollView(child: Text(content)),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
