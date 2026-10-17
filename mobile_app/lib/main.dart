import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/assessment_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';

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
  String _apiHost = "http://10.0.2.2:8000";

  // Thông tin người dùng sau khi đăng nhập (Firebase / Local Auth)
  Map<String, dynamic>? _currentUser;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardioXAI Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F4C81),
          primary: const Color(0xFF0F4C81),
          secondary: const Color(0xFF0284C7),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F4C81),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: _currentUser == null
          ? AuthScreen(
              apiHost: _apiHost,
              onAuthSuccess: (user) {
                setState(() {
                  _currentUser = user;
                });
              },
            )
          : MainNavigation(
              user: _currentUser!,
              apiHost: _apiHost,
              onHostChanged: (newHost) => setState(() => _apiHost = newHost),
              onLogout: () => setState(() => _currentUser = null),
            ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final Map<String, dynamic> user;
  final String apiHost;
  final ValueChanged<String> onHostChanged;
  final VoidCallback onLogout;

  const MainNavigation({
    Key? key,
    required this.user,
    required this.apiHost,
    required this.onHostChanged,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        user: widget.user,
        apiHost: widget.apiHost,
        onNavigateToAssessment: () => setState(() => _currentIndex = 1),
      ),
      AssessmentScreen(apiHost: widget.apiHost),
      HistoryScreen(apiHost: widget.apiHost),
      ProfileScreen(
        user: widget.user,
        apiHost: widget.apiHost,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF0F4C81).withOpacity(0.12),
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF0F4C81)),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart, color: Color(0xFF0F4C81)),
            label: 'Chẩn đoán',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_shared, color: Color(0xFF0F4C81)),
            label: 'Hồ sơ Bệnh',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF0F4C81)),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
