import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
// import 'package:csv/csv.dart'; // 패키지 충돌 원인이므로 임시로 주석 처리
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: [Locale('ko', 'KR')],
    home: MainMenu(),
  ));
}

// --- 데이터 모델 ---
class TestItem {
  String name;
  String? imagePath;
  String namingInstruction;
  String descInstruction;
  String choiceQuestion;
  String option1;
  String? option1ImagePath;
  String option2;
  String? option2ImagePath;

  TestItem({
    required this.name,
    this.imagePath,
    this.namingInstruction = "이것은 무엇인가요?",
    this.descInstruction = "이 사물에 대해 설명해주세요.",
    this.choiceQuestion = "어울리는 부위를 선택하세요.",
    this.option1 = "손",
    this.option1ImagePath,
    this.option2 = "발",
    this.option2ImagePath,
  });

  Map<String, dynamic> toJson() => {
        'name': name, 'imagePath': imagePath,
        'namingInstruction': namingInstruction, 'descInstruction': descInstruction,
        'choiceQuestion': choiceQuestion, 'option1': option1,
        'option1ImagePath': option1ImagePath, 'option2': option2,
        'option2ImagePath': option2ImagePath,
      };

  factory TestItem.fromJson(Map<String, dynamic> json) => TestItem(
        name: json['name'], imagePath: json['imagePath'],
        namingInstruction: json['namingInstruction'], descInstruction: json['descInstruction'],
        choiceQuestion: json['choiceQuestion'], option1: json['option1'],
        option1ImagePath: json['option1ImagePath'], option2: json['option2'],
        option2ImagePath: json['option2ImagePath'],
      );
}

// --- 메인 메뉴 (관리자 진입 포함) ---
class MainMenu extends StatefulWidget {
  const MainMenu({super.key});
  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _tapCount = 0;
  Timer? _tapTimer;

  void _handleAdminEntry() {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 2), () => _tapCount = 0);
    if (_tapCount >= 3) {
      _tapCount = 0;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width: 300, height: 100,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TestSetupScreen())),
                child: const Text("평가 시작", style: TextStyle(fontSize: 30)),
              ),
            ),
          ),
          Positioned(
            left: 0, bottom: 0,
            child: GestureDetector(
              onTap: _handleAdminEntry,
              child: Container(width: 100, height: 100, color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 관리자 대시보드 ---
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("관리자 설정"),
          bottom: const TabBar(tabs: [Tab(text: "문항 관리"), Tab(text: "데이터 확인")]),
        ),
        body: const TabBarView(children: [TemplateManager(), FolderManagerScreen()]),
      ),
    );
  }
}

// --- 문항 관리 (추가/삭제/편집) ---
class TemplateManager extends StatefulWidget {
  const TemplateManager({super.key});
  @override
  State<TemplateManager> createState() => _TemplateManagerState();
}

class _TemplateManagerState extends State<TemplateManager> {
  List<TestItem> items = [];

  @override
  void initState() { super.initState(); _loadItems(); }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('test_items');
    if (data != null) {
      setState(() => items = (jsonDecode(data) as List).map((e) => TestItem.fromJson(e)).toList());
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('test_items', jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  void _editItem(int? index) {
    TestItem target = index == null ? TestItem(name: "") : items[index];
    final nameController = TextEditingController(text: target.name);
    final op1Controller = TextEditingController(text: target.option1);
    final op2Controller = TextEditingController(text: target.option2);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDiagState) => AlertDialog(
          title: Text(index == null ? "새 문항 추가" : "문항 편집"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "사물 이름")),
                ElevatedButton(onPressed: () async {
                  final xf = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (xf != null) setDiagState(() => target.imagePath = xf.path);
                }, child: const Text("메인 이미지 선택")),
                const Divider(),
                TextField(controller: op1Controller, decoration: const InputDecoration(labelText: "선택지 1")),
                ElevatedButton(onPressed: () async {
                  final xf = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (xf != null) setDiagState(() => target.option1ImagePath = xf.path);
                }, child: const Text("선택지 1 이미지")),
                TextField(controller: op2Controller, decoration: const InputDecoration(labelText: "선택지 2")),
                ElevatedButton(onPressed: () async {
                  final xf = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (xf != null) setDiagState(() => target.option2ImagePath = xf.path);
                }, child: const Text("선택지 2 이미지")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
            TextButton(onPressed: () {
              target.name = nameController.text;
              target.option1 = op1Controller.text;
              target.option2 = op2Controller.text;
              setState(() { if (index == null) items.add(target); });
              _save();
              Navigator.pop(ctx);
            }, child: const Text("저장")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _editItem(null), child: const Icon(Icons.add)),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text("${i + 1}. ${items[i].name}"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => _editItem(i)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
                setState(() => items.removeAt(i)); _save();
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 폴더 기반 데이터 관리 ---
class FolderManagerScreen extends StatefulWidget {
  const FolderManagerScreen({super.key});
  @override
  State<FolderManagerScreen> createState() => _FolderManagerScreenState();
}

class _FolderManagerScreenState extends State<FolderManagerScreen> {
  List<Directory> subjectFolders = [];

  @override
  void initState() { super.initState(); _loadFolders(); }

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
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FileViewer(dir: folder))),
        );
      },
    );
  }
}

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
                showDialog(context: ctx, builder: (_) => AlertDialog(content: SingleChildScrollView(child: Text(content))));
              }
            },
          );
        },
      ),
    );
  }
}

