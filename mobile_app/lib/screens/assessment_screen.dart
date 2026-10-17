import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../services/api_service.dart';

class AssessmentScreen extends StatefulWidget {
  final String apiHost;
  const AssessmentScreen({Key? key, required this.apiHost}) : super(key: key);

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
  String _name = "Bệnh nhân mẫu";

  bool _isLoading = false;
  FullAnalysisResult? _analysisResult;

  double get _bmi => _weight / ((_height / 100) * (_height / 100));

  void _loadPreset(String presetType) {
    setState(() {
      if (presetType == 'high') {
        _name = "Trần Văn Cao";
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
        _name = "Lê Thị Thảo";
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
        patientName: _name,
      );

      final result = await ApiService.analyzePatient(input, customHost: widget.apiHost);
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối API: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('CardioXAI Pro', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text('Chẩn đoán Nguy cơ & XAI Cá thể hóa', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Chọn mẫu ca bệnh nhanh',
            icon: const Icon(Icons.flash_on, color: Colors.amberAccent),
            onSelected: _loadPreset,
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'high', child: Text('⚠️ Ca Nguy cơ Cao (51t, HA 145/95)')),
              const PopupMenuItem(value: 'healthy', child: Text('✓ Ca Khỏe mạnh (32t, HA 118/76)')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient Input Card
            Card(
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
                          const Text(
                            '👤 Thông tin Lâm sàng',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F4C81)),
                          ),
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
                      TextFormField(
                        key: ValueKey(_name),
                        initialValue: _name,
                        decoration: InputDecoration(
                          labelText: 'Họ và tên bệnh nhân',
                          prefixIcon: const Icon(Icons.person, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) => _name = val,
                      ),
                      const SizedBox(height: 14),
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
                              activeColor: const Color(0xFF0F4C81),
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
                          Radio<int>(value: 2, groupValue: _gender, activeColor: const Color(0xFF0F4C81), onChanged: (v) => setState(() => _gender = v!)),
                          const Text('Nam'),
                          Radio<int>(value: 1, groupValue: _gender, activeColor: const Color(0xFF0F4C81), onChanged: (v) => setState(() => _gender = v!)),
                          const Text('Nữ'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(_height),
                              initialValue: '$_height',
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Chiều cao (cm)',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              onChanged: (v) => setState(() => _height = double.tryParse(v) ?? _height),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(_weight),
                              initialValue: '$_weight',
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
                      const Divider(height: 28),
                      const Text('🩺 Huyết áp & Sinh hóa', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F4C81))),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(_apHi),
                              initialValue: '$_apHi',
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'HA Tâm thu',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              onChanged: (v) => setState(() => _apHi = int.tryParse(v) ?? _apHi),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(_apLo),
                              initialValue: '$_apLo',
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'HA Tâm trương',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              onChanged: (v) => setState(() => _apLo = int.tryParse(v) ?? _apLo),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _cholesterol,
                        decoration: InputDecoration(
                          labelText: 'Cholesterol toàn phần',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Mức 1: Bình thường (< 5.2)')),
                          DropdownMenuItem(value: 2, child: Text('Mức 2: Hơi cao (5.2 - 6.2)')),
                          DropdownMenuItem(value: 3, child: Text('Mức 3: Rất cao (> 6.2)')),
                        ],
                        onChanged: (v) => setState(() => _cholesterol = v!),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Hút thuốc', style: TextStyle(fontSize: 13)),
                              value: _smoke,
                              activeColor: const Color(0xFF0F4C81),
                              onChanged: (v) => setState(() => _smoke = v!),
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Vận động', style: TextStyle(fontSize: 13)),
                              value: _active,
                              activeColor: const Color(0xFF0F4C81),
                              onChanged: (v) => setState(() => _active = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: white, strokeWidth: 2))
                              : const Icon(Icons.query_stats, color: Colors.white),
                          label: Text(
                            _isLoading ? 'Đang phân tích XAI...' : 'Phân tích Nguy cơ & XAI',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F4C81),
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

            const SizedBox(height: 16),

            // Analysis Result Presentation
            if (_analysisResult != null) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _analysisResult!.prediction.riskLevel == 'HIGH'
                        ? [const Color(0xFFFFF5F5), const Color(0xFFFED7D7)]
                        : (_analysisResult!.prediction.riskLevel == 'MODERATE'
                            ? [const Color(0xFFFFFDF0), const Color(0xFFFEFCBF)]
                            : [const Color(0xFFF0FFF4), const Color(0xFFC6F6D5)]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _analysisResult!.prediction.riskLevel == 'HIGH'
                        ? const Color(0xFFE53E3E)
                        : (_analysisResult!.prediction.riskLevel == 'MODERATE' ? const Color(0xFFD69E2E) : const Color(0xFF38A169)),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Xác suất Bệnh Tim mạch:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _analysisResult!.prediction.riskLevel == 'HIGH' ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _analysisResult!.prediction.riskLevel,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _analysisResult!.prediction.riskPercentage,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: _analysisResult!.prediction.riskLevel == 'HIGH' ? const Color(0xFF9B2C2C) : const Color(0xFF22543D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _analysisResult!.prediction.recommendation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF2D3748)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // SHAP Waterfall Contributions Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.insights, color: Color(0xFF0F4C81), size: 20),
                          SizedBox(width: 8),
                          Text('Bóc tách SHAP (Đóng góp Biên)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F4C81))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Thanh màu thể hiện mức độ tác động của từng chỉ số lên quyết định mô hình:',
                        style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
                      ),
                      const SizedBox(height: 14),
                      ..._analysisResult!.shapContributions.map((c) {
                        final isPositive = c.shapValue > 0;
                        final double barWidthRatio = (c.shapValue.abs() / 0.5).clamp(0.05, 1.0);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${c.displayName}: ${c.actualValue}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                                  ),
                                  Text(
                                    '${isPositive ? "+" : ""}${c.shapValue.toStringAsFixed(3)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isPositive ? const Color(0xFFE53E3E) : const Color(0xFF3182CE),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: barWidthRatio,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFEDF2F7),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isPositive ? const Color(0xFFE53E3E) : const Color(0xFF3182CE),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
const Color white = Colors.white;
