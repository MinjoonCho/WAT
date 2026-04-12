import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/test_item.dart';
import '../utils/default_template.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 문항 관리 화면 (관리자용)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class TemplateManager extends StatefulWidget {
  const TemplateManager({super.key});

  @override
  State<TemplateManager> createState() => _TemplateManagerState();
}

class _TemplateManagerState extends State<TemplateManager> {
  List<TestItem> items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('test_items');
    if (data != null) {
      setState(
        () => items =
            (jsonDecode(data) as List).map((e) => TestItem.fromJson(e)).toList(),
      );
      return;
    }

    items = buildDefaultTemplateItems();
    await _save();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _restoreDefaultTemplate() async {
    setState(() => items = buildDefaultTemplateItems());
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('기본 템플릿으로 복원했습니다.')),
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'test_items',
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  // 순서 변경
  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() => items.insert(index - 1, items.removeAt(index)));
    _save();
  }

  void _moveDown(int index) {
    if (index >= items.length - 1) return;
    setState(() => items.insert(index + 1, items.removeAt(index)));
    _save();
  }

  // 편집/추가 다이얼로그
  void _editItem(int? index) {
    TestItem target =
        index == null ? TestItem(name: '') : TestItem.fromJson(items[index].toJson());

    final nameCtrl = TextEditingController(text: target.name);
    final namingCtrl = TextEditingController(text: target.namingInstruction);
    final descCtrl = TextEditingController(text: target.descInstruction);
    final choiceCtrl = TextEditingController(text: target.choiceQuestion);
    final op1Ctrl = TextEditingController(text: target.option1);
    final op2Ctrl = TextEditingController(text: target.option2);
    final descExCtrl = TextEditingController(text: target.practiceDescExample ?? '');
    final answerExpCtrl =
        TextEditingController(text: target.practiceAnswerExplanation ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(index == null ? '새 문항 추가' : '문항 편집'),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 연습문항 체크박스 ───────────────────────────────────
                  CheckboxListTile(
                    title: const Text('연습문항',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    value: target.isPractice,
                    activeColor: const Color(0xFF9C27B0),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) =>
                        setDlg(() => target.isPractice = v ?? false),
                  ),
                  const Divider(),

                  // ── 기본 정보 ─────────────────────────────────────────
                  _field(nameCtrl, '사물 이름 *'),
                  _field(namingCtrl, '명칭 질문 (예: 이게 뭐죠?)'),
                  _field(descCtrl, '설명 지시 (예: 이 사물에 대해 설명해보세요.)'),

                  const SizedBox(height: 8),
                  const Text('메인 이미지',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final xf = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (xf != null) setDlg(() => target.imagePath = xf.path);
                      },
                      icon: const Icon(Icons.image, size: 18),
                      label: Text(target.imagePath != null ? '이미지 변경' : '이미지 선택'),
                    ),
                    if (target.imagePath != null) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _imagePreview(target.imagePath!, 72),
                      ),
                    ],
                  ]),
                  const Divider(),

                  // ── 선택지 ────────────────────────────────────────────
                  _field(choiceCtrl, '선택지 질문'),
                  const SizedBox(height: 8),
                  const Text('선택지 정답 설정',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  // 선택지 1
                  Row(
                    children: [
                      Radio<int>(
                        value: 1,
                        groupValue: target.correctOptionIndex,
                        activeColor: const Color(0xFF9C27B0),
                        onChanged: (v) =>
                            setDlg(() => target.correctOptionIndex = v!),
                      ),
                      const Text('정답'),
                      const SizedBox(width: 8),
                      Expanded(child: _field(op1Ctrl, '선택지 1')),
                      const SizedBox(width: 8),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        ElevatedButton(
                          onPressed: () async {
                            final xf = await ImagePicker()
                                .pickImage(source: ImageSource.gallery);
                            if (xf != null) setDlg(() => target.option1ImagePath = xf.path);
                          },
                          child: Text(
                            target.option1ImagePath != null ? '이미지 ✓' : '이미지',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (target.option1ImagePath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: _imagePreview(target.option1ImagePath!, 64),
                            ),
                          ),
                      ]),
                    ],
                  ),
                  // 선택지 2
                  Row(
                    children: [
                      Radio<int>(
                        value: 2,
                        groupValue: target.correctOptionIndex,
                        activeColor: const Color(0xFF9C27B0),
                        onChanged: (v) =>
                            setDlg(() => target.correctOptionIndex = v!),
                      ),
                      const Text('정답'),
                      const SizedBox(width: 8),
                      Expanded(child: _field(op2Ctrl, '선택지 2')),
                      const SizedBox(width: 8),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        ElevatedButton(
                          onPressed: () async {
                            final xf = await ImagePicker()
                                .pickImage(source: ImageSource.gallery);
                            if (xf != null) setDlg(() => target.option2ImagePath = xf.path);
                          },
                          child: Text(
                            target.option2ImagePath != null ? '이미지 ✓' : '이미지',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        if (target.option2ImagePath != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: _imagePreview(target.option2ImagePath!, 64),
                            ),
                          ),
                      ]),
                    ],
                  ),

                  // ── 연습문항 전용 필드 ────────────────────────────────
                  if (target.isPractice) ...[
                    const Divider(),
                    const Text('연습문항 전용',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9C27B0))),
                    const SizedBox(height: 8),
                    _field(descExCtrl, '설명 예시 (슬라이드6 하단 예시 텍스트)', maxLines: 4),
                    const SizedBox(height: 8),
                    _field(answerExpCtrl, '정답 해설 (슬라이드9 상단 해설 텍스트)', maxLines: 3),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                target.name = nameCtrl.text.trim();
                target.namingInstruction = namingCtrl.text.trim();
                target.descInstruction = descCtrl.text.trim();
                target.choiceQuestion = choiceCtrl.text.trim();
                target.option1 = op1Ctrl.text.trim();
                target.option2 = op2Ctrl.text.trim();
                target.practiceDescExample =
                    descExCtrl.text.trim().isEmpty ? null : descExCtrl.text.trim();
                target.practiceAnswerExplanation =
                    answerExpCtrl.text.trim().isEmpty
                        ? null
                        : answerExpCtrl.text.trim();

                setState(() {
                  if (index == null) {
                    items.add(target);
                  } else {
                    items[index] = target;
                  }
                });
                _save();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
              ),
              child: const Text('저장', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      persistentFooterButtons: [
        OutlinedButton.icon(
          onPressed: _restoreDefaultTemplate,
          icon: const Icon(Icons.restore),
          label: const Text('기본 템플릿 복원'),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editItem(null),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? const Center(child: Text('등록된 문항이 없습니다.'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  items.insert(newIndex, items.removeAt(oldIndex));
                });
                _save();
              },
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                return ListTile(
                  key: ValueKey(i),
                  leading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: item.isPractice
                          ? const Color(0xFFF3E5F5)
                          : const Color(0xFF9C27B0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: item.isPractice
                            ? const Color(0xFF9C27B0)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Row(
                    children: [
                      if (item.isPractice)
                        Container(
                          margin: const EdgeInsets.only(right: 6, top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '연습',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9C27B0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        '정답: 선택지 ${item.correctOptionIndex}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 위아래 버튼
                      IconButton(
                        icon: const Icon(Icons.arrow_upward, size: 20),
                        onPressed: i > 0 ? () => _moveUp(i) : null,
                        tooltip: '위로',
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward, size: 20),
                        onPressed: i < items.length - 1
                            ? () => _moveDown(i)
                            : null,
                        tooltip: '아래로',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editItem(i),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => items.removeAt(i));
                          _save();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _imagePreview(String path, double size) {
    if (path.startsWith('asset:')) {
      return Image.asset(
        path.substring('asset:'.length),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(path),
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
