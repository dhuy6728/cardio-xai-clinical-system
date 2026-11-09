import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/api_service.dart';

class AssessmentScreen extends StatefulWidget {
  final String apiHost;
  final Map<String, dynamic>? user;

  const AssessmentScreen({
    super.key,
    required this.apiHost,
    this.user,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Input Controllers: Hoàn toàn trống, không nhập sẵn dữ liệu
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _apHiController = TextEditingController();
  final _apLoController = TextEditingController();
  final _nameController = TextEditingController();

  int _gender = 2; // 2: Nam, 1: Nữ
  int? _cholesterol; // Để trống, yêu cầu người dùng chọn
  int? _gluc; // Để trống, yêu cầu người dùng chọn
  bool _smoke = false;
  bool _alco = false;
  bool _active = false;

  bool _isLoading = false;
  FullAnalysisResult? _analysisResult;

  bool get _isDoctor => (widget.user?['role'] ?? 'patient') == 'doctor';

  String get _effectiveName {
    if (_isDoctor) {
      final name = _nameController.text.trim();
      return name.isNotEmpty ? name : 'Bệnh nhân';
    }
    return widget.user?['full_name'] ?? 'Bệnh nhân';
  }

  // Tính BMI động khi người dùng nhập chiều cao và cân nặng
  double? get _calculatedBmi {
    final h = double.tryParse(_heightController.text.trim());
    final w = double.tryParse(_weightController.text.trim());
    if (h != null && w != null && h > 0 && w > 0) {
      final val = w / ((h / 100) * (h / 100));
      return double.parse(val.toStringAsFixed(1));
    }
    return null;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _apHiController.dispose();
    _apLoController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitAnalysis() async {
    // Ẩn bàn phím
    FocusManager.instance.primaryFocus?.unfocus();

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    if (_cholesterol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn mức Cholesterol toàn phần'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_gluc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn mức Đường huyết đói'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final age = double.tryParse(_ageController.text.trim()) ?? 45.0;
      final height = double.tryParse(_heightController.text.trim()) ?? 165.0;
      final weight = double.tryParse(_weightController.text.trim()) ?? 65.0;
      final apHi = int.tryParse(_apHiController.text.trim()) ?? 120;
      final apLo = int.tryParse(_apLoController.text.trim()) ?? 80;

      final input = PatientInput(
        age: age,
        gender: _gender,
        height: height,
        weight: weight,
        apHi: apHi,
        apLo: apLo,
        cholesterol: _cholesterol!,
        gluc: _gluc!,
        smoke: _smoke ? 1 : 0,
        alco: _alco ? 1 : 0,
        active: _active ? 1 : 0,
        patientName: _effectiveName,
        userId: widget.user?['id'],
      );

      final result = await ApiService.analyzePatient(input, customHost: widget.apiHost);

      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isDoctor
                ? 'Đã phân tích lâm sàng và lưu vào kho lưu trữ!'
                : 'Đã đánh giá và lưu vào kho lưu trữ sức khỏe của bạn!'),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi phân tích: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildBmiBadge() {
    final bmi = _calculatedBmi;
    if (bmi == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Text(
          'BMI: --',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    final isObese = bmi >= 25.0;
    final isOverweight = bmi >= 23.0 && bmi < 25.0;
    final statusText = isObese ? 'Béo phì' : (isOverweight ? 'Thừa cân' : 'Bình thường');
    final bgColor = isObese ? Colors.red.shade50 : (isOverweight ? Colors.amber.shade50 : Colors.green.shade50);
    final textColor = isObese ? Colors.red.shade800 : (isOverweight ? Colors.amber.shade900 : Colors.green.shade800);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        'BMI: $bmi ($statusText)',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _isDoctor ? const Color(0xFF0F4C81) : const Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isDoctor ? 'Hội chẩn lâm sàng (Bác sĩ)' : 'Tự đánh giá nguy cơ tim mạch',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5),
            ),
            Text(
              _isDoctor ? 'Hỗ trợ quyết định y khoa minh bạch XAI' : 'Theo dõi chỉ số và phòng ngừa biến cố',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          // Đảm bảo khoảng cách cuộn dưới cùng để nút bấm không bao giờ bị che khuất bởi navigation bar
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thông tin người dùng (Bệnh nhân)
              if (!_isDoctor)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Color(0xFF0284C7), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user?['full_name'] ?? 'Bệnh nhân',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Kết quả sẽ tự động lưu vào kho lưu trữ cá nhân',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Thẻ Form Nhập Liệu
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header phần 1
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isDoctor ? 'Thông tin ca bệnh' : 'Thể trạng và sức khỏe',
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: themeColor),
                            ),
                            _buildBmiBadge(),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Nhập tên bệnh nhân (Chỉ hiển thị cho Bác sĩ)
                        if (_isDoctor) ...[
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Họ và tên bệnh nhân khám',
                              hintText: 'Nhập họ và tên bệnh nhân',
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: themeColor, width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (val) {
                              if (_isDoctor && (val == null || val.trim().isEmpty)) {
                                return 'Vui lòng nhập họ và tên bệnh nhân';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Hàng 1: Tuổi & Giới tính (Cân đối 2 cột hoàn hảo)
                        Row(
                          children: [
                            // Ô nhập tuổi
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Tuổi',
                                  hintText: 'Nhập số tuổi',
                                  prefixIcon: const Icon(Icons.cake_outlined, size: 18),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: themeColor, width: 1.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tuổi';
                                  final num = int.tryParse(v.trim());
                                  if (num == null || num < 10 || num > 120) return 'Từ 10 đến 120';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Chọn giới tính
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                                        onTap: () => setState(() => _gender = 2),
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _gender == 2 ? themeColor.withOpacity(0.12) : Colors.transparent,
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                                          ),
                                          child: Text(
                                            'Nam',
                                            style: TextStyle(
                                              fontWeight: _gender == 2 ? FontWeight.bold : FontWeight.w500,
                                              color: _gender == 2 ? themeColor : const Color(0xFF64748B),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(width: 1, color: const Color(0xFFE2E8F0)),
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                                        onTap: () => setState(() => _gender = 1),
                                        child: Container(
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _gender == 1 ? themeColor.withOpacity(0.12) : Colors.transparent,
                                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                                          ),
                                          child: Text(
                                            'Nữ',
                                            style: TextStyle(
                                              fontWeight: _gender == 1 ? FontWeight.bold : FontWeight.w500,
                                              color: _gender == 1 ? themeColor : const Color(0xFF64748B),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Hàng 2: Chiều cao & Cân nặng (Cân đối 2 cột)
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _heightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Chiều cao (cm)',
                                  hintText: 'Nhập chiều cao',
                                  prefixIcon: const Icon(Icons.height, size: 18),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: themeColor, width: 1.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập chiều cao';
                                  final val = double.tryParse(v.trim());
                                  if (val == null || val < 50 || val > 250) return 'Từ 50 - 250 cm';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Cân nặng (kg)',
                                  hintText: 'Nhập cân nặng',
                                  prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 18),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: themeColor, width: 1.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập cân nặng';
                                  final val = double.tryParse(v.trim());
                                  if (val == null || val < 20 || val > 300) return 'Từ 20 - 300 kg';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 14),

                        // Header phần 2: Huyết áp & Sinh hóa
                        Text(
                          'Huyết áp & chỉ số sinh hóa',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: themeColor),
                        ),
                        const SizedBox(height: 12),

                        // Hàng 3: Huyết áp tâm thu & Huyết áp tâm trương (Đồng đều chiều cao)
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _apHiController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'HA Tâm thu (mmHg)',
                                  hintText: 'Chỉ số tối đa',
                                  prefixIcon: const Icon(Icons.speed_outlined, size: 18),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: themeColor, width: 1.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập HA tối đa';
                                  final val = int.tryParse(v.trim());
                                  if (val == null || val < 60 || val > 260) return 'Từ 60 - 260';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _apLoController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'HA Tâm trương (mmHg)',
                                  hintText: 'Chỉ số tối thiểu',
                                  prefixIcon: const Icon(Icons.speed_outlined, size: 18),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: themeColor, width: 1.5)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập HA tối thiểu';
                                  final val = int.tryParse(v.trim());
                                  if (val == null || val < 40 || val > 180) return 'Từ 40 - 180';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Dropdown Cholesterol
                        DropdownButtonFormField<int>(
                          value: _cholesterol,
                          isDense: true,
                          decoration: InputDecoration(
                            labelText: 'Cholesterol toàn phần',
                            hintText: 'Chọn mức cholesterol',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: themeColor, width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Mức 1: Bình thường (< 5.2 mmol/L)', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 2, child: Text('Mức 2: Hơi cao (5.2 - 6.2 mmol/L)', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 3, child: Text('Mức 3: Rất cao (> 6.2 mmol/L)', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (v) => setState(() => _cholesterol = v),
                        ),
                        const SizedBox(height: 12),

                        // Dropdown Glucose
                        DropdownButtonFormField<int>(
                          value: _gluc,
                          isDense: true,
                          decoration: InputDecoration(
                            labelText: 'Đường huyết đói (Glucose)',
                            hintText: 'Chọn mức đường huyết',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: themeColor, width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Mức 1: Bình thường (< 5.6 mmol/L)', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 2, child: Text('Mức 2: Tiền ĐTĐ (5.6 - 6.9 mmol/L)', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 3, child: Text('Mức 3: Đái tháo đường (≥ 7.0 mmol/L)', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (v) => setState(() => _gluc = v),
                        ),
                        const SizedBox(height: 14),

                        // Lối sống & Thói quen (Cân đối 3 mục nằm gọn 1 hàng)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lối sống & thói quen',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildLifestyleChip(
                                      label: 'Hút thuốc',
                                      isSelected: _smoke,
                                      themeColor: themeColor,
                                      onTap: () => setState(() => _smoke = !_smoke),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildLifestyleChip(
                                      label: 'Rượu bia',
                                      isSelected: _alco,
                                      themeColor: themeColor,
                                      onTap: () => setState(() => _alco = !_alco),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildLifestyleChip(
                                      label: 'Vận động',
                                      isSelected: _active,
                                      themeColor: themeColor,
                                      onTap: () => setState(() => _active = !_active),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Nút Gửi Phân Tích & Lưu Kho
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: _isLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.analytics_outlined, size: 20),
                            label: Text(
                              _isDoctor
                                  ? 'Phân tích lâm sàng & lưu kho lưu trữ'
                                  : 'Đánh giá nguy cơ & lưu kho lưu trữ',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isLoading ? null : _submitAnalysis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Kết quả phân tích (Hiển thị sau khi submit)
              if (_analysisResult != null) ...[
                const SizedBox(height: 18),
                _buildResultCard(_analysisResult!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLifestyleChip({
    required String label,
    required bool isSelected,
    required Color themeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? themeColor : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 15,
              color: isSelected ? themeColor : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? themeColor : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(FullAnalysisResult res) {
    final pred = res.prediction;
    final prob = pred.riskProbability;
    final isHigh = prob >= 0.65;
    final isMod = prob >= 0.35 && prob < 0.65;

    final badgeColor = isHigh ? Colors.red : (isMod ? Colors.orange : Colors.green);
    final badgeText = isHigh ? "Nguy cơ cao" : (isMod ? "Nguy cơ trung bình" : "Nguy cơ thấp (An toàn)");

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: badgeColor.shade300, width: 1.2),
      ),
      color: badgeColor.shade50.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kết quả đánh giá nguy cơ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor.shade900, fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '${(prob * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: badgeColor.shade800),
              ),
            ),
            Center(
              child: Text(
                'Xác suất bệnh tim mạch (Mô hình AI)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                pred.recommendation,
                style: const TextStyle(fontSize: 12.5, height: 1.45, color: Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                SizedBox(width: 6),
                Text(
                  'Đã tự động lưu vào kho lưu trữ của hệ thống.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
