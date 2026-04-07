import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/drive_helper.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 데이터 확인 화면 (피험자 폴더 목록 및 클릭 시 상세 화면 이동)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
      // 폴더만 필터링
      final dirs = root.listSync().whereType<Directory>().toList();
      setState(() {
        _patients = dirs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_patients.isEmpty) return const Center(child: Text('저장된 피험자 데이터가 없습니다.'));

    return ListView.builder(
      itemCount: _patients.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (ctx, i) {
        final dir = _patients[i];
        final name = dir.path.split(Platform.pathSeparator).last;
        final fileCount = dir.listSync().whereType<File>().length;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF3E5F5),
              child: Icon(Icons.folder, color: Color(0xFF9C27B0)),
            ),
            title: Text('등록번호: $name', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('저장된 파일: $fileCount개'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PatientDetailScreen(patientDir: dir, regNo: name)),
              );
            },
          ),
        );
      },
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 피험자 파일 상세 및 미리보기 화면
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class PatientDetailScreen extends StatefulWidget {
  final Directory patientDir;
  final String regNo;

  const PatientDetailScreen({super.key, required this.patientDir, required this.regNo});

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
    final csvFile = _files.where((f) => f.path.endsWith('.csv')).firstOrNull;
    if (csvFile != null) {
      final input = await csvFile.readAsString();
      final rows = const CsvToListConverter().convert(input);
      setState(() {
        _csvData = rows;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String path) async {
    if (_currentlyPlayingPath == path && _audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.pause();
      setState(() => _currentlyPlayingPath = null);
    } else {
      await _audioPlayer.play(DeviceFileSource(path));
      setState(() => _currentlyPlayingPath = path);
      
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _currentlyPlayingPath = null);
      });
    }
  }

  Future<void> _uploadToDrive() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        ValueNotifier<String> statusMsg = ValueNotifier<String>('업로드 준비 중...');
        bool isDone = false;
        
        DriveHelper.uploadPatientFolder(
          widget.patientDir,
          widget.regNo,
          onProgress: (msg) {
            statusMsg.value = msg;
            if (msg.contains('성공:') || msg.contains('오류') || msg.contains('취소')) {
              isDone = true;
            }
          },
        ).then((_) {
            if (!isDone) statusMsg.value = '업로드 동작 수행 완료됨.';
        });

        return AlertDialog(
          title: const Text('구글 드라이브 업로드'),
          content: ValueListenableBuilder<String>(
            valueListenable: statusMsg,
            builder: (c, val, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(val),
                  const SizedBox(height: 16),
                  if (!val.contains('성공') && !val.contains('오류') && !val.contains('취소') && !val.contains('완료'))
                    const LinearProgressIndicator(color: Color(0xFF9C27B0)),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('등록번호: ${widget.regNo}'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: '구글 드라이브에 업로드',
            onPressed: _uploadToDrive,
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽: 파일 목록 (주로 녹음 파일들)
          Expanded(
            flex: 1,
            child: Container(
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
                    title: Text(fname, style: TextStyle(fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text('${(file.lengthSync() / 1024).toStringAsFixed(1)} KB'),
                    trailing: isAudio
                        ? IconButton(
                            icon: Icon(isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                                color: isPlaying ? Colors.red : const Color(0xFF9C27B0)),
                            onPressed: () => _playAudio(file.path),
                          )
                        : null,
                    tileColor: isPlaying ? const Color(0xFFFCE4EC) : null,
                  );
                },
              ),
            ),
          ),
          // 오른쪽: CSV 테이블 미리보기 영역
          Expanded(
            flex: 2,
            child: _csvData == null
                ? const Center(child: Text('CSV 결과 파일이 없습니다.', style: TextStyle(color: Colors.grey)))
                : _buildCsvTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildCsvTable() {
    if (_csvData!.isEmpty) return const Center(child: Text('데이터가 비어 있습니다.'));

    // 앞단 8줄은 헤더 정보, 중간 공백, 그 다음부터 표 데이터로 들어옴
    // 구조 처리를 단순화하여 모든 내용을 ListView와 테이블로 렌더링
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('검사 결과 요약', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF9C27B0))),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFFF3E5F5)),
            columns: _csvData!.first.map((e) => DataColumn(label: Text(e.toString(), style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            rows: _csvData!.skip(1).map((row) {
              return DataRow(
                cells: row.map((e) => DataCell(Text(e.toString()))).toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
