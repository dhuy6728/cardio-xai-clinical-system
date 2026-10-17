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

  // Patient parameters
  double _age = 52.0;
  int _gender = 2; // 1: Female, 2: Male
  double _height = 168.0;
  double _weight = 80.0;
  int _apHi = 140;
  int _apLo = 90;
  int _cholesterol = 2;
  int _gluc = 1;
  bool _smoke = false;
  bool _alco = false;
  bool _active = true;
  String _doctorPatientName = "Trần Văn Cao";

  bool _isLoading = false;
  FullAnalysisResult? _analysisResult;

  bool get _isDoctor => (widget.user?['role'] ?? 'patient') == 'doctor';
  String get _effectiveName => _isDoctor
      ? _doctorPatientName.trim()
      : (widget.user?['full_name'] ?? 'Bệnh nhân');

  double get _bmi => _weight / ((_height / 100) * (_height / 100));

  void _loadPreset(String presetType) {
    setState(() {
      if (presetType == 'high') {
        _doctorPatientName = "Trần Văn Cao";
        _age = 51.0;
        _gender = 2;
        _height = 168.0;
        _weight = 90.0;
        _apHi = 145;
        _apLo = 95;
        _cholesterol = 3;
        _gluc = 2;
        _smoke = true;
        _alco = false;
        _active = false;
      } else if (presetType == 'healthy') {
        _doctorPatientName = "Lê Thị Thảo";
        _age = 32.0;
        _gender = 1;
        _height = 165.0;
        _weight = 61.0;
        _apHi = 118;
        _apLo = 76;
        _cholesterol = 1;
        _gluc = 1;
        _smoke = false;
        _alco = false;
        _active = true;
      }
    });
  }

  Future<void> _submitAnalysis() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final input = PatientInput(
        age: _age,
        gender: _gender,
        height: _height,
        weight: _weight,
        apHi: _apHi,
        apLo: _apLo,
        cholesterol: _cholesterol,
        gluc: _gluc,
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
                ? 'Đã phân tích và lưu vào Kho lưu trữ bệnh án!'
                : 'Đã đánh giá và lưu vào Kho lưu trữ sức khỏe của bạn!'),
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
            content: Text('Lỗi kết nối máy chủ: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _isDoctor ? const Color(0xFF0F4C81) : const Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isDoctor ? 'Hội Chẩn Lâm Sàng (Bác Sĩ)' : 'Tự Đánh Giá Nguy Cơ Tim Mạch',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              _isDoctor ? 'Hỗ trợ quyết định y khoa minh bạch XAI' : 'Theo dõi chỉ số và phòng ngừa biến cố',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (_isDoctor)
            PopupMenuButton<String>(
              tooltip: 'Chọn ca bệnh mẫu',
              icon: const Icon(Icons.flash_on, color: Colors.amberAccent),
              onSelected: _loadPreset,
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'high', child: Text('⚠️ Ca Nguy cơ Cao (51t, HA 145/95)')),
                PopupMenuItem(value: 'healthy', child: Text('✓ Ca Khỏe mạnh (32t, HA 118/76)')),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient Identification / Profile banner
            if (!_isDoctor)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Color(0xFF0284C7), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user?['full_name'] ?? 'Bệnh nhân',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Kết quả sẽ tự động lưu vào Kho lưu trữ cá nhân',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Form Input Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _isDoctor ? '👤 Thông tin Ca Bệnh' : '📊 Thể trạng & Sức khỏe',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: themeColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(

                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _bmi >= 25 ? Colors.amber.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'BMI: ${_bmi.toStringAsFixed(1)} kg/m²',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _bmi >= 25 ? Colors.orange.shade900 : Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Chỉ hiện ô nhập tên khi là BÁC SĨ (Bệnh nhân không cần hỏi tên)
                      if (_isDoctor) ...[
                        TextFormField(
                          key: ValueKey(_doctorPatientName),
                          initialValue: _doctorPatientName,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên bệnh nhân khám',
                            prefixIcon: const Icon(Icons.person, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => _doctorPatientName = val,
                        ),
                        const SizedBox(height: 14),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: Text('Tuổi: ${_age.toInt()} tuổi', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Slider(
                              min: 30,
                              max: 65,
                              value: _age,
                              activeColor: themeColor,
                              divisions: 35,
                              label: '${_age.toInt()} tuổi',
                              onChanged: (v) => setState(() => _age = v),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Giới tính: ', style: TextStyle(fontWeight: FontWeight.w600)),
                          Radio<int>(value: 2, groupValue: _gender, activeColor: themeColor, onChanged: (v) => setState(() => _gender = v!)),
                          const Text('Nam'),
                          Radio<int>(value: 1, groupValue: _gender, activeColor: themeColor, onChanged: (v) => setState(() => _gender = v!)),
                          const Text('Nữ'),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _height.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Chiều cao (cm)',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              onChanged: (v) => _height = double.tryParse(v) ?? _height,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: _weight.toStringAsFixed(1),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Cân nặng (kg)',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              onChanged: (v) => setState(() => _weight = double.tryParse(v) ?? _weight),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 10),

                      Text(
                        '🩺 Huyết áp & Chỉ số Sinh hóa',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: themeColor),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _apHi.toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'HA Tâm thu (mmHg)',
                                helperText: 'Chỉ số tối đa',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              onChanged: (v) => _apHi = int.tryParse(v) ?? _apHi,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: _apLo.toString(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'HA Tâm trương (mmHg)',
                                helperText: 'Chỉ số tối thiểu',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              onChanged: (v) => _apLo = int.tryParse(v) ?? _apLo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<int>(
                        value: _cholesterol,
                        decoration: InputDecoration(
                          labelText: 'Cholesterol toàn phần',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Mức 1: Bình thường (< 5.2 mmol/L)')),
                          DropdownMenuItem(value: 2, child: Text('Mức 2: Hơi cao (5.2 - 6.2 mmol/L)')),
                          DropdownMenuItem(value: 3, child: Text('Mức 3: Rất cao (> 6.2 mmol/L)')),
                        ],
                        onChanged: (v) => setState(() => _cholesterol = v!),
                      ),
                      const SizedBox(height: 14),

                      DropdownButtonFormField<int>(
                        value: _gluc,
                        decoration: InputDecoration(
                          labelText: 'Đường huyết đói (Glucose)',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Mức 1: Bình thường (< 5.6 mmol/L)')),
                          DropdownMenuItem(value: 2, child: Text('Mức 2: Tiền ĐTĐ (5.6 - 6.9 mmol/L)')),
                          DropdownMenuItem(value: 3, child: Text('Mức 3: Đái tháo đường (≥ 7.0 mmol/L)')),
                        ],
                        onChanged: (v) => setState(() => _gluc = v!),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Hút thuốc', style: TextStyle(fontSize: 13)),
                              value: _smoke,
                              activeColor: themeColor,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (v) => setState(() => _smoke = v!),
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text('Vận động', style: TextStyle(fontSize: 13)),
                              value: _active,
                              activeColor: themeColor,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (v) => setState(() => _active = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.analytics_outlined),
                          label: Text(
                            _isDoctor
                                ? 'Phân tích Lâm sàng & Lưu Kho lưu trữ'
                                : 'Đánh Giá Nguy Cơ & Lưu Kho Lưu Trữ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : _submitAnalysis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Results Section
            if (_analysisResult != null) ...[
              const SizedBox(height: 20),
              _buildResultCard(_analysisResult!),
            ],
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
    final badgeText = isHigh ? "NGUY CƠ CAO" : (isMod ? "NGUY CƠ TRUNG BÌNH" : "AN TOÀN");

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: badgeColor.shade300, width: 1.5),
      ),
      color: badgeColor.shade50.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kết Quả Đánh Giá Nguy Cơ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '${(prob * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: badgeColor.shade800),
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
                style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                SizedBox(width: 6),
                Text(
                  'Đã tự động ghi nhận vào Kho lưu trữ của hệ thống.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
