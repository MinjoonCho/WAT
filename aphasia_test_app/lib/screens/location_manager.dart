import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationManagerScreen extends StatefulWidget {
  const LocationManagerScreen({super.key});

  @override
  State<LocationManagerScreen> createState() => _LocationManagerScreenState();
}

class _LocationManagerScreenState extends State<LocationManagerScreen> {
  List<String> _locations = [];
  final _addCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('locations');
    setState(() {
      _locations = raw != null
          ? List<String>.from(jsonDecode(raw))
          : ['신촌세브란스병원'];
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locations', jsonEncode(_locations));
  }

  void _add() {
    final loc = _addCtrl.text.trim();
    if (loc.isEmpty || _locations.contains(loc)) return;

    setState(() => _locations.add(loc));
    _addCtrl.clear();
    _save();
  }

  void _remove(int index) {
    setState(() => _locations.removeAt(index));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('검사 장소')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addCtrl,
                    decoration: const InputDecoration(
                      labelText: '새 검사 장소 추가',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: const Text('추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _locations.isEmpty
                ? const Center(child: Text('등록된 검사 장소가 없습니다.'))
                : ListView.builder(
                    itemCount: _locations.length,
                    itemBuilder: (ctx, i) => ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Color(0xFF9C27B0),
                      ),
                      title: Text(_locations[i]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _remove(i),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
