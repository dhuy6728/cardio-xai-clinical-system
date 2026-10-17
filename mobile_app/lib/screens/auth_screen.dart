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
  String? _errorMessage;

  // Vai trò được chọn: 'patient' (Bệnh nhân) hoặc 'doctor' (Bác sĩ)
  String _selectedRole = 'patient';

  // Phương thức đăng nhập / đăng ký: 'email' hoặc 'phone'
  String _authMethod = 'email';

  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _onRoleChanged(String role) {
    setState(() {
      _selectedRole = role;
      _errorMessage = null;
    });
  }

  void _onAuthMethodChanged(String method) {
    if (_authMethod == method) return;
    setState(() {
      _authMethod = method;
      _errorMessage = null;
      _identifierController.clear();
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final idText = _identifierController.text.trim();
      final pwdText = _passwordController.text;

      if (_isLogin) {
        final res = await ApiService.login(
          identifier: idText,
          password: pwdText,
          customHost: widget.apiHost,
        );

        final user = Map<String, dynamic>.from(res['user']);
        user['role'] = _selectedRole;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Chào mừng ${user['full_name'] ?? 'bạn'} trở lại!')),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );

        widget.onAuthSuccess(user);
      } else {
        final fullName = _fullNameController.text.trim();
        final res = await ApiService.register(
          email: _authMethod == 'email' ? idText : null,
          phone: _authMethod == 'phone' ? idText : null,
          password: pwdText,
          fullName: fullName,
          role: _selectedRole,
          customHost: widget.apiHost,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_selectedRole == 'doctor'
                      ? 'Đăng ký tài khoản Bác sĩ thành công!'
                      : 'Đăng ký tài khoản Bệnh nhân thành công!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );

        final user = Map<String, dynamic>.from(res['user']);
        user['role'] = _selectedRole;
        widget.onAuthSuccess(user);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll('SocketException', 'Lỗi kết nối');
      setState(() => _errorMessage = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = _selectedRole == 'patient';
    final isEmail = _authMethod == 'email';
    final primaryColor = isPatient ? const Color(0xFF0284C7) : const Color(0xFF0F4C81);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon / Logo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPatient
                              ? [const Color(0xFF0284C7), const Color(0xFF0369A1)]
                              : [const Color(0xFF0F4C81), const Color(0xFF1E293B)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(isPatient ? '🫀' : '👨‍⚕️', style: const TextStyle(fontSize: 34)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Brand Title
                  Center(
                    child: Text(
                      isPatient ? 'CardioCare Sức Khỏe' : 'CardioCare Bác Sĩ',
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
                  const SizedBox(height: 20),

                  // 1. CHỌN VAI TRÒ (BỆNH NHÂN / BÁC SĨ)
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
                              padding: const EdgeInsets.symmetric(vertical: 9),
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
                                  const Text('🫀 ', style: TextStyle(fontSize: 15)),
                                  Text(
                                    'Bệnh Nhân',
                                    style: TextStyle(
                                      fontWeight: isPatient ? FontWeight.bold : FontWeight.w600,
                                      color: isPatient ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                      fontSize: 13.5,
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
                              padding: const EdgeInsets.symmetric(vertical: 9),
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
                                  const Text('👨‍⚕️ ', style: TextStyle(fontSize: 15)),
                                  Text(
                                    'Bác Sĩ',
                                    style: TextStyle(
                                      fontWeight: !isPatient ? FontWeight.bold : FontWeight.w600,
                                      color: !isPatient ? const Color(0xFF0F4C81) : const Color(0xFF64748B),
                                      fontSize: 13.5,
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

                  const SizedBox(height: 16),

                  // 2. CHỌN ĐĂNG NHẬP / ĐĂNG KÝ BẰNG EMAIL HOẶC SỐ ĐIỆN THOẠI
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _onAuthMethodChanged('email'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isEmail ? primaryColor.withOpacity(0.08) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isEmail ? primaryColor : const Color(0xFFCBD5E1),
                                width: isEmail ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  size: 16,
                                  color: isEmail ? primaryColor : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Dùng Email',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isEmail ? FontWeight.bold : FontWeight.w500,
                                    color: isEmail ? primaryColor : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _onAuthMethodChanged('phone'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !isEmail ? primaryColor.withOpacity(0.08) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: !isEmail ? primaryColor : const Color(0xFFCBD5E1),
                                width: !isEmail ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_android_outlined,
                                  size: 16,
                                  color: !isEmail ? primaryColor : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Dùng Số điện thoại',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: !isEmail ? FontWeight.bold : FontWeight.w500,
                                    color: !isEmail ? primaryColor : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bảo Mật Kho Lưu Trữ Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      children: [
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

                  const SizedBox(height: 16),

                  // CẢNH BÁO LỖI NỔI BẬT NẾU CÓ
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // FORM FIELDS: HOÀN TOÀN TRỐNG KÈM DÒNG CHỮ HƯỚNG DẪN MỜ
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: isPatient ? 'Họ và tên của bạn' : 'Họ và tên Bác sĩ',
                        hintText: isPatient ? 'Nhập họ và tên đầy đủ' : 'Ví dụ: Bác sĩ Nguyễn Văn A',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Email HOẶC Số điện thoại (Chỉ yêu cầu 1 trong 2)
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: isEmail ? 'Địa chỉ Email' : 'Số điện thoại',
                      hintText: isEmail
                          ? 'Nhập địa chỉ email (VD: vidu@gmail.com)'
                          : 'Nhập số điện thoại (VD: 0912345678)',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: Icon(isEmail ? Icons.email_outlined : Icons.phone_android_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return isEmail ? 'Vui lòng nhập địa chỉ email' : 'Vui lòng nhập số điện thoại';
                      }
                      final clean = v.trim();
                      if (isEmail) {
                        if (!clean.contains('@') || !clean.contains('.')) {
                          return 'Email không hợp lệ (Ví dụ: ten@domain.com)';
                        }
                      } else {
                        final phoneClean = clean.replaceAll(' ', '');
                        if (phoneClean.length < 10 || !phoneClean.startsWith('0')) {
                          return 'Số điện thoại không hợp lệ (10 chữ số, bắt đầu bằng 0)';
                        }
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // Mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu của bạn (tối thiểu 6 ký tự)',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF64748B)),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                      if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Nút Gửi (Đăng Nhập / Đăng Ký)
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
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

                  // Chuyển đổi giữa Đăng Nhập và Đăng Ký
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _formKey.currentState?.reset();
                        _identifierController.clear();
                        _passwordController.clear();
                        _fullNameController.clear();
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Chưa có tài khoản? Bấm để Đăng ký ngay'
                          : 'Đã có tài khoản? Quay lại Đăng nhập',
                      style: TextStyle(
                        color: primaryColor,
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