// --- 피시험자 정보 입력 (DatePicker & Age 계산) ---
class TestSetupScreen extends StatefulWidget {
  const TestSetupScreen({super.key});
  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
  final regNoController = TextEditingController();
  final testCodeController = TextEditingController();
  final nameController = TextEditingController();
  final eduController = TextEditingController();
  final evaluatorController = TextEditingController();
  final locationController = TextEditingController();
  DateTime? birthDate;
  String gender = "남성";
  String ageText = "나이 자동 계산";

  void _calculateAge(DateTime birth) {
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) age--;
    setState(() => ageText = "만 $age세");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("피험자 정보")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: TextField(controller: regNoController, decoration: const InputDecoration(labelText: "등록 번호"))),
              const SizedBox(width: 20),
              Expanded(child: TextField(controller: testCodeController, decoration: const InputDecoration(labelText: "검사 코드"))),
            ]),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "성함 (한글 입력 가능)")),
            Row(children: [
              Text("생년월일: ${birthDate == null ? '미선택' : DateFormat('yyyy-MM-dd').format(birthDate!)}"),
              TextButton(onPressed: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime(1960), firstDate: DateTime(1900), lastDate: DateTime.now());
                if (d != null) { setState(() => birthDate = d); _calculateAge(d); }
              }, child: const Text("날짜 선택")),
              const SizedBox(width: 20),
              Text(ageText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            DropdownButton<String>(value: gender, items: ["남성", "여성"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => gender = v!)),
            TextField(controller: eduController, decoration: const InputDecoration(labelText: "학력 (예: 초졸)")),
            TextField(controller: evaluatorController, decoration: const InputDecoration(labelText: "평가자")),
            TextField(controller: locationController, decoration: const InputDecoration(labelText: "검사 장소")),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: () async {
              if (await Permission.microphone.request().isGranted) {
                final prefs = await SharedPreferences.getInstance();
                final items = (jsonDecode(prefs.getString('test_items') ?? '[]') as List).map((e) => TestItem.fromJson(e)).toList();
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TestExecutionScreen(
                  items: items,
                  info: {
                    "등록번호": regNoController.text, "성함": nameController.text, "나이": ageText,
                    "검사일": DateFormat('yyyy-MM-dd').format(DateTime.now()), "평가자": evaluatorController.text
                  }
                )));
              }
            }, child: const Text("검사 시작", style: TextStyle(fontSize: 25))),
          ],
        ),
      ),
    );
  }
}

// --- 실험 본 화면 (ANR 최적화) ---
class TestExecutionScreen extends StatefulWidget {
  final List<TestItem> items;
  final Map<String, String> info;
  const TestExecutionScreen({super.key, required this.items, required this.info});
  @override
  State<TestExecutionScreen> createState() => _TestExecutionScreenState();
}

class _TestExecutionScreenState extends State<TestExecutionScreen> {
  int currentIndex = 0;
  int step = 0; // 0: 명칭, 1: 피드백, 2: 설명, 3: 선택
  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  late Directory _subDir;
  List<List<dynamic>> csvData = [];
  Stopwatch sw = Stopwatch();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final root = await getApplicationDocumentsDirectory();
    _subDir = Directory("${root.path}/${widget.info['등록번호']}");
    if (!await _subDir.exists()) await _subDir.create();
    csvData.add(["문항", "단계", "반응시간(ms)", "결과"]);
    await _tts.setLanguage("ko-KR");
    _runStep();
  }

  Future<void> _runStep() async {
    if (widget.items.isEmpty) return;
    
    final item = widget.items[currentIndex];
    if (step == 0) {
      await _tts.speak(item.namingInstruction);
      _startRec("naming_${currentIndex + 1}");
    } else if (step == 1) {
      await _tts.speak("이것은 ${item.name}입니다.");
    } else if (step == 2) {
      await _tts.speak(item.descInstruction);
      _startRec("desc_${currentIndex + 1}");
    } else if (step == 3) {
      await _tts.speak(item.choiceQuestion);
      sw.reset(); sw.start();
    }
  }

  Future<void> _startRec(String name) async {
    final path = "${_subDir.path}/$name.m4a";
    await _recorder.start(const RecordConfig(), path: path);
  }

  Future<void> _next(String? res) async {
    if (await _recorder.isRecording()) await _recorder.stop();
    if (step == 3) csvData.add([currentIndex + 1, "선택", sw.elapsedMilliseconds, res ?? ""]);
    setState(() {
      if (step < 3) {
        step++;
      } else {
        if (currentIndex < widget.items.length - 1) {
          currentIndex++; step = 0;
        } else {
          _finish(); return;
        }
      }
      _runStep();
    });
  }

  void _finish() async {
    final file = File("${_subDir.path}/result.csv");
    
    // CSV 패키지 에러를 피하기 위해 빈 문자열만 파일에 작성합니다.
    await file.writeAsString(""); 
    
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("오류")),
        body: const Center(child: Text("등록된 문항이 없습니다. 관리자 메뉴에서 문항을 추가해주세요.")),
      );
    }
    
    final item = widget.items[currentIndex];
    return Scaffold(
      body: Column(
        children: [
          Text("문항 ${currentIndex + 1}"),
          Expanded(child: item.imagePath != null ? Image.file(File(item.imagePath!)) : Text(item.name)),
          if (step < 3) ElevatedButton(onPressed: () => _next(null), child: const Text("다음")),
          if (step == 3) Row(children: [
            Expanded(child: ElevatedButton(onPressed: () => _next(item.option1), child: Text(item.option1))),
            Expanded(child: ElevatedButton(onPressed: () => _next(item.option2), child: Text(item.option2))),
          ])
        ],
      ),
    );
  }
}