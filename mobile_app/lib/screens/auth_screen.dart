import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  final String apiHost;
  final Function(Map<String, dynamic> user) onAuthSuccess;

  const AuthScreen({
    super.key,
    required this.apiHost,
    required this.onAuthSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Vai trò được chọn: 'patient' (Bệnh nhân) hoặc 'doctor' (Bác sĩ)
  String _selectedRole = 'patient';

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _fullNameController;
  final _phoneController = TextEditingController(text: '0901234567');

  @override
  void initState() {
    super.initState();
    _applyRoleDefaults();
  }

  void _applyRoleDefaults() {
    if (_selectedRole == 'patient') {
      _emailController = TextEditingController(text: 'benhnhan@cardioxai.vn');
      _passwordController = TextEditingController(text: 'matkhau123');
      _fullNameController = TextEditingController(text: 'Nguyễn Văn Bệnh Nhân');
    } else {
      _emailController = TextEditingController(text: 'bacsi@cardioxai.vn');
      _passwordController = TextEditingController(text: 'matkhau123');
      _fullNameController = TextEditingController(text: 'Bác sĩ Nguyễn Văn A');
    }
  }

  void _onRoleChanged(String role) {
    setState(() {
      _selectedRole = role;
      _applyRoleDefaults();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final res = await ApiService.login(
          email: _emailController.text,
          password: _passwordController.text,
          customHost: widget.apiHost,
        );

        final user = Map<String, dynamic>.from(res['user']);
        // Gán hoặc tôn trọng vai trò đã chọn
        user['role'] = _selectedRole;

        widget.onAuthSuccess(user);
      } else {
        final res = await ApiService.register(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
          phone: _phoneController.text,
          role: _selectedRole,
          customHost: widget.apiHost,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedRole == 'doctor'
                ? 'Đăng ký tài khoản Bác sĩ thành công!'
                : 'Đăng ký tài khoản Bệnh nhân thành công!'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );

        final user = Map<String, dynamic>.from(res['user']);
        user['role'] = _selectedRole;
        widget.onAuthSuccess(user);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = _selectedRole == 'patient';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: isPatient ? const Color(0xFF0284C7) : const Color(0xFF0F4C81),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isPatient ? const Color(0xFF0284C7) : const Color(0xFF0F4C81)).withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(isPatient ? '🫀' : '👨‍⚕️', style: const TextStyle(fontSize: 34)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      isPatient ? 'CardioXAI Sức Khỏe' : 'CardioXAI Bác Sĩ',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      isPatient
                          ? 'Theo dõi sức khỏe tim mạch & tự đánh giá nguy cơ'
                          : 'Hệ thống hỗ trợ hội chẩn & giải thích lâm sàng XAI',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // YÊU CẦU CHỌN VAI TRÒ (BỆNH NHÂN / BÁC SĨ)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _onRoleChanged('patient'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isPatient ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isPatient
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🫀 ', style: TextStyle(fontSize: 16)),
                                  Text(
                                    'Bệnh Nhân',
                                    style: TextStyle(
                                      fontWeight: isPatient ? FontWeight.bold : FontWeight.w600,
                                      color: isPatient ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _onRoleChanged('doctor'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isPatient ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isPatient
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('👨‍⚕️ ', style: TextStyle(fontSize: 16)),
                                  Text(
                                    'Bác Sĩ',
                                    style: TextStyle(
                                      fontWeight: !isPatient ? FontWeight.bold : FontWeight.w600,
                                      color: !isPatient ? const Color(0xFF0F4C81) : const Color(0xFF64748B),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Bảo mật kho lưu trữ Badge (không dùng chữ SQL)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_outline, size: 16, color: Color(0xFF16A34A)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bảo mật danh tính & đồng bộ Kho lưu trữ an toàn',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Form Fields
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: isPatient ? 'Họ và tên của bạn' : 'Họ và tên Bác sĩ',
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPatient ? const Color(0xFF0284C7) : const Color(0xFF0F4C81),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _isLogin
                                  ? (isPatient ? 'Đăng Nhập Bệnh Nhân' : 'Đăng Nhập Bác Sĩ')
                                  : (isPatient ? 'Đăng Ký Tài Khoản Bệnh Nhân' : 'Đăng Ký Tài Khoản Bác Sĩ'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Toggle Login/Register
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? 'Chưa có tài khoản? Bấm để Đăng ký ngay'
                          : 'Đã có tài khoản? Quay lại Đăng nhập',
                      style: TextStyle(
                        color: isPatient ? const Color(0xFF0284C7) : const Color(0xFF0F4C81),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
