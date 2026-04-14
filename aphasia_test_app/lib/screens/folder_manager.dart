import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FolderManagerScreen extends StatefulWidget {
  const FolderManagerScreen({super.key});

  @override
  State<FolderManagerScreen> createState() => _FolderManagerScreenState();
}

class _FolderManagerScreenState extends State<FolderManagerScreen> {
  List<Directory> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final root = await getApplicationDocumentsDirectory();
      final dirs = root.listSync().whereType<Directory>().toList();
      setState(() {
        _patients = dirs;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('데이터 확인')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? const Center(child: Text('저장된 환자 데이터가 없습니다.'))
              : ListView.builder(
                  itemCount: _patients.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (ctx, i) {
                    final dir = _patients[i];
                    final name = dir.path.split(Platform.pathSeparator).last;
                    final fileCount = dir.listSync().whereType<File>().length;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF3E5F5),
                          child: Icon(Icons.folder, color: Color(0xFF9C27B0)),
                        ),
                        title: Text(
                          '등록번호: $name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('저장된 파일: ${fileCount}개'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientDetailScreen(
                                patientDir: dir,
                                regNo: name,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class PatientDetailScreen extends StatefulWidget {
  final Directory patientDir;
  final String regNo;

  const PatientDetailScreen({
    super.key,
    required this.patientDir,
    required this.regNo,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late List<File> _files;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingPath;
  List<List<dynamic>>? _csvData;

  @override
  void initState() {
    super.initState();
    _refreshFiles();
    _loadCsvIfExists();
  }

  void _refreshFiles() {
    _files = widget.patientDir.listSync().whereType<File>().toList();
  }

  Future<void> _loadCsvIfExists() async {
    File? csvFile;
    for (final file in _files) {
      if (file.path.endsWith('.csv')) {
        csvFile = file;
        break;
      }
    }

    if (csvFile == null) return;

    final input = await csvFile.readAsString();
    final rows = const CsvToListConverter().convert(input);
    if (!mounted) return;
    setState(() => _csvData = rows);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String path) async {
    if (_currentlyPlayingPath == path &&
        _audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.pause();
      if (!mounted) return;
      setState(() => _currentlyPlayingPath = null);
      return;
    }

    await _audioPlayer.play(DeviceFileSource(path));
    if (!mounted) return;
    setState(() => _currentlyPlayingPath = path);

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _currentlyPlayingPath = null);
    });
  }

  Future<void> _sharePatientFolder() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final statusMsg = ValueNotifier<String>('압축 파일을 준비 중입니다.');

        Future(() async {
          try {
            final tempDir = await getTemporaryDirectory();
            final zipPath =
                '${tempDir.path}${Platform.pathSeparator}WAT_${widget.regNo}.zip';
            final encoder = ZipFileEncoder();
            encoder.create(zipPath);

            final entries = widget.patientDir.listSync(recursive: true);
            for (final entry in entries.whereType<File>()) {
              final relativePath =
                  entry.path.substring(widget.patientDir.path.length + 1);
              statusMsg.value = '압축 중: $relativePath';
              encoder.addFile(entry, relativePath);
            }
            encoder.close();

            statusMsg.value = '공유 화면을 여는 중입니다.';
            await SharePlus.instance.share(
              ShareParams(
                files: [XFile(zipPath)],
                text: 'WAT 검사 데이터 ${widget.regNo}',
                subject: 'WAT_${widget.regNo}.zip',
              ),
            );
            statusMsg.value = '공유가 완료되었습니다.';
          } catch (e) {
            statusMsg.value = '공유 준비 중 오류가 발생했습니다: $e';
          }
        });

        return AlertDialog(
          title: const Text('압축 후 공유'),
          content: ValueListenableBuilder<String>(
            valueListenable: statusMsg,
            builder: (c, val, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(val),
                  const SizedBox(height: 16),
                  if (!val.contains('완료') && !val.contains('오류'))
                    const LinearProgressIndicator(color: Color(0xFF9C27B0)),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('등록번호: ${widget.regNo}'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'zip으로 압축 후 공유',
            onPressed: _sharePatientFolder,
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Colors.black12)),
              ),
              child: ListView.builder(
                itemCount: _files.length,
                itemBuilder: (ctx, i) {
                  final file = _files[i];
                  final fname = file.path.split(Platform.pathSeparator).last;
                  final isAudio = fname.endsWith('.m4a');
                  final isPlaying = _currentlyPlayingPath == file.path;

                  return ListTile(
                    leading: Icon(
                      isAudio ? Icons.audiotrack : Icons.table_chart,
                      color: isPlaying ? Colors.red : const Color(0xFF9C27B0),
                    ),
                    title: Text(
                      fname,
                      style: TextStyle(
                        fontWeight:
                            isPlaying ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                    ),
                    trailing: isAudio
                        ? IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.stop_circle
                                  : Icons.play_circle_fill,
                              color: isPlaying
                                  ? Colors.red
                                  : const Color(0xFF9C27B0),
                            ),
                            onPressed: () => _playAudio(file.path),
                          )
                        : null,
                    tileColor: isPlaying ? const Color(0xFFFCE4EC) : null,
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: _csvData == null
                  ? const Center(
                      child: Text(
                        'CSV 결과 파일이 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : _buildCsvTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCsvTable() {
    if (_csvData!.isEmpty) {
      return const Center(child: Text('데이터가 비어 있습니다.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '검사 결과 요약',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9C27B0),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.resolveWith(
              (states) => const Color(0xFFF3E5F5),
            ),
            columns: _csvData!
                .first
                .map(
                  (e) => DataColumn(
                    label: Text(
                      e.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
                .toList(),
            rows: _csvData!
                .skip(1)
                .map(
                  (row) => DataRow(
                    cells: row.map((e) => DataCell(Text(e.toString()))).toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
