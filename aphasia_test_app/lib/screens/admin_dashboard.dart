import 'package:flutter/material.dart';

import 'folder_manager.dart';
import 'location_manager.dart';
import 'template_manager.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('관리자 설정'),
            SizedBox(width: 8),
            Icon(Icons.settings, color: Color(0xFF9C27B0), size: 22),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AdminMenuCard(
            icon: Icons.list_alt,
            title: '문항 관리',
            subtitle: '기본 템플릿 확인, 문항 수정, 누락 항목 점검',
            onTap: () => _open(context, const TemplateManager()),
          ),
          const SizedBox(height: 12),
          _AdminMenuCard(
            icon: Icons.place_outlined,
            title: '검사 장소',
            subtitle: '검사 장소 목록 추가 및 수정',
            onTap: () => _open(context, const LocationManagerScreen()),
          ),
          const SizedBox(height: 12),
          _AdminMenuCard(
            icon: Icons.folder_open,
            title: '데이터 확인',
            subtitle: '저장된 환자 폴더 확인 및 공유',
            onTap: () => _open(context, const FolderManagerScreen()),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7D7EC)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF9C27B0), size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
