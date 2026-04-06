import 'dart:async';
import 'package:flutter/material.dart';
import 'admin_dashboard.dart';
import 'test_setup_screen.dart';

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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Version 1.0 — 우상단
          const Positioned(
            top: 40,
            right: 40,
            child: Text(
              'Version 1.0',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // 중앙 콘텐츠
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // WAT 타이틀
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
                // Word Association Test
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
                      TextSpan(text: 'ssociation '),
                      TextSpan(
                        text: 'T',
                        style: TextStyle(color: Color(0xFF9C27B0)),
                      ),
                      TextSpan(text: 'est'),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                // 연구자 배지
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
                    '김향희  /  예병석  /  김정완',
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

          // START 버튼 — 우하단
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

          // 숨겨진 관리자 진입 영역 — 좌하단 (data 라벨)
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
