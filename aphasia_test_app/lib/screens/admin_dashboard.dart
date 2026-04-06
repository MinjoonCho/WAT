import 'package:flutter/material.dart';
import 'template_manager.dart';
import 'folder_manager.dart';
import 'location_manager.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 관리자 대시보드 — 탭: 문항 관리 / 검사 장소 / 데이터 확인
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('관리자 설정'),
          bottom: const TabBar(
            indicatorColor: Color(0xFF9C27B0),
            labelColor: Color(0xFF9C27B0),
            tabs: [
              Tab(text: '문항 관리'),
              Tab(text: '검사 장소'),
              Tab(text: '데이터 확인'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TemplateManager(),
            LocationManagerScreen(),
            FolderManagerScreen(),
          ],
        ),
      ),
    );
  }
}
