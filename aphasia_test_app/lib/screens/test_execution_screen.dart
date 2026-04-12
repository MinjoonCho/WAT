import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/test_item.dart';

class TestExecutionScreen extends StatefulWidget {
  final List<TestItem> items;
  final Map<String, String> info;
  final DateTime startTime;
  final bool randomizeItems;

  const TestExecutionScreen({
    super.key,
    required this.items,
    required this.info,
    required this.startTime,
    this.randomizeItems = false,
  });

  @override
  State<TestExecutionScreen> createState() => _TestExecutionScreenState();
}

enum _Phase { instruction, practice, transition, real, done }

class _TestExecutionScreenState extends State<TestExecutionScreen> {
  _Phase _phase = _Phase.instruction;
  int _itemIndex = 0;
  int _step = 0;

  late final List<TestItem> _practiceItems;
  late final List<TestItem> _realItems;

  final FlutterTts _tts = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  late Directory _subDir;

  final List<List<dynamic>> _csvData = [];
  final Stopwatch _rtSw = Stopwatch();
  final Map<int, List<int>> _itemRTs = {};
  bool _rtActive = false;

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
    _realItems = widget.items.where((e) => !e.isPractice).toList();
    if (widget.randomizeItems) {
      _realItems.shuffle(Random());
    }
    _init();
  }

  Future<void> _init() async {
    final root = await getApplicationDocumentsDirectory();
    final regNo = widget.info['등록번호'] ?? 'unknown';
    _subDir = Directory('${root.path}/$regNo');
    if (!await _subDir.exists()) {
      await _subDir.create();
    }

    _csvData.add([
      'Item No.',
      'Item',
      'NamingRT(ms.)',
      'DescriptionRT(ms.)',
      'AssociationRT(ms.)',
      'Accuracy',
    ]);

    await _configureTts();
    _tts.setCompletionHandler(() {
      if (!mounted) return;

      if (_phase == _Phase.real && (_step == 0 || _step == 1)) {
        _startRT();
        setState(() {});
        return;
      }

      if (_phase == _Phase.real && _step == 2) {
        _startRT();
        setState(() => _step = 3);
        return;
      }

      if (_phase == _Phase.practice && _step == 3) {
        setState(() => _step = 4);
      }
    });

    await _speak('지금부터 그림을 보여줄 거예요. 그림을 잘 보고 대답해 보세요.');
  }

  Future<void> _configureTts() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(0.95);

    try {
      final rawVoices = await _tts.getVoices;
      if (rawVoices is! List) return;

      final voices = rawVoices.whereType<Map>().toList();
      final koreanVoices = voices.where((voice) {
        final locale = '${voice['locale'] ?? ''}'.toLowerCase();
        return locale.startsWith('ko');
      }).toList();

      if (koreanVoices.isEmpty) return;

      koreanVoices.sort((a, b) {
        return _voiceQualityScore(b).compareTo(_voiceQualityScore(a));
      });

      final bestVoice = koreanVoices.first;
      final voice = <String, String>{};
      if (bestVoice['name'] != null && bestVoice['locale'] != null) {
        voice['name'] = '${bestVoice['name']}';
        voice['locale'] = '${bestVoice['locale']}';
      }
      if (bestVoice['identifier'] != null) {
        voice['identifier'] = '${bestVoice['identifier']}';
      }
      if (voice.isNotEmpty) {
        await _tts.setVoice(voice);
      }
    } catch (_) {
      // 플랫폼이 음성 조회를 지원하지 않으면 기본 한국어 음성을 사용한다.
    }
  }

  int _voiceQualityScore(Map voice) {
    final quality = _asInt(voice['quality']);
    final latency = _asInt(voice['latency']);
    final networkPenalty = _asBool(voice['network_required']) ? 1000 : 0;
    return quality - latency - networkPenalty;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    return '$value'.toLowerCase() == 'true';
  }

  void _startRT() {
    _rtSw
      ..reset()
      ..start();
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
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  String _copula(String word) {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return '예요';

    for (var i = trimmed.length - 1; i >= 0; i--) {
      final code = trimmed.codeUnitAt(i);
      if (_isSkippableCodeUnit(code)) continue;
      if (code < 0xAC00 || code > 0xD7A3) return '예요';
      final hasBatchim = (code - 0xAC00) % 28 != 0;
      return hasBatchim ? '이에요' : '예요';
    }

    return '예요';
  }

  bool _isSkippableCodeUnit(int code) {
    return code == 0x20 ||
        code == 0x2E ||
        code == 0x2C ||
        code == 0x21 ||
        code == 0x3F ||
        code == 0x22 ||
        code == 0x27 ||
        code == 0x28 ||
        code == 0x29;
  }

  String _itemDescriptionLead(String name) => '이건 $name${_copula(name)}';

  Future<void> _next() async {
    switch (_phase) {
      case _Phase.instruction:
        if (_practiceItems.isNotEmpty) {
          setState(() {
            _phase = _Phase.practice;
            _itemIndex = 0;
            _step = 0;
          });
          await _runPracticeStep();
        } else {
          _toTransition();
        }
        break;
      case _Phase.practice:
        if (_step < 5) {
          setState(() => _step++);
          await _runPracticeStep();
        } else if (_itemIndex < _practiceItems.length - 1) {
          setState(() {
            _itemIndex++;
            _step = 0;
          });
          await _runPracticeStep();
        } else {
          _toTransition();
        }
        break;
      case _Phase.transition:
        if (_realItems.isNotEmpty) {
          setState(() {
            _phase = _Phase.real;
            _itemIndex = 0;
            _step = 0;
          });
          await _runRealStep();
        } else {
          await _finish();
        }
        break;
      case _Phase.real:
        await _handleRealNext();
        break;
      case _Phase.done:
        Navigator.popUntil(context, (route) => route.isFirst);
        break;
    }
  }

  Future<void> _handleRealNext() async {
    switch (_step) {
      case 0:
        final ms = _stopRT();
        _itemRTs[_itemIndex] = [ms, 0, 0];
        await _stopRec();
        setState(() => _step = 1);
        await _runRealStep();
        break;
      case 1:
        final ms = _stopRT();
        _itemRTs[_itemIndex]![1] = ms;
        await _stopRec();
        setState(() => _step = 2);
        await _runRealStep();
        break;
      case 2:
        setState(() => _step = 3);
        break;
      case 3:
      case 4:
      case 5:
        break;
    }
  }

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
      isCorrect ? 'Correct' : 'Incorrect',
    ]);

    if (_itemIndex < _realItems.length - 1) {
      setState(() {
        _itemIndex++;
        _step = 0;
      });
      await _runRealStep();
      return;
    }

    await _finish();
  }

  void _toTransition() {
    setState(() => _phase = _Phase.transition);
    _speak('지금부터 다른 그림들을 더 보여드릴게요. 같은 방식으로 해보세요.');
  }

  Future<void> _runPracticeStep() async {
    if (_practiceItems.isEmpty) return;
    final item = _practiceItems[_itemIndex];

    switch (_step) {
      case 0:
        await _speak(item.namingInstruction);
        break;
      case 1:
        await _speak('${_itemDescriptionLead(item.name)}. ${item.descInstruction}');
        break;
      case 2:
        break;
      case 3:
        await _speak(item.choiceQuestion);
        break;
      case 4:
        break;
      case 5:
        if (item.practiceAnswerExplanation != null &&
            item.practiceAnswerExplanation!.trim().isNotEmpty) {
          await _speak(item.practiceAnswerExplanation!);
        }
        break;
    }
  }

  Future<void> _runRealStep() async {
    if (_realItems.isEmpty) return;
    final item = _realItems[_itemIndex];
    final idx = _itemIndex + 1;

    switch (_step) {
      case 0:
        await _speak(item.namingInstruction);
        await _startRec('naming_$idx');
        break;
      case 1:
        await _speak('${_itemDescriptionLead(item.name)}. ${item.descInstruction}');
        await _startRec('desc_$idx');
        break;
      case 2:
        await _speak(item.choiceQuestion);
        break;
      case 3:
      case 4:
      case 5:
        break;
    }
  }

  Future<void> _finish() async {
    await _stopRec();
    final endTime = DateTime.now();
    final totalMin = endTime.difference(widget.startTime).inMinutes;
    final csvFile = File('${_subDir.path}/result.csv');
    final headerInfo = [
      'Participant Name,${widget.info['피검자명']}',
      'Registration No.,${widget.info['등록번호']}',
      'Test Date,${widget.info['검사일']}',
      'Examiner,${widget.info['검사자명']}',
      'Test Location,${widget.info['검사장소']}',
      'Test Code,${widget.info['검사코드']}',
      'Randomization,${widget.info['문항랜덤화'] == '예' ? 'Yes' : 'No'}',
      'Duration(min),$totalMin',
      '',
    ].join('\n');
    final rows = _csvData.map((row) => row.join(',')).join('\n');
    await csvFile.writeAsString('$headerInfo$rows\n');
    if (mounted) {
      setState(() => _phase = _Phase.done);
    }
  }

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

  Widget _textScreen(String text) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: _pagePadding(horizontal: 48, vertical: 40),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _font(34),
                  fontWeight: FontWeight.bold,
                  height: 1.7,
                ),
              ),
            ),
          ),
          _nextBtn(),
        ],
      ),
    );
  }

  Widget _practiceScreen() {
    if (_practiceItems.isEmpty) return const SizedBox();
    final item = _practiceItems[_itemIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _practiceContent(item),
          _label('연습문항'),
          if (_step != 3 && _step != 4) _nextBtn(),
        ],
      ),
    );
  }

  Widget _practiceContent(TestItem item) {
    switch (_step) {
      case 0:
        return _namingView(item.namingInstruction, item.imagePath);
      case 1:
        return _descView(
          '${_itemDescriptionLead(item.name)}.\n${item.descInstruction}',
          item.imagePath,
        );
      case 2:
        return Column(
          children: [
            Expanded(
              child: _descView(
                '${_itemDescriptionLead(item.name)}.\n${item.descInstruction}',
                item.imagePath,
              ),
            ),
            if (item.practiceDescExample != null)
              Container(
                width: double.infinity,
                padding: _pagePadding(horizontal: 40, vertical: 28),
                child: Text(
                  item.practiceDescExample!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _font(28),
                    color: const Color(0xFF555555),
                    height: 1.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      case 3:
        return _choiceQView(item.choiceQuestion, item.imagePath);
      case 4:
        return _choiceImgView(item, onTap: (_) => _next(), highlight: -1);
      case 5:
        return _choiceImgView(
          item,
          onTap: null,
          highlight: item.correctOptionIndex,
          explanation: item.practiceAnswerExplanation,
        );
    }
    return const SizedBox();
  }

  Widget _realScreen() {
    if (_realItems.isEmpty) return const SizedBox();
    final item = _realItems[_itemIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _realContent(item),
          _label('문항 ${_itemIndex + 1}'),
          if (_step == 0 || _step == 1) _nextBtn(),
        ],
      ),
    );
  }

  Widget _realContent(TestItem item) {
    switch (_step) {
      case 0:
        return _namingView(item.namingInstruction, item.imagePath);
      case 1:
        return _descView(
          '${_itemDescriptionLead(item.name)}.\n${item.descInstruction}',
          item.imagePath,
        );
      case 2:
        return _choiceQView(item.choiceQuestion, item.imagePath);
      case 3:
        return _choiceImgView(item, onTap: _handleChoice, highlight: -1);
      case 4:
      case 5:
        return const SizedBox();
    }
    return const SizedBox();
  }

  Widget _doneScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '끝!',
              style: TextStyle(fontSize: _font(72)),
            ),
            SizedBox(height: _space(32)),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                minimumSize: Size(_space(280), _space(72)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                '수고했습니다!',
                style: TextStyle(
                  fontSize: _font(26),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _namingView(String question, String? path) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: _space(56)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _space(40)),
            child: Text(
              question,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _font(32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: _space(16)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _space(40),
                0,
                _space(40),
                _space(90),
              ),
              child: _img(path),
            ),
          ),
        ],
      ),
    );
  }

  Widget _descView(String text, String? path) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: _space(24)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _space(40)),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _font(28),
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: _space(16)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _space(40),
                0,
                _space(40),
                _space(90),
              ),
              child: _img(path),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceQView(String question, String? path) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: _space(16)),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _space(60)),
              child: _img(path),
            ),
          ),
          SizedBox(height: _space(16)),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                _space(40),
                0,
                _space(40),
                _space(90),
              ),
              child: Text(
                question,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _font(28),
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceImgView(
    TestItem item, {
    required void Function(String)? onTap,
    required int highlight,
    String? explanation,
  }) {
    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: _space(8)),
          Expanded(
            flex: 25,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _space(80)),
              child: _img(item.imagePath),
            ),
          ),
          SizedBox(height: _space(8)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _space(40)),
            child: Text(
              explanation ?? item.choiceQuestion,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _font(24),
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: _space(8)),
          Expanded(
            flex: 45,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isVertical = constraints.maxWidth < 720;
                final children = [
                  _choiceCell(
                    item.option1,
                    item.option1ImagePath,
                    highlight: highlight == 1,
                    onTap: onTap != null ? () => onTap('1') : null,
                  ),
                  _choiceCell(
                    item.option2,
                    item.option2ImagePath,
                    highlight: highlight == 2,
                    onTap: onTap != null ? () => onTap('2') : null,
                  ),
                ];

                if (isVertical) {
                  return Column(children: children);
                }
                return Row(children: children);
              },
            ),
          ),
          SizedBox(height: _space(8)),
        ],
      ),
    );
  }

  Widget _choiceCell(
    String label,
    String? path, {
    required bool highlight,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(_space(16)),
                    child: _img(path),
                  ),
                  if (highlight)
                    Container(
                      margin: EdgeInsets.all(_space(4)),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red,
                          width: _space(6),
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: _space(12)),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _font(22),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _img(String? path) {
    if (path != null && path.startsWith('asset:')) {
      return Image.asset(
        path.substring('asset:'.length),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      );
    }
    if (path != null && File(path).existsSync()) {
      return Image.file(
        File(path),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      );
    }

    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        size: _space(80),
        color: const Color(0xFFCCCCCC),
      ),
    );
  }

  Widget _label(String text) {
    return Positioned(
      top: _space(28),
      left: _space(16),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _space(18),
            vertical: _space(8),
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade600,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: _font(16),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _nextBtn() {
    return Positioned(
      right: _space(24),
      bottom: _space(24),
      child: GestureDetector(
        onTap: _next,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _space(24),
            vertical: _space(14),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF888888),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Next',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _font(18),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: _space(6)),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: _space(16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _uiScale() {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return (shortestSide / 900).clamp(0.72, 1.0).toDouble();
  }

  double _font(double base) {
    return (base * _uiScale()).clamp(base * 0.72, base).toDouble();
  }

  double _space(double base) {
    return base * _uiScale();
  }

  EdgeInsets _pagePadding({
    required double horizontal,
    required double vertical,
  }) {
    return EdgeInsets.symmetric(
      horizontal: _space(horizontal),
      vertical: _space(vertical),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _recorder.dispose();
    super.dispose();
  }
}
