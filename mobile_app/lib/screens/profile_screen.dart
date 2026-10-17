import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String apiHost;
  final VoidCallback onLogout;
  final ValueChanged<String>? onRoleChanged;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.apiHost,
    required this.onLogout,
    this.onRoleChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới (ít nhất 6 ký tự)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C81),
                foregroundColor: Colors.white,
              ),
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_newPasswordController.text != _confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mật khẩu xác nhận không trùng khớp!')),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);
                      setDialogState(() => _isLoading = true);

                      try {
                        await ApiService.changePassword(
                          email: widget.user['email'],
                          oldPassword: _oldPasswordController.text,
                          newPassword: _newPasswordController.text,
                          customHost: widget.apiHost,
                        );

                        if (mounted) {
                          nav.pop();
                          _oldPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Đổi mật khẩu thành công!'),
                              backgroundColor: Color(0xFF16A34A),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('$e'.replaceAll('Exception: ', '')),
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          );
                        }
                      } finally {
                        setDialogState(() => _isLoading = false);
                      }
                    },
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user['email'] ?? 'Chưa cập nhật';
    final name = widget.user['full_name'] ?? 'Bệnh nhân';
    final role = widget.user['role'] ?? 'patient';
    final isDoctor = role == 'doctor';
    final themeColor = isDoctor ? const Color(0xFF0F4C81) : const Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tài khoản & cài đặt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // User Avatar Card
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: themeColor.withOpacity(0.12),
                    child: Text(isDoctor ? '👨‍⚕️' : '🫀', style: const TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDoctor ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDoctor ? const Color(0xFFBFDBFE) : const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      isDoctor ? '👨‍⚕️ Tài khoản bác sĩ' : '🫀 Tài khoản bệnh nhân',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDoctor ? const Color(0xFF1D4ED8) : const Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chuyển đổi vai trò linh hoạt
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.swap_horiz, color: themeColor),
                    title: const Text('Chuyển đổi giao diện vai trò', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      isDoctor ? 'Đang ở cổng bác sĩ (Lâm sàng & XAI)' : 'Đang ở cổng bệnh nhân (Sức khỏe & bài báo)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: themeColor,
                        side: BorderSide(color: themeColor),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      onPressed: () {
                        final nextRole = isDoctor ? 'patient' : 'doctor';
                        widget.onRoleChanged?.call(nextRole);
                      },
                      child: Text(
                        isDoctor ? 'Sang bệnh nhân' : 'Sang bác sĩ',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Settings & Security Section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.security, color: themeColor),
                    title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Cập nhật mật khẩu bảo mật tài khoản', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.inventory_2_outlined, color: themeColor),
                    title: const Text('Kho lưu trữ y tế', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Đồng bộ dữ liệu an toàn & bảo mật', style: TextStyle(fontSize: 12)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.info_outline, color: themeColor),
                    title: const Text('Phiên bản ứng dụng', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('CardioCare AI v1.2.0 (XGBoost + SHAP/LIME)', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                label: const Text('Đăng xuất khỏi thiết bị', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDC2626)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: widget.onLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
