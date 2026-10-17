import 'package:flutter/material.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/assessment_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const CardioCareApp());
}

class CardioCareApp extends StatefulWidget {
  const CardioCareApp({super.key});

  @override
  State<CardioCareApp> createState() => _CardioCareAppState();
}

class _CardioCareAppState extends State<CardioCareApp> {
  // Mặc định kết nối tới máy chủ FastAPI
  String _apiHost = "http://10.0.2.2:8000";

  // Thông tin người dùng sau khi đăng nhập (Bác sĩ hoặc Bệnh nhân)
  Map<String, dynamic>? _currentUser;

  @override
  Widget build(BuildContext context) {
    final isDoctor = (_currentUser?['role'] ?? 'patient') == 'doctor';
    final primaryColor = isDoctor ? const Color(0xFF0F4C81) : const Color(0xFF0284C7);

    return MaterialApp(
      title: 'CardioCare AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: isDoctor ? const Color(0xFF0284C7) : const Color(0xFF10B981),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
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
              onRoleChanged: (newRole) => setState(() => _currentUser!['role'] = newRole),
              onLogout: () => setState(() => _currentUser = null),
            ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final Map<String, dynamic> user;
  final String apiHost;
  final ValueChanged<String> onHostChanged;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onLogout;

  const MainNavigation({
    super.key,
    required this.user,
    required this.apiHost,
    required this.onHostChanged,
    required this.onRoleChanged,
    required this.onLogout,
  });


  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDoctor = (widget.user['role'] ?? 'patient') == 'doctor';
    final themeColor = isDoctor ? const Color(0xFF0F4C81) : const Color(0xFF0284C7);

    // GIAO DIỆN KHÁC NHAU GIỮA BỆNH NHÂN VÀ BÁC SĨ
    final List<Widget> screens;
    final List<NavigationDestination> destinations;

    if (!isDoctor) {
      // 1. GIAO DIỆN BỆNH NHÂN
      screens = [
        // Tab 0: Trang chủ bài báo, kiến thức sức khỏe
        HomeScreen(
          user: widget.user,
          apiHost: widget.apiHost,
          onNavigateToAssessment: () => setState(() => _currentIndex = 1),
        ),
        // Tab 1: Chẩn đoán tự đánh giá (Không hỏi tên)
        AssessmentScreen(
          apiHost: widget.apiHost,
          user: widget.user,
        ),
        // Tab 2: Kho lưu trữ sức khỏe (Ngày tháng & tình trạng)
        HistoryScreen(
          apiHost: widget.apiHost,
          user: widget.user,
        ),
        // Tab 3: Cá nhân
        ProfileScreen(
          user: widget.user,
          apiHost: widget.apiHost,
          onLogout: widget.onLogout,
          onRoleChanged: widget.onRoleChanged,
        ),
      ];

      destinations = [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: themeColor),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: const Icon(Icons.monitor_heart_outlined),
          selectedIcon: Icon(Icons.monitor_heart, color: themeColor),
          label: 'Chẩn đoán',
        ),
        NavigationDestination(
          icon: const Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2, color: themeColor),
          label: 'Kho lưu trữ',
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: themeColor),
          label: 'Cá nhân',
        ),
      ];
    } else {
      // 2. GIAO DIỆN BÁC SĨ
      screens = [
        // Tab 0: Khám lâm sàng & XAI (Có nhập Tên bệnh nhân)
        AssessmentScreen(
          apiHost: widget.apiHost,
          user: widget.user,
        ),
        // Tab 1: Kho lưu trữ bệnh án (Quản lý theo Tên bệnh nhân)
        HistoryScreen(
          apiHost: widget.apiHost,
          user: widget.user,
        ),
        // Tab 2: Cẩm nang y khoa & Hướng dẫn ESC
        HomeScreen(
          user: widget.user,
          apiHost: widget.apiHost,
          onNavigateToAssessment: () => setState(() => _currentIndex = 0),
        ),
        // Tab 3: Cá nhân
        ProfileScreen(
          user: widget.user,
          apiHost: widget.apiHost,
          onLogout: widget.onLogout,
          onRoleChanged: widget.onRoleChanged,
        ),
      ];

      destinations = [
        NavigationDestination(
          icon: const Icon(Icons.medical_services_outlined),
          selectedIcon: Icon(Icons.medical_services, color: themeColor),
          label: 'Khám & XAI',
        ),
        NavigationDestination(
          icon: const Icon(Icons.folder_shared_outlined),
          selectedIcon: Icon(Icons.folder_shared, color: themeColor),
          label: 'Kho lưu trữ',
        ),
        NavigationDestination(
          icon: const Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book, color: themeColor),
          label: 'Cẩm nang',
        ),
        NavigationDestination(
          icon: const Icon(Icons.badge_outlined),
          selectedIcon: Icon(Icons.badge, color: themeColor),
          label: 'Bác sĩ',
        ),
      ];
    }

    return Scaffold(
      body: screens[_currentIndex < screens.length ? _currentIndex : 0],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: themeColor.withOpacity(0.12),
        selectedIndex: _currentIndex < destinations.length ? _currentIndex : 0,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: destinations,
      ),
    );
  }
}
