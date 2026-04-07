import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/test_item.dart';
import 'test_execution_screen.dart';

// ────────────────────────────────────────────────────────────────────────────
// 교육년수 → 학력 레이블
// ────────────────────────────────────────────────────────────────────────────
String _eduLabel(int years) {
  if (years == 0) return '무학';
  if (years <= 6) return '초졸';
  if (years <= 9) return '중졸';
  if (years <= 12) return '고졸';
  if (years <= 16) return '대졸';
  if (years <= 18) return '대학원졸';
  return '19년 이상';
}

class TestSetupScreen extends StatefulWidget {
  const TestSetupScreen({super.key});

  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
  final _nameCtrl      = TextEditingController();
  final _regNoCtrl     = TextEditingController();
  final _testCodeCtrl  = TextEditingController();
  final _examinerCtrl  = TextEditingController();
  final _sessionCtrl   = TextEditingController();

  DateTime? _birthDate;
  String    _gender    = '남';
  int       _eduYears  = 0;

  List<String> _locations        = [];
  String?      _selectedLocation;
  bool         _locationsLoaded  = false;

  final String _testDate = DateFormat('yyyyMMdd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('locations');
    final list  = raw != null
        ? List<String>.from(jsonDecode(raw))
        : <String>['신촌세브란스병원'];
    setState(() {
      _locations       = list;
      _selectedLocation = list.isNotEmpty ? list.first : null;
      _locationsLoaded  = true;
    });
  }

  String _calcAge(DateTime birth) {
    final now    = DateTime.now();
    int   age    = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) age--;
    final months = (now.month - birth.month + 12) % 12;
    return '$age세  $months개월';
  }

  Future<void> _pickBirthDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(1960),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _birthDate = d);
  }

  Future<void> _startTest() async {
    if (await Permission.microphone.request().isGranted) {
      final prefs = await SharedPreferences.getInstance();
      final items = (jsonDecode(prefs.getString('test_items') ?? '[]') as List)
          .map((e) => TestItem.fromJson(e))
          .toList();
      if (!mounted) return;
      final startTime = DateTime.now();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TestExecutionScreen(
            items: items,
            info: {
              '피검자명' : _nameCtrl.text,
              '생년월일' : _birthDate != null
                  ? DateFormat('yyyyMMdd').format(_birthDate!)
                  : '',
              '나이'    : _birthDate != null ? _calcAge(_birthDate!) : '',
              '성별'    : _gender,
              '교육년수' : '$_eduYears',
              '학력'    : _eduLabel(_eduYears),
              '등록번호' : _regNoCtrl.text,
              '검사일'  : _testDate,
              '검사자명' : _examinerCtrl.text,
              '검사장소' : _selectedLocation ?? '',
              '검사코드' : '2026S${_testCodeCtrl.text}',
              '검사회차' : _sessionCtrl.text,
            },
            startTime: startTime,
          ),
        ),
      );
    }
  }

  // ── 컬러 상수 ──────────────────────────────────────────────────────────────
  static const _purple = Color(0xFF9C27B0);
  static const _border = Color(0xFFCE93D8);

  // ── 공통 셀 높이 ────────────────────────────────────────────────────────────
  static const double _rowH = 64.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 타이틀 ───────────────────────────────────────────────────────
            const Text(
              '기본 정보',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // ── 커스텀 테이블 ─────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  // 1행: 피검자명 | 검사일
                  _row([
                    _hCell('피검자명'),
                    _inputCell(controller: _nameCtrl, hint: '홍길순'),
                    _hCell('검사일'),
                    _plainCell(_testDate, color: Colors.grey),
                  ]),
                  _divider(),

                  // 2행: 생년월일 | 검사[소요]시간
                  _row([
                    _hCell('생년월일'),
                    _tapCell(
                      _birthDate != null
                          ? DateFormat('yyyyMMdd').format(_birthDate!)
                          : '탭하여 선택',
                      onTap: _pickBirthDate,
                      dim: _birthDate == null,
                    ),
                    _hCell('검사[소요]시간'),
                    _plainCell('자동 측정', color: Colors.grey),
                  ]),
                  _divider(),

                  // 3행: 나이 | 검사자명
                  _row([
                    _hCell('나이'),
                    _plainCell(
                      _birthDate != null ? _calcAge(_birthDate!) : '—',
                    ),
                    _hCell('검사자명'),
                    _inputCell(controller: _examinerCtrl, hint: '김향희'),
                  ]),
                  _divider(),

                  // 4행: 성별 | 검사장소
                  _row([
                    _hCell('성별'),
                    _genderCell(),
                    _hCell('검사장소'),
                    _locationCell(),
                  ]),
                  _divider(),

                  // 5행: 교육년수 | 검사코드
                  _row(
                    [
                      _hCell('교육년수'),
                      _eduCell(),
                      _hCell('검사코드'),
                      // 검사코드는 2026S + 넘버패드 입력
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            const Text('2026S', style: TextStyle(fontSize: 15, color: Colors.blue)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: _testCodeCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 15, color: Colors.red),
                                decoration: const InputDecoration(
                                  hintText: '00001',
                                  hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    height: 96,
                  ),
                  _divider(),

                  // 6행: 등록번호 | 검사회차
                  _row([
                    _hCell('등록번호'),
                    _inputCell(controller: _regNoCtrl, hint: '2635114', isNumber: true),
                    _hCell('검사회차'),
                    _inputCell(controller: _sessionCtrl, hint: '1', isNumber: true),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── 시작 버튼 (우측) ───────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _startTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '검사 시작',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 레이아웃 헬퍼
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _row(List<Widget> cells, {double height = _rowH}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cells.map((c) {
          final isHeader = c is _HeaderCell;
          return isHeader
              ? c
              : Expanded(child: SizedBox(height: height, child: c));
        }).toList(),
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: _border);

  // 헤더 셀 (보라색 배경)
  _HeaderCell _hCell(String label) => _HeaderCell(label);

  // 일반 텍스트 셀
  Widget _plainCell(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: color ?? Colors.black87,
          ),
        ),
      ),
    );
  }

  // TextField 셀
  Widget _inputCell({
    required TextEditingController controller,
    required String hint,
    Color textColor = Colors.black87,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(fontSize: 15, color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        ),
      ),
    );
  }

  // 탭 가능한 셀 (생년월일)
  Widget _tapCell(String text, {required VoidCallback onTap, bool dim = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: dim ? const Color(0xFF999999) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // 성별 토글 셀
  Widget _genderCell() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: ['남', '여'].map((g) {
          final sel = _gender == g;
          return GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _purple : const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: _purple, width: 1.5),
              ),
              child: Text(
                g,
                style: TextStyle(
                  color: sel ? Colors.white : _purple,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 검사장소 드롭다운 셀
  Widget _locationCell() {
    if (!_locationsLoaded) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_locations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('장소 없음', style: TextStyle(color: Colors.grey)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedLocation,
          items: _locations
              .map(
                (loc) => DropdownMenuItem(
                  value: loc,
                  child: Text(loc, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedLocation = v);
          },
        ),
      ),
    );
  }

  // 교육년수 슬라이더 셀
  Widget _eduCell() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$_eduYears년',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _eduLabel(_eduYears),
                  style: const TextStyle(
                    fontSize: 12,
                    color: _purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _eduYears.toDouble(),
              min: 0,
              max: 19,
              divisions: 19,
              activeColor: _purple,
              inactiveColor: const Color(0xFFE1BEE7),
              onChanged: (v) => setState(() => _eduYears = v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 헤더 셀 위젯 (Expanded 없이 IntrinsicWidth 사용)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      color: const Color(0xFF9C27B0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
