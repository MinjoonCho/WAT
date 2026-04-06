import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../models/test_item.dart';

class TestExecutionScreen extends StatefulWidget {
  final List<TestItem> items;
  final Map<String, String> info;
  final DateTime startTime;
  const TestExecutionScreen({
    super.key,
    required this.items,
    required this.info,
    required this.startTime,
  });
  @override
  State<TestExecutionScreen> createState() => _TestExecutionScreenState();
}

enum _Phase { instruction, practice, transition, real, done }

class _TestExecutionScreenState extends State<TestExecutionScreen> {
  _Phase _phase = _Phase.instruction;
  int _itemIndex = 0;
  int _step = 0;

  late List<TestItem> _practiceItems;
  late List<TestItem> _realItems;

  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  late Directory _subDir;

  // CSV 헤더: 문항, 이름, 명칭RT, 설명RT, 선택RT, 정오
  List<List<dynamic>> _csvData = [];

  // 반응시간 측정
  final Stopwatch _rtSw = Stopwatch();
  bool _rtActive = false;

  // 문항별 RT 누적 [명칭ms, 설명ms, 선택ms]
  final Map<int, List<int>> _itemRTs = {};

  // RecordConfig — 128kbps, 44100Hz, voiceRecognition 소스
  static const _recCfg = RecordConfig(
    encoder: AudioEncoder.aacLc,
    bitRate: 128000,
    sampleRate: 44100,
    numChannels: 1,
    androidConfig: AndroidRecordConfig(
      audioSource: AndroidAudioSource.voiceRecognition,
    ),
  );

  @override
  void initState() {
    super.initState();
    _practiceItems = widget.items.where((e) => e.isPractice).toList();
    _realItems     = widget.items.where((e) => !e.isPractice).toList();
    _init();
  }

