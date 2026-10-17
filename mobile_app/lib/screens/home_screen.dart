import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String apiHost;
  final VoidCallback onNavigateToAssessment;

  const HomeScreen({
    Key? key,
    required this.user,
    required this.apiHost,
    required this.onNavigateToAssessment,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _selectedCategory = "Tất cả";
  List<Map<String, dynamic>> _articles = [];
  String _searchQuery = "";

  final List<String> _categories = [
    "Tất cả",
    "Dấu hiệu cảnh báo",
    "Nguyên nhân & Nguy cơ",
    "Dinh dưỡng & Ăn uống",
    "Lối sống & Thể thao",
    "Lời khuyên Chuyên gia",
  ];

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  // Dự phòng bài viết chuẩn nếu chưa kết nối tới API
  final List<Map<String, dynamic>> _fallbackArticles = [
    {
      "id": "warning-signs-heart-attack",
      "title": "5 Dấu Hiệu Cảnh Báo Nhồi Máu Cơ Tim Sớm: Khi Nào Cần Gọi Cấp Cứu 115?",
      "category": "Dấu hiệu cảnh báo",
      "read_time": "4 phút đọc",
      "author": "TS.BS Nguyễn Văn An - Hội Tim Mạch Việt Nam",
      "date": "15/10/2026",
      "icon": "🚨",
      "badge_color": "#EF4444",
      "summary": "Nhồi máu cơ tim có thể diễn ra đột ngột nhưng thường phát tín hiệu cảnh báo trước. Nắm rõ quy tắc 'Thời gian vàng' giúp cứu sống tính mạng.",
      "key_takeaways": [
        "Cơn đau thắt ngực kéo dài trên 15 phút, lan ra vai, hàm, lưng.",
        "Khó thở đột ngột, vã mồ hôi lạnh, choáng váng.",
        "Thời gian vàng: 1 - 2 giờ đầu từ khi khởi phát cơn đau.",
        "Gọi ngay cấp cứu 115, không tự ý lái xe."
      ],
      "content": "Cơn đau thắt ngực do thiếu máu cơ tim cục bộ thường bóp nghẹt sau xương ức, lan lên cổ, vai trái hoặc ra sau lưng. Khi xuất hiện cơn đau dữ dội trên 15 phút kèm khó thở và vã mồ hôi, cần ngồi nghỉ ngay và gọi 115 cấp cứu lập tức."
    },
    {
      "id": "hypertension-silent-killer",
      "title": "Tăng Huyết Áp – 'Kẻ Giết Người Thầm Lặng' & Cách Kiểm Soát Không Dùng Thuốc",
      "category": "Nguyên nhân & Nguy cơ",
      "read_time": "5 phút đọc",
      "author": "ThS.BS Trần Mai Lan - Viện Tim Mạch Quốc Gia",
      "date": "12/10/2026",
      "icon": "🩸",
      "badge_color": "#F59E0B",
      "summary": "Gần 50% người bị tăng huyết áp không hề có triệu chứng cho đến khi xảy ra tai biến. Khám phá các biện pháp hạ huyết áp bền vững.",
      "key_takeaways": [
        "Huyết áp tối ưu là dưới 120/80 mmHg; tăng huyết áp khi từ 140/90 mmHg trở lên.",
        "Giảm lượng muối ăn xuống dưới 5g/ngày giúp hạ 5-8 mmHg huyết áp.",
        "Tập thể dục 150 phút/tuần và tăng cường rau củ giàu kali.",
        "Đo huyết áp đúng cách tại nhà: Nghỉ 5 phút, ngồi thẳng lưng."
      ],
      "content": "Tăng huyết áp làm thành mạch máu bị xơ cứng và suy giảm độ đàn hồi, lâu dần dẫn đến phì đại tim, suy tim và đột quỵ. Biện pháp cốt lõi là ăn nhạt, hạn chế muối ăn, kiểm soát cân nặng và tập luyện đều đặn."
    },
    {
      "id": "mediterranean-diet-for-heart",
      "title": "Chế Độ Ăn Địa Trung Hải: 'Tấm Khiên Vàng' Bảo Vệ Thành Mạch & Giảm Mỡ Máu",
      "category": "Dinh dưỡng & Ăn uống",
      "read_time": "6 phút đọc",
      "author": "BS. Dinh dưỡng Lê Hoàng Quân",
      "date": "10/10/2026",
      "icon": "🥗",
      "badge_color": "#10B981",
      "summary": "Chế độ ăn Địa Trung Hải đã được chứng minh giảm tới 30% nguy cơ biến cố tim mạch. Hướng dẫn ứng dụng vào bữa ăn người Việt.",
      "key_takeaways": [
        "Ưu tiên chất béo tốt không bão hòa đơn (Dầu olive, quả bơ, hạt dinh dưỡng).",
        "Ăn cá béo (cá hồi, cá thu) ít nhất 2 bữa/tuần để bổ sung Omega-3.",
        "Tăng tối đa lượng chất xơ hòa tan (yến mạch, các loại đậu, rau xanh).",
        "Hạn chế thịt đỏ và thực phẩm siêu chế biến."
      ],
      "content": "Bữa ăn giàu chất chống oxy hóa, rau củ quả đa sắc tố và axit béo omega-3 giúp bảo vệ lớp nội mạc mạch máu, dọn dẹp các mảng xơ vữa mỡ máu LDL và ngăn ngừa xơ cứng động mạch."
    },
    {
      "id": "exercise-guidelines-heart-health",
      "title": "Vận Động Thể Lực Đúng Cách: Quy Tắc 150 Phút & Vùng Nhịp Tim Đích An Toàn",
      "category": "Lối sống & Thể thao",
      "read_time": "5 phút đọc",
      "author": "BS.CKI Phạm Thanh Tùng - Y học Thể thao",
      "date": "08/10/2026",
      "icon": "🏃",
      "badge_color": "#3B82F6",
      "summary": "Lười vận động là một trong 5 yếu tố hàng đầu gây suy tim. Hướng dẫn tính nhịp tim an toàn và phác đồ tập luyện từng bước.",
      "key_takeaways": [
        "Vận động ít nhất 150 phút thể lực vừa phải mỗi tuần.",
        "Vùng nhịp tim an toàn rèn luyện tim mạch: 50% - 70% nhịp tim tối đa.",
        "Đi bộ nhanh, bơi lội, đạp xe là các môn an toàn và hiệu quả nhất.",
        "Khởi động kỹ 5 phút và giảm tốc độ từ từ trước khi dừng."
      ],
      "content": "Đi bộ nhanh mỗi ngày 30 phút giúp tim đập đều đặn, kích thích tuần hoàn bàng hệ phát triển, hỗ trợ hạ huyết áp tự nhiên và tăng nồng độ HDL cholesterol tốt."
    },
    {
      "id": "10-golden-rules-heart-health",
      "title": "10 Lời Khuyên Vàng Bảo Vệ Trái Tim Suốt Đời Từ Chuyên Gia Tim Mạch",
      "category": "Lời khuyên Chuyên gia",
      "read_time": "4 phút đọc",
      "author": "Ban Chỉ Đạo Phòng Chống Tim Mạch Quốc Gia",
      "date": "01/10/2026",
      "icon": "⭐",
      "badge_color": "#0284C7",
      "summary": "10 thói quen sống cốt lõi mà bất kỳ ai từ 30 tuổi trở lên cũng nên thực hành mỗi ngày để giữ trái tim luôn khỏe mạnh và dẻo dai.",
      "key_takeaways": [
        "Nói KHÔNG với thuốc lá chủ động và thụ động.",
        "Kiểm soát cân nặng duy trì BMI từ 18.5 đến 22.9 kg/m².",
        "Ngủ đủ 7 - 8 tiếng mỗi đêm và kiểm soát căng thẳng.",
        "Khám sức khỏe định kỳ 1 lần mỗi năm."
      ],
      "content": "Một trái tim khỏe mạnh bắt đầu từ lối sống lành mạnh: không hút thuốc lá, ăn nhạt, ăn nhiều rau quả tươi, tập thể dục thường xuyên, kiểm tra huyết áp định kỳ và giữ tâm trí thư thái."
    }
  ];

  Future<void> _fetchArticles() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse("${widget.apiHost}/api/v1/articles")).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _articles = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Offline fallback
    }
    setState(() {
      _articles = _fallbackArticles;
      _isLoading = false;
    });
  }

  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return const Color(0xFF0F4C81);
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _openArticleDetail(Map<String, dynamic> art) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final badgeColor = _hexToColor(art['badge_color']);
        final takeaways = (art['key_takeaways'] as List?)?.map((e) => e.toString()).toList() ?? [];

        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${art['icon'] ?? '📖'} ${art['category'] ?? ''}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "⏱️ ${art['read_time'] ?? ''}",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    art['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tác giả: ${art['author'] ?? ''} • ${art['date'] ?? ''}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  if (takeaways.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Điểm Cốt Lõi Cần Nhớ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...takeaways.map((t) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                    Expanded(
                                      child: Text(
                                        t,
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    art['summary'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155),
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    art['content'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      "Nguồn tài liệu: Hội Tim Mạch Việt Nam (VNHA) & Hiệp hội Tim mạch Châu Âu (ESC). Thông tin mang tính tham khảo y khoa, không thay thế chẩn đoán trực tiếp của bác sĩ.",
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _articles.where((art) {
      final matchesCategory = _selectedCategory == "Tất cả" || art['category'] == _selectedCategory;
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          (art['title'] ?? '').toString().toLowerCase().contains(q) ||
          (art['summary'] ?? '').toString().toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text(
              "CardioCare Sức Khỏe",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Làm mới tin tức",
            onPressed: _fetchArticles,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchArticles,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // Banner chào đón
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4C81), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F4C81).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.health_and_safety, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Xin chào, ${widget.user['full_name'] ?? 'Bạn'}!",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const Text(
                              "Cùng chăm sóc và bảo vệ trái tim mỗi ngày",
                              style: TextStyle(color: Color(0xFFE0F2FE), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: widget.onNavigateToAssessment,
                    icon: const Icon(Icons.monitor_heart, color: Color(0xFF0F4C81), size: 18),
                    label: const Text(
                      "Chẩn Đoán & Tự Đánh Giá Nguy Cơ Ngay",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C81), fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F4C81),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4 Chỉ số vàng
            const Text(
              "4 Chỉ Số Vàng Tim Mạch",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildQuickMetric("Huyết áp", "< 120/80", "mmHg", const Color(0xFF0284C7)),
                const SizedBox(width: 8),
                _buildQuickMetric("Mỡ máu", "< 5.2", "mmol/L", const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildQuickMetric("BMI chuẩn", "18.5 - 22.9", "kg/m²", const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _buildQuickMetric("Vận động", "150", "phút/tuần", const Color(0xFF8B5CF6)),
              ],
            ),

            const SizedBox(height: 18),

            // Ô tìm kiếm bài viết
            TextField(
              decoration: InputDecoration(
                hintText: "Tìm bài viết, nguyên nhân, chế độ ăn...",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),

            const SizedBox(height: 12),

            // Category selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                      selectedColor: const Color(0xFF0F4C81),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF0F4C81) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Danh sách bài báo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Bài Báo & Lời Khuyên Chuyên Gia (${filtered.length})",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    "Không tìm thấy bài viết phù hợp với từ khóa.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              )
            else
              ...filtered.map((art) => _buildArticleCard(art)),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              unit,
              style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> art) {
    final badgeColor = _hexToColor(art['badge_color']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openArticleDetail(art),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "${art['icon'] ?? '📖'} ${art['category'] ?? ''}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "⏱️ ${art['read_time'] ?? ''}",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                art['title'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                art['summary'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "✍️ ${art['author'] ?? ''}",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text(
                    "Đọc tiếp →",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
