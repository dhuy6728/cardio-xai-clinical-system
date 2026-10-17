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
        title: const Text('Lịch sử Khám bệnh (SQL DB)'),
        backgroundColor: const Color(0xFF1F4E79),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Lỗi kết nối CSDL: ${snapshot.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _loadHistory, child: const Text('Thử lại')),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có hồ sơ bệnh án nào được lưu.'));
          }

          final records = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              final riskProb = (r['risk_probability'] as num).toDouble();
              final isHigh = riskProb >= 0.65;
              final isMod = riskProb >= 0.35 && riskProb < 0.65;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isHigh ? Colors.red : (isMod ? Colors.orange : Colors.green),
                    child: Text(
                      '${(riskProb * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  title: Text(
                    '${r['patient_name'] ?? "Bệnh nhân"} - Huyết áp: ${r['ap_hi']}/${r['ap_lo']} mmHg',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Tuổi: ${r['age']} | BMI: ${r['bmi']} | Ngày: ${r['created_at']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Chip(
                    label: Text(
                      r['risk_level'] ?? '',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: isHigh ? Colors.red : (isMod ? Colors.orange : Colors.green),
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
