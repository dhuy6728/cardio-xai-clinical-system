import 'package:flutter/material.dart';
import 'screens/assessment_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(const CardioXaiApp());
}

class CardioXaiApp extends StatefulWidget {
  const CardioXaiApp({Key? key}) : super(key: key);

  @override
  State<CardioXaiApp> createState() => _CardioXaiAppState();
}

class _CardioXaiAppState extends State<CardioXaiApp> {
  // Mặc định kết nối tới máy chủ FastAPI
  String _apiHost = "http://10.0.2.2:8000"; // 10.0.2.2 cho Android Emulator hoặc http://IP_LAN:8000 cho máy thật

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardioXAI Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4E79)),
        useMaterial3: true,
      ),
      home: MainNavigation(
        apiHost: _apiHost,
        onHostChanged: (newHost) {
          setState(() {
            _apiHost = newHost;
          });
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final String apiHost;
  final ValueChanged<String> onHostChanged;

  const MainNavigation({Key? key, required this.apiHost, required this.onHostChanged}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _showSettingsDialog() {
    final controller = TextEditingController(text: widget.apiHost);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cài đặt Máy chủ API (0đ)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập địa chỉ máy chủ FastAPI (ví dụ IP Wifi máy tính hoặc URL Cloudflare Tunnel / Render):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.x:8000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              widget.onHostChanged(controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã cập nhật Host: ${controller.text.trim()}')),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      AssessmentScreen(apiHost: widget.apiHost),
      HistoryScreen(apiHost: widget.apiHost),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Khám & XAI'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Lịch sử Bệnh án'),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showSettingsDialog,
        tooltip: 'Cài đặt kết nối Server',
        child: const Icon(Icons.settings),
      ),
    );
  }
}
