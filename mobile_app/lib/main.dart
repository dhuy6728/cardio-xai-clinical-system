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
  // Default API host connecting to local FastAPI
  String _apiHost = "http://10.0.2.2:8000";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardioXAI Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F4C81),
          primary: const Color(0xFF0F4C81),
          secondary: const Color(0xFF00B4D8),
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F2027),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.dns, color: Color(0xFF0F4C81)),
            SizedBox(width: 8),
            Text('Cài đặt Máy chủ (0đ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Địa chỉ máy chủ FastAPI (RESTful API):',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                hintText: 'http://10.0.2.2:8000',
                prefixIcon: const Icon(Icons.link, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C81),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              widget.onHostChanged(controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã cập nhật máy chủ: ${controller.text.trim()}'),
                  backgroundColor: const Color(0xFF0F4C81),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Lưu kết nối'),
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF0F4C81).withOpacity(0.12),
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite, color: Color(0xFF0F4C81)),
              label: 'Khám & XAI',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder_shared, color: Color(0xFF0F4C81)),
              label: 'Hồ sơ SQL',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showSettingsDialog,
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        tooltip: 'Cài đặt kết nối Server',
        child: const Icon(Icons.settings, size: 18),
      ),
    );
  }
}
