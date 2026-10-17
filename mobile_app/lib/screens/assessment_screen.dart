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
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá Nguy cơ & XAI'),
        backgroundColor: const Color(0xFF1F4E79),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patient Input Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🩺 Chỉ số Lâm sàng & Sinh hóa',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F4E79)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _name,
                        decoration: const InputDecoration(labelText: 'Tên bệnh nhân', prefixIcon: Icon(Icons.person)),
                        onChanged: (val) => _name = val,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Tuổi: ${_age.toInt()} tuổi'),
                          ),
                          Expanded(
                            flex: 2,
                            child: Slider(
                              min: 30,
                              max: 65,
                              value: _age,
                              divisions: 35,
                              label: '${_age.toInt()}',
                              onChanged: (v) => setState(() => _age = v),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Giới tính: '),
                          Radio<int>(value: 2, groupValue: _gender, onChanged: (v) => setState(() => _gender = v!)),
                          const Text('Nam'),
                          Radio<int>(value: 1, groupValue: _gender, onChanged: (v) => setState(() => _gender = v!)),
                          const Text('Nữ'),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '$_height',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Chiều cao (cm)'),
                              onChanged: (v) => setState(() => _height = double.tryParse(v) ?? _height),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: '$_weight',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Cân nặng (kg)'),
                              onChanged: (v) => setState(() => _weight = double.tryParse(v) ?? _weight),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BMI: ${_bmi.toStringAsFixed(1)} kg/m² (${_bmi >= 30 ? "Béo phì" : (_bmi >= 25 ? "Tiền béo phì" : "Bình thường")})',
                        style: TextStyle(fontWeight: FontWeight.w600, color: _bmi >= 25 ? Colors.deepOrange : Colors.green),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '$_apHi',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Huyết áp tâm thu (ap_hi)'),
                              onChanged: (v) => setState(() => _apHi = int.tryParse(v) ?? _apHi),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: '$_apLo',
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Huyết áp tâm trương (ap_lo)'),
                              onChanged: (v) => setState(() => _apLo = int.tryParse(v) ?? _apLo),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _cholesterol,
                        decoration: const InputDecoration(labelText: 'Cholesterol'),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Mức 1: Bình thường (< 5.2 mmol/L)')),
                          DropdownMenuItem(value: 2, child: Text('Mức 2: Hơi cao (5.2 - 6.2 mmol/L)')),
                          DropdownMenuItem(value: 3, child: Text('Mức 3: Rất cao (> 6.2 mmol/L)')),
                        ],
                        onChanged: (v) => setState(() => _cholesterol = v!),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hút thuốc lá'),
                        value: _smoke,
                        onChanged: (v) => setState(() => _smoke = v!),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Vận động thể lực đều đặn'),
                        value: _active,
                        onChanged: (v) => setState(() => _active = v!),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.analytics),
                          label: Text(_isLoading ? 'Đang phân tích...' : 'Phân tích Nguy cơ & XAI', style: const TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F4E79), foregroundColor: Colors.white),
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
              Card(
                color: _analysisResult!.prediction.riskLevel == 'HIGH'
                    ? const Color(0xFFFDF2F2)
                    : (_analysisResult!.prediction.riskLevel == 'MODERATE' ? const Color(0xFFFEFCE8) : const Color(0xFFF0FDF4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _analysisResult!.prediction.riskLevel == 'HIGH'
                        ? Colors.red
                        : (_analysisResult!.prediction.riskLevel == 'MODERATE' ? Colors.orange : Colors.green),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Xác suất Nguy cơ Tim mạch: ${_analysisResult!.prediction.riskPercentage}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _analysisResult!.prediction.riskLevel == 'HIGH' ? Colors.red.shade900 : Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Phân tầng: ${_analysisResult!.prediction.riskLevel}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _analysisResult!.prediction.recommendation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // SHAP Waterfall Contributions
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔍 Giải thích SHAP: Tác động của từng chỉ số',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F4E79)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '🟥 Đỏ: Làm tăng nguy cơ | 🟦 Xanh: Bảo vệ / Giảm nguy cơ',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ..._analysisResult!.shapContributions.map((c) {
                        final isPositive = c.shapValue > 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text('${c.displayName} (${c.actualValue})', style: const TextStyle(fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPositive ? Colors.red.shade100 : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${isPositive ? "+" : ""}${c.shapValue.toStringAsFixed(3)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isPositive ? Colors.red.shade900 : Colors.blue.shade900,
                                    ),
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
