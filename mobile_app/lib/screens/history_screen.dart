import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  final String apiHost;
  const HistoryScreen({Key? key, required this.apiHost}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = ApiService.fetchHistory(customHost: widget.apiHost);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Hồ sơ Bệnh án SQL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text('Đồng bộ CSDL Quan hệ thời gian thực', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới danh sách',
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
                      'Không thể kết nối đến máy chủ SQL:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black82),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử kết nối lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C81),
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
                children: const [
                  Icon(Icons.folder_open, size: 54, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Chưa có hồ sơ bệnh án nào được ghi nhận.', style: TextStyle(color: Colors.grey)),
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

              final Color tagColor = isHigh ? const Color(0xFFE53E3E) : (isMod ? const Color(0xFFD69E2E) : const Color(0xFF38A169));
              final Color bgColor = isHigh ? const Color(0xFFFFF5F5) : (isMod ? const Color(0xFFFFFDF0) : const Color(0xFFF0FFF4));

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: tagColor.withOpacity(0.3), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${(riskProb * 100).toInt()}%',
                            style: TextStyle(color: tagColor, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r['patient_name'] ?? 'Bệnh nhân',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A202C)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: tagColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    r['risk_level'] ?? '',
                                    style: TextStyle(color: tagColor, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'HA: ${r['ap_hi']}/${r['ap_lo']} mmHg • BMI: ${r['bmi']} • Tuổi: ${r['age']}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568), fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Thời gian: ${r['created_at']}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFA0AEC0)),
                            ),
                          ],
                        ),
                      ),
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
}
