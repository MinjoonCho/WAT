import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin_dashboard.dart';
import 'test_setup_screen.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  static const String _adminPassword = '0000';

  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleAdminEntry() async {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 2), () => _tapCount = 0);

    if (_tapCount < 3) return;

    _tapCount = 0;
    final granted = await _showAdminPasswordDialog();
    if (!mounted || !granted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboard()),
    );
  }

  Future<bool> _showAdminPasswordDialog() async {
    final controller = TextEditingController();
    var errorText = '';
    var submitted = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            if (submitted) return;

            if (controller.text == _adminPassword) {
              submitted = true;
              Navigator.of(ctx).pop(true);
              return;
            }

            setDialogState(() {
              errorText = '비밀번호가 올바르지 않습니다.';
            });
          }

          return AlertDialog(
            title: const Text('관리자 비밀번호'),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 4,
                    decoration: InputDecoration(
                      hintText: '4자리 숫자',
                      errorText: errorText.isEmpty ? null : errorText,
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      if (submitted) return;
                      if (errorText.isEmpty) return;
                      setDialogState(() => errorText = '');
                    },
                    onSubmitted: (_) => submit(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: submit,
                child: const Text('확인'),
              ),
            ],
          );
        },
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned(
            top: 40,
            right: 40,
            child: Text(
              'Version 1.1',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'WAT',
                  style: TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: 'W',
                        style: TextStyle(color: Color(0xFF9C27B0)),
                      ),
                      TextSpan(text: 'ord '),
                      TextSpan(
                        text: 'A',
                        style: TextStyle(color: Color(0xFF9C27B0)),
                      ),
                      TextSpan(text: 'ccess '),
                      TextSpan(
                        text: 'T',
                        style: TextStyle(color: Color(0xFF9C27B0)),
                      ),
                      TextSpan(text: 'est'),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    '김향희  /  이대희  /  김정환',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 48,
            bottom: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestSetupScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 72),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                'START',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _handleAdminEntry,
              child: Container(
                width: 120,
                height: 80,
                color: Colors.transparent,
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.only(left: 16, bottom: 12),
                child: const Text(
                  'data',
                  style: TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
