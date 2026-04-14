import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/test_item.dart';
import '../utils/default_template.dart';

class TemplateManager extends StatefulWidget {
  const TemplateManager({super.key});

  @override
  State<TemplateManager> createState() => _TemplateManagerState();
}

class _TemplateManagerState extends State<TemplateManager> {
  static const _accentColor = Color(0xFF9C27B0);
  static const _errorColor = Color(0xFFD32F2F);
  static const _errorBackground = Color(0xFFFFEBEE);

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

  List<String> _missingRequiredFields(TestItem item) {
    final missing = <String>[];

    if (item.name.trim().isEmpty) missing.add('사물 이름');
    if ((item.imagePath ?? '').trim().isEmpty) missing.add('메인 이미지');
    if (item.namingInstruction.trim().isEmpty) missing.add('명칭 질문');
    if (item.descInstruction.trim().isEmpty) missing.add('설명 지시');
    if (item.choiceQuestion.trim().isEmpty) missing.add('선택지 질문');
    if (item.option1.trim().isEmpty) missing.add('선택지 1');
    if ((item.option1ImagePath ?? '').trim().isEmpty) missing.add('선택지 1 이미지');
    if (item.option2.trim().isEmpty) missing.add('선택지 2');
    if ((item.option2ImagePath ?? '').trim().isEmpty) missing.add('선택지 2 이미지');

    if (item.isPractice) {
      if ((item.practiceDescExample ?? '').trim().isEmpty) {
        missing.add('연습 설명 예시');
      }
      if ((item.practiceAnswerExplanation ?? '').trim().isEmpty) {
        missing.add('연습 정답 설명');
      }
    }

    return missing;
  }

  void _editItem(int? index) {
    final target = index == null
        ? TestItem(name: '')
        : TestItem.fromJson(items[index].toJson());

    final nameCtrl = TextEditingController(text: target.name);
    final namingCtrl = TextEditingController(text: target.namingInstruction);
    final descCtrl = TextEditingController(text: target.descInstruction);
    final choiceCtrl = TextEditingController(text: target.choiceQuestion);
    final op1Ctrl = TextEditingController(text: target.option1);
    final op2Ctrl = TextEditingController(text: target.option2);
    final descExCtrl =
        TextEditingController(text: target.practiceDescExample ?? '');
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
                  CheckboxListTile(
                    title: const Text(
                      '연습문항',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: target.isPractice,
                    activeColor: _accentColor,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => setDlg(() => target.isPractice = v ?? false),
                  ),
                  const Divider(),
                  _field(nameCtrl, '사물 이름 *'),
                  _field(namingCtrl, '명칭 질문'),
                  _field(descCtrl, '설명 지시'),
                  const SizedBox(height: 8),
                  const Text(
                    '메인 이미지',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final xf = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (xf != null) {
                            setDlg(() => target.imagePath = xf.path);
                          }
                        },
                        icon: const Icon(Icons.image, size: 18),
                        label: Text(
                          target.imagePath != null ? '이미지 변경' : '이미지 선택',
                        ),
                      ),
                      if (target.imagePath != null) ...[
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _imagePreview(target.imagePath!, 72),
                        ),
                      ],
                    ],
                  ),
                  const Divider(),
                  _field(choiceCtrl, '선택지 질문'),
                  const SizedBox(height: 8),
                  const Text(
                    '선택지 정답 설정',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Radio<int>(
                        value: 1,
                        groupValue: target.correctOptionIndex,
                        activeColor: _accentColor,
                        onChanged: (v) =>
                            setDlg(() => target.correctOptionIndex = v!),
                      ),
                      const Text('정답'),
                      const SizedBox(width: 8),
                      Expanded(child: _field(op1Ctrl, '선택지 1')),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final xf = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                              );
                              if (xf != null) {
                                setDlg(() => target.option1ImagePath = xf.path);
                              }
                            },
                            child: Text(
                              target.option1ImagePath != null ? '이미지 변경' : '이미지',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          if (target.option1ImagePath != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child:
                                    _imagePreview(target.option1ImagePath!, 64),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Radio<int>(
                        value: 2,
                        groupValue: target.correctOptionIndex,
                        activeColor: _accentColor,
                        onChanged: (v) =>
                            setDlg(() => target.correctOptionIndex = v!),
                      ),
                      const Text('정답'),
                      const SizedBox(width: 8),
                      Expanded(child: _field(op2Ctrl, '선택지 2')),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final xf = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                              );
                              if (xf != null) {
                                setDlg(() => target.option2ImagePath = xf.path);
                              }
                            },
                            child: Text(
                              target.option2ImagePath != null ? '이미지 변경' : '이미지',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          if (target.option2ImagePath != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child:
                                    _imagePreview(target.option2ImagePath!, 64),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (target.isPractice) ...[
                    const Divider(),
                    const Text(
                      '연습문항 전용',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _field(descExCtrl, '설명 예시', maxLines: 4),
                    const SizedBox(height: 8),
                    _field(answerExpCtrl, '정답 설명', maxLines: 3),
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
                target.practiceAnswerExplanation = answerExpCtrl.text.trim().isEmpty
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
              style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
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

  Future<void> _confirmDeleteItem(int index) async {
    final item = items[index];
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('재확인'),
        content: Text("'${item.name}' 문항을 삭제할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() => items.removeAt(index));
      await _save();
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('문항 관리')),
      persistentFooterButtons: [
        OutlinedButton.icon(
          onPressed: _restoreDefaultTemplate,
          icon: const Icon(Icons.restore),
          label: const Text('기본 템플릿 복원'),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editItem(null),
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? const Center(child: Text('등록된 문항이 없습니다.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final missingFields = _missingRequiredFields(item);
                final hasIssue = missingFields.isNotEmpty;

                return Container(
                  color: hasIssue ? _errorBackground : null,
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hasIssue
                            ? _errorColor
                            : item.isPractice
                                ? const Color(0xFFF3E5F5)
                                : _accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: hasIssue || !item.isPractice
                              ? Colors.white
                              : _accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      item.name.isEmpty ? '이름 없는 문항' : item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: hasIssue ? _errorColor : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (item.isPractice)
                              Container(
                                margin: const EdgeInsets.only(right: 6, top: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E5F5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  '연습',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _accentColor,
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
                        if (hasIssue) ...[
                          const SizedBox(height: 4),
                          Text(
                            '누락: ${missingFields.join(', ')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasIssue)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: _errorColor,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 20),
                          onPressed: i > 0 ? () => _moveUp(i) : null,
                          tooltip: '위로',
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 20),
                          onPressed: i < items.length - 1 ? () => _moveDown(i) : null,
                          tooltip: '아래로',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editItem(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteItem(i),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