  Future<void> _init() async {
    final root  = await getApplicationDocumentsDirectory();
    final regNo = widget.info['등록번호'] ?? 'unknown';
    _subDir = Directory('${root.path}/$regNo');
    if (!await _subDir.exists()) await _subDir.create();
    _csvData.add(['문항번호', '문항명', '명칭반응시간(ms)', '설명반응시간(ms)', '선택반응시간(ms)', '정오']);
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.45);
    // TTS 완료 → 타이머 시작
    _tts.setCompletionHandler(() {
      if (_phase == _Phase.real && (_step == 0 || _step == 1 || _step == 2)) {
        _startRT();
        setState(() {}); // 타이머 상태 반영
      }
    });
    await _speak('지금부터 그림을 보여줄 거예요. 그림을 잘 보고 대답해 보세요.');
  }

  void _startRT() {
    _rtSw.reset();
    _rtSw.start();
    _rtActive = true;
  }

  int _stopRT() {
    if (!_rtActive) return 0;
    _rtSw.stop();
    _rtActive = false;
    return _rtSw.elapsedMilliseconds;
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _startRec(String name) async {
    final path = '${_subDir.path}/$name.m4a';
    await _recorder.start(_recCfg, path: path);
  }

  Future<void> _stopRec() async {
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  // ── Next 버튼 처리 ────────────────────────────────────────────────────────
  Future<void> _next() async {
    switch (_phase) {
      case _Phase.instruction:
        if (_practiceItems.isNotEmpty) {
          setState(() { _phase = _Phase.practice; _itemIndex = 0; _step = 0; });
          _runPracticeStep();
        } else {
          _toTransition();
        }
        break;

      case _Phase.practice:
        if (_step < 5) {
          setState(() => _step++);
          _runPracticeStep();
        } else {
          if (_itemIndex < _practiceItems.length - 1) {
            setState(() { _itemIndex++; _step = 0; });
            _runPracticeStep();
          } else {
            _toTransition();
          }
        }
        break;

      case _Phase.transition:
        if (_realItems.isNotEmpty) {
          setState(() { _phase = _Phase.real; _itemIndex = 0; _step = 0; });
          _runRealStep();
        } else {
          _finish();
        }
        break;

      case _Phase.real:
        await _handleRealNext();
        break;

      case _Phase.done:
        Navigator.popUntil(context, (r) => r.isFirst);
        break;
    }
  }

  Future<void> _handleRealNext() async {
    switch (_step) {
      case 0: // 명칭 → RT 기록, 녹음 중지, step1
        final ms = _stopRT();
        _itemRTs[_itemIndex] = [ms, 0, 0];
        await _stopRec();
        setState(() => _step = 1);
        _runRealStep();
        break;
      case 1: // 설명 → RT 기록, 녹음 중지, step2
        final ms = _stopRT();
        _itemRTs[_itemIndex]![1] = ms;
        await _stopRec();
        setState(() => _step = 2);
        _runRealStep();
        break;
      case 2: // 선택질문 → step3 (RT는 계속 실행, TTS 완료 후 이미 시작됨)
        setState(() => _step = 3);
        break;
      default:
        break;
    }
  }

  // 선택지 탭 처리 (step 3)
  Future<void> _handleChoice(String chosen) async {
    final ms = _stopRT();
    final item = _realItems[_itemIndex];
    _itemRTs[_itemIndex] ??= [0, 0, 0];
    _itemRTs[_itemIndex]![2] = ms;
    final isCorrect = (chosen == '1' && item.correctOptionIndex == 1) ||
                      (chosen == '2' && item.correctOptionIndex == 2);
    _csvData.add([
      _itemIndex + 1,
      item.name,
      _itemRTs[_itemIndex]![0],
      _itemRTs[_itemIndex]![1],
      ms,
      isCorrect ? '정답' : '오답',
    ]);
    if (_itemIndex < _realItems.length - 1) {
      setState(() { _itemIndex++; _step = 0; });
      _runRealStep();
    } else {
      _finish();
    }
  }

  void _toTransition() {
    setState(() => _phase = _Phase.transition);
    _speak('지금부터 다른 그림들을 더 보여드릴게요. 같은 방식으로 해보세요.');
  }

  Future<void> _runPracticeStep() async {
    if (_practiceItems.isEmpty) return;
    final item = _practiceItems[_itemIndex];
    switch (_step) {
      case 0: await _speak(item.namingInstruction); break;
      case 1: await _speak('이건 ${item.name}이에요. ${item.descInstruction}'); break;
      case 2: break; // 예시 텍스트만 표시
      case 3: await _speak(item.choiceQuestion); break;
      case 4: break; // 선택지 이미지 표시
      case 5:
        if (item.practiceAnswerExplanation != null) {
          await _speak(item.practiceAnswerExplanation!);
        }
        break;
    }
  }

  Future<void> _runRealStep() async {
    if (_realItems.isEmpty) return;
    final item = _realItems[_itemIndex];
    final idx  = _itemIndex + 1;
    switch (_step) {
      case 0:
        await _speak(item.namingInstruction);
        await _startRec('naming_$idx');
        break;
      case 1:
        await _speak('이건 ${item.name}이에요. ${item.descInstruction}');
        await _startRec('desc_$idx');
        break;
      case 2:
        await _speak(item.choiceQuestion);
        break;
      case 3:
        // 이미지 표시만 (tts 없음, 타이머는 step2 TTS 완료 시 시작)
        break;
    }
  }

  void _finish() async {
    await _stopRec();
    final endTime  = DateTime.now();
    final totalMin = endTime.difference(widget.startTime).inMinutes;
    final csvFile  = File('${_subDir.path}/result.csv');
    final headerInfo = [
      '피검자명,${widget.info['피검자명']}',
      '등록번호,${widget.info['등록번호']}',
      '검사일,${widget.info['검사일']}',
      '검사자명,${widget.info['검사자명']}',
      '검사장소,${widget.info['검사장소']}',
      '검사코드,${widget.info['검사코드']}',
      '소요시간(분),$totalMin',
      '',
    ].join('\n');
    final rows = _csvData.map((r) => r.join(',')).join('\n');
    await csvFile.writeAsString('$headerInfo$rows\n');
    setState(() => _phase = _Phase.done);
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.instruction:
        return _textScreen('지금부터 그림을 보여줄 거예요.\n그림을 잘 보고 대답해 보세요.');
      case _Phase.practice:
        return _practiceScreen();
      case _Phase.transition:
        return _textScreen('지금부터 다른 그림들을 더 보여드릴게요.\n같은 방식으로 해보세요.');
      case _Phase.real:
        return _realScreen();
      case _Phase.done:
        return _doneScreen();
    }
  }

  // ── 텍스트 전용 화면 ───────────────────────────────────────────────────────
  Widget _textScreen(String text) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, height: 1.7)),
          ),
        ),
        _nextBtn(),
      ]),
    );
  }

  // ── 연습문항 화면 ──────────────────────────────────────────────────────────
  Widget _practiceScreen() {
    if (_practiceItems.isEmpty) return const SizedBox();
    final item = _practiceItems[_itemIndex];
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        _practiceContent(item),
        _label('연습문항'),
        if (_step != 4) _nextBtn(),
      ]),
    );
  }

  Widget _practiceContent(TestItem item) {
    switch (_step) {
      case 0: return _namingView(item.namingInstruction, item.imagePath);
      case 1: return _descView('이건 ${item.name}이에요.\n${item.descInstruction}', item.imagePath);
      case 2:
        return Column(children: [
          Expanded(child: _descView('이건 ${item.name}이에요.\n${item.descInstruction}', item.imagePath)),
          if (item.practiceDescExample != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(40, 16, 40, 80),
              child: Text(item.practiceDescExample!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, color: Color(0xFF555555), height: 1.8)),
            ),
        ]);
      case 3: return _choiceQView(item.choiceQuestion, item.imagePath);
      case 4: return _choiceImgView(item, onTap: (_) => _next(), highlight: -1);
      case 5: return _choiceImgView(item, onTap: null, highlight: item.correctOptionIndex,
                  explanation: item.practiceAnswerExplanation);
      default: return const SizedBox();
    }
  }

  // ── 본문항 화면 ────────────────────────────────────────────────────────────
  Widget _realScreen() {
    if (_realItems.isEmpty) return const SizedBox();
    final item = _realItems[_itemIndex];
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        _realContent(item),
        _label('문항 ${_itemIndex + 1}'),
        if (_step != 3) _nextBtn(),
      ]),
    );
  }

  Widget _realContent(TestItem item) {
    switch (_step) {
      case 0: return _namingView(item.namingInstruction, item.imagePath);
      case 1: return _descView('이건 ${item.name}이에요.\n${item.descInstruction}', item.imagePath);
      case 2: return _choiceQView(item.choiceQuestion, item.imagePath);
      case 3: return _choiceImgView(item, onTap: _handleChoice, highlight: -1);
      default: return const SizedBox();
    }
  }

  // ── 종료 화면 ──────────────────────────────────────────────────────────────
  Widget _doneScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('끝!', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
              minimumSize: const Size(280, 72),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text('수고했습니다!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 공통 레이아웃
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  // 명칭: 질문 상단 + 이미지 (남은 공간 전체)
  Widget _namingView(String q, String? path) {
    return SafeArea(
      child: Column(children: [
        const SizedBox(height: 56),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(q,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 90),
            child: _img(path),
          ),
        ),
      ]),
    );
  }

  // 설명: 텍스트 상단 + 이미지 (남은 공간)
  Widget _descView(String text, String? path) {
    return SafeArea(
      child: Column(children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.5)),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 90),
            child: _img(path),
          ),
        ),
      ]),
    );
  }

  // 선택질문: 이미지(30%) + 질문 텍스트
  Widget _choiceQView(String q, String? path) {
    return SafeArea(
      child: Column(children: [
        const SizedBox(height: 16),
        Expanded(flex: 3, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: _img(path),
        )),
        const SizedBox(height: 16),
        Expanded(flex: 3, child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 90),
          child: Text(q,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.6)),
        )),
      ]),
    );
  }

  // 선택지 이미지
  Widget _choiceImgView(
    TestItem item, {
    required void Function(String)? onTap,
    required int highlight,
    String? explanation,
  }) {
    return SafeArea(
      child: Column(children: [
        const SizedBox(height: 8),
        // 상단 메인 이미지 (25%)
        Expanded(flex: 25, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: _img(item.imagePath),
        )),
        const SizedBox(height: 8),
        // 설명 또는 질문
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            explanation ?? item.choiceQuestion,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.5),
          ),
        ),
        const SizedBox(height: 8),
        // 선택지 이미지 (45%)
        Expanded(flex: 45, child: Row(children: [
          _choiceCell(item.option1, item.option1ImagePath,
            highlight: highlight == 1, onTap: onTap != null ? () => onTap('1') : null),
          _choiceCell(item.option2, item.option2ImagePath,
            highlight: highlight == 2, onTap: onTap != null ? () => onTap('2') : null),
        ])),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _choiceCell(String label, String? path, {required bool highlight, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(
            child: Stack(alignment: Alignment.center, children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _img(path),
              ),
              if (highlight)
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 6,
                        strokeAlign: BorderSide.strokeAlignOutside),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
  }

  // 이미지 위젯 (fit: contain, 전체 공간 활용)
  Widget _img(String? path) {
    if (path != null && File(path).existsSync()) {
      return Image.file(File(path),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain);
    }
    return const Center(
      child: Icon(Icons.image_not_supported_outlined, size: 80, color: Color(0xFFCCCCCC)));
  }

  // 문항 라벨 (좌상단)
  Widget _label(String text) {
    return Positioned(
      top: 40, left: 24,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade600,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  // Next 버튼 (우하단)
  Widget _nextBtn() {
    return Positioned(
      right: 32, bottom: 32,
      child: GestureDetector(
        onTap: _next,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF888888),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Next', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ]),
        ),
      ),
    );
  }
}
