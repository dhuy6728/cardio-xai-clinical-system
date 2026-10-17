import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  final String apiHost;
  final Map<String, dynamic>? user;

  const HistoryScreen({
    super.key,
    required this.apiHost,
    this.user,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  bool get _isDoctor => (widget.user?['role'] ?? 'patient') == 'doctor';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = ApiService.fetchHistory(
        customHost: widget.apiHost,
      );
    });
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
              _isDoctor ? 'Kho lưu trữ bệnh án' : 'Kho lưu trữ sức khỏe',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              _isDoctor ? 'Danh sách bệnh nhân & hồ sơ lâm sàng' : 'Lịch sử ngày khám & tình trạng nguy cơ',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới kho lưu trữ',
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 54, color: Colors.redAccent),
                    const SizedBox(height: 14),
                    Text(
                      'Không thể kết nối đến Kho lưu trữ:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử kết nối lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _loadHistory,
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 54, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    _isDoctor
                        ? 'Chưa có hồ sơ bệnh án nào trong Kho lưu trữ.'
                        : 'Bạn chưa có lần chẩn đoán nào trong Kho lưu trữ.\nHãy vào mục "Chẩn đoán" để bắt đầu.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final records = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              final riskProb = (r['risk_probability'] as num).toDouble();
              final isHigh = riskProb >= 0.65;
              final isMod = riskProb >= 0.35 && riskProb < 0.65;

              final badgeColor = isHigh ? Colors.red : (isMod ? Colors.orange : Colors.green);
              final statusText = isHigh ? "Nguy cơ cao" : (isMod ? "Nguy cơ trung bình" : "Nguy cơ thấp (An toàn)");

              // Formatted date string
              final dateStr = r['created_at'] != null
                  ? r['created_at'].toString().replaceFirst('T', ' ').split('.').first
                  : 'Gần đây';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Bác sĩ hiển thị tên bệnh nhân, Bệnh nhân hiển thị ngày tháng
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  _isDoctor ? Icons.person : Icons.calendar_today,
                                  size: 16,
                                  color: themeColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isDoctor
                                        ? '${r['patient_name'] ?? 'Bệnh nhân'} (#${r['id']})'
                                        : 'Ngày khám: $dateStr',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$statusText (${(riskProb * 100).toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: badgeColor.shade900,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_isDoctor) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Thời gian khám: $dateStr',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],

                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniMetric('Huyết áp', '${r['ap_hi']}/${r['ap_lo']} mmHg'),
                            _buildMiniMetric('BMI', '${r['bmi'] ?? '--'} kg/m²'),
                            _buildMiniMetric('Tuổi', '${r['age']} tuổi'),
                            _buildMiniMetric('Cholesterol', 'Mức ${r['cholesterol']}'),
                          ],
                        ),
                      ),

                      if (r['recommendation'] != null && r['recommendation'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '💡 ${r['recommendation']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
      ],
    );
  }
}
