import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String apiHost;
  final VoidCallback onLogout;

  const ProfileScreen({
    Key? key,
    required this.user,
    required this.apiHost,
    required this.onLogout,
  }) : super(key: key);

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
          title: const Text('Đổi Mật Khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

                      setDialogState(() => _isLoading = true);

                      try {
                        await ApiService.changePassword(
                          email: widget.user['email'],
                          oldPassword: _oldPasswordController.text,
                          newPassword: _newPasswordController.text,
                          customHost: widget.apiHost,
                        );

                        Navigator.pop(ctx);
                        _oldPasswordController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đổi mật khẩu thành công!'),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$e'.replaceAll('Exception: ', '')),
                            backgroundColor: const Color(0xFFDC2626),
                          ),
                        );
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
    final uid = widget.user['firebase_uid'] ?? 'ID_ANONYMOUS';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ Người dùng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0F4C81),
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
                    backgroundColor: const Color(0xFF0F4C81).withOpacity(0.12),
                    child: const Icon(Icons.person, size: 52, color: Color(0xFF0F4C81)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      role == 'doctor' ? 'Bác sĩ chuyên khoa' : 'Bệnh nhân theo dõi',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Settings & Security Section
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.security, color: Color(0xFF0F4C81)),
                    title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Cập nhật mật khẩu bảo mật tài khoản', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_done_outlined, color: Color(0xFF0F4C81)),
                    title: const Text('Mã định danh Firebase', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(uid, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Color(0xFF0F4C81)),
                    title: const Text('Phiên bản Ứng dụng', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('CardioXAI Mobile v1.1.0 (XGBoost + SHAP & LIME)', style: TextStyle(fontSize: 12)),
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
                label: const Text('Đăng Xuất Khỏi Thiết Bị', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
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
