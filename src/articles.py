"""
Database of Professional Medical Articles & Health Guidance for Patients.
Curated based on guidelines from the European Society of Cardiology (ESC),
American Heart Association (AHA), and Vietnam National Heart Association (VNHA).
"""

from typing import Dict, List, Optional

ARTICLES_DATA: List[Dict] = [
    {
        "id": "warning-signs-heart-attack",
        "title": "5 dấu hiệu cảnh báo nhồi máu cơ tim sớm: Khi nào cần gọi cấp cứu 115?",
        "category": "Dấu hiệu cảnh báo",
        "category_id": "warning",
        "read_time": "4 phút đọc",
        "author": "TS.BS Nguyễn Văn An - Hội Tim Mạch Việt Nam",
        "date": "15/10/2026",
        "icon": "🚨",
        "badge_color": "#EF4444",
        "summary": "Nhồi máu cơ tim có thể diễn ra đột ngột nhưng thường phát tín hiệu cảnh báo trước nhiều giờ hoặc nhiều ngày. Nắm rõ quy tắc 'Thời gian vàng' giúp cứu sống tính mạng.",
        "key_takeaways": [
            "Cơn đau thắt ngực kéo dài trên 15 phút, lan ra vai, hàm, lưng là dấu hiệu kinh điển.",
            "Khó thở đột ngột, vã mồ hôi lạnh, choáng váng đặc biệt nguy hiểm ở người cao tuổi và phụ nữ.",
            "Quy tắc thời gian vàng: 1 - 2 giờ đầu từ khi khởi phát cơn đau là lúc tái thông mạch vành hiệu quả nhất.",
            "Không tự ý lái xe đi cấp cứu, hãy gọi ngay 115 hoặc nhờ người nhà đưa đến cơ sở y tế gần nhất."
        ],
        "content": """
### 1. Nhận diện cơn đau thắt ngực điển hình
Cơn đau thắt ngực do thiếu máu cơ tim cục bộ thường có các đặc điểm:
* **Cảm giác:** Bóp nghẹt, đè nặng như có tảng đá đè lên ngực trái hoặc sau xương ức.
* **Vị trí lan:** Cơn đau thường lan lên cổ, hàm dưới, vai trái, cánh tay trái hoặc lan ra sau lưng giữa hai bả vai.
* **Thời gian:** Kéo dài trên 10-15 phút và không giảm hẳn khi nghỉ ngơi hoặc ngậm thuốc giãn mạch dưới lưỡi.

### 2. Dấu hiệu không điển hình (Đặc biệt ở phụ nữ & người cao tuổi)
Nhiều bệnh nhân nữ hoặc người bệnh đái tháo đường không trải qua cơn đau ngực dữ dội, mà thay vào đó là:
* Khó thở không giải thích được, cảm giác hụt hơi.
* Buồn nôn, đầy bụng, ợ nóng giống triệu chứng trào ngược dạ dày.
* Mệt mỏi cực độ, kiệt sức dù không làm việc nặng.
* Vã mồ hôi lạnh đầm đìa, hoa mắt, chóng mặt hoặc ngất xỉu.

### 3. Quy tắc xử trí khẩn cấp trong 5 phút đầu
1. **Dừng ngay mọi hoạt động:** Ngồi hoặc nằm tựa lưng 45 độ, thả lỏng cúc áo cổ áo.
2. **Gọi cấp cứu 115 ngay lập tức:** Báo rõ nghi ngờ nhồi máu cơ tim để đội ngũ cấp cứu chuẩn bị trang thiết bị khử rung và thuốc.
3. **Sử dụng thuốc (Nếu đã được bác sĩ kê đơn trước đó):** Dùng viên ngậm Nitroglycerin hoặc Aspirin theo chỉ định của bác sĩ chuyên khoa.
4. **Không tự lái xe:** Tuyệt đối không tự điều khiển phương tiện giao thông.
        """
    },
    {
        "id": "hypertension-silent-killer",
        "title": "Tăng huyết áp – 'Kẻ giết người thầm lặng' & cách kiểm soát không dùng thuốc",
        "category": "Nguyên nhân & nguy cơ",
        "category_id": "causes",
        "read_time": "5 phút đọc",
        "author": "ThS.BS Trần Mai Lan - Viện Tim Mạch Quốc Gia",
        "date": "12/10/2026",
        "icon": "🩸",
        "badge_color": "#F59E0B",
        "summary": "Gần 50% người bị tăng huyết áp không hề có triệu chứng cho đến khi xảy ra tai biến đột quỵ hoặc suy tim. Khám phá cơ chế và biện pháp hạ huyết áp bền vững.",
        "key_takeaways": [
            "Huyết áp tối ưu là dưới 120/80 mmHg; tăng huyết áp khi từ 140/90 mmHg trở lên.",
            "Giảm lượng muối ăn xuống dưới 5g/ngày (khoảng 1 thìa cà phê gạt) giúp hạ 5-8 mmHg huyết áp.",
            "Hạn chế rượu bia, tăng cường rau xanh giàu kali (chuối, rau bina, bơ) giúp ổn định thành mạch.",
            "Đo huyết áp đúng cách tại nhà: Nghỉ 5 phút, ngồi thẳng lưng, tay đặt ngang tầm tim."
        ],
        "content": """
### 1. Tại sao tăng huyết áp lại vô cùng nguy hiểm?
Áp lực máu trong lòng mạch tăng cao kéo dài làm tổn thương lớp tế bào nội mạc mạch máu, dẫn đến:
* **Xơ vữa động mạch:** Mạch máu trở nên xơ cứng, hẹp lại và dễ hình thành cục máu đông.
* **Phì đại thất trái & Suy tim:** Tim phải gồng mình co bóp chống lại áp lực cao, lâu dần thành tim dày lên rồi giãn ra gây suy tim.
* **Đột quỵ não:** Vỡ mạch máu não (xuất huyết) hoặc tắc mạch não (nhồi máu não).
* **Suy thận mạn:** Tổn thương các mao mạch lọc máu ở cầu thận.

### 2. Các biện pháp hạ áp tự nhiên đã được kiểm chứng y khoa
* **Chế độ ăn giảm muối:** Giới hạn natri < 2.000 mg/ngày (tương đương 5g muối ăn). Hạn chế thực phẩm chế biến sẵn, đồ đóng hộp, nước mắm, chấm ngập thức ăn.
* **Chế độ ăn DASH (Dietary Approaches to Stop Hypertension):** Giàu rau củ quả, hạt ngũ cốc nguyên cám, sữa ít béo; giảm chất béo bão hòa.
* **Tập luyện thể thao 150 phút/tuần:** Đi bộ nhanh, bơi lội, đạp xe mức độ vừa phải giúp mạch máu đàn hồi tốt hơn.
* **Kiểm soát cân nặng:** Cứ giảm 1 kg cân nặng dư thừa, huyết áp tâm thu có thể giảm tương ứng khoảng 1 mmHg.
        """
    },
    {
        "id": "mediterranean-diet-for-heart",
        "title": "Chế độ ăn Địa Trung Hải: 'Tấm khiên vàng' bảo vệ thành mạch & giảm mỡ máu",
        "category": "Dinh dưỡng & ăn uống",
        "category_id": "nutrition",
        "read_time": "6 phút đọc",
        "author": "BS. Dinh dưỡng Lê Hoàng Quân - ĐH Y Hà Nội",
        "date": "10/10/2026",
        "icon": "🥗",
        "badge_color": "#10B981",
        "summary": "Nghiên cứu PREDIMED chứng minh chế độ ăn Địa Trung Hải giảm tới 30% nguy cơ biến cố tim mạch lớn. Hướng dẫn ứng dụng thực đơn này phù hợp với ẩm thực Việt Nam.",
        "key_takeaways": [
            "Ưu tiên chất béo tốt không bão hòa đơn (Dầu olive nguyên chất, quả bơ, hạt điều, hạt óc chó).",
            "Ăn cá béo (cá hồi, cá thu, cá trích) ít nhất 2 bữa/tuần để bổ sung Omega-3 bảo vệ tim.",
            "Tăng tối đa lượng chất xơ hòa tan (yến mạch, đậu đỗ, rau lá xanh) giúp cuốn trôi cholesterol xấu LDL.",
            "Hạn chế thịt đỏ (thịt bò, thịt heo), thay bằng thịt gia cầm nạc hoặc đạm thực vật."
        ],
        "content": """
### 1. Kim tự tháp dinh dưỡng Địa Trung Hải là gì?
Chế độ ăn Địa Trung Hải không chỉ là một chế độ ăn kiêng mà là một phong cách sống đã được UNESCO công nhận là di sản văn hóa phi vật thể:
* **Tầng đáy (Ăn mỗi ngày):** Rau củ quả đa màu sắc, ngũ cốc nguyên cám, các loại đậu, hạt dinh dưỡng và dầu olive nguyên chất (Extra Virgin).
* **Tầng giữa (Ăn 2-3 lần/tuần):** Cá, hải sản (đặc biệt là cá béo giàu Omega-3), thịt gia cầm, trứng, phô mai và sữa chua lên men tự nhiên.
* **Tầng đỉnh (Hạn chế tối đa):** Thịt đỏ, thịt chế biến sẵn (xúc xích, thịt xông khói), đồ ngọt, nước ngọt có ga và bánh kẹo công nghiệp.

### 2. Ứng dụng khéo léo vào bữa ăn gia đình Việt Nam
* **Thay dầu mỡ động vật:** Chuyển sang dùng dầu hạt cải, dầu đậu nành hoặc dầu olive khi chế biến món ăn; hạn chế chiên xào ngập dầu, chuyển sang luộc, hấp, nướng không dầu.
* **Bổ sung rau củ địa phương:** Rau ngót, rau muống, súp lơ xanh, mồng tơi, cà chua chín đều là nguồn chất chống oxy hóa tuyệt vời.
* **Đổi cơm trắng sang gạo lứt/yến mạch:** Giúp ổn định đường huyết sau ăn và tăng đào thải mỡ máu qua đường tiêu hóa.
        """
    },
    {
        "id": "exercise-guidelines-heart-health",
        "title": "Vận động thể lực đúng cách cho trái tim: Quy tắc 150 phút & nhịp tim đích",
        "category": "Lối sống & thể thao",
        "category_id": "lifestyle",
        "read_time": "5 phút đọc",
        "author": "BS.CKI Phạm Thanh Tùng - Chuyên khoa Y học Thể thao",
        "date": "08/10/2026",
        "icon": "🏃",
        "badge_color": "#3B82F6",
        "summary": "Tập luyện quá sức có thể gây hại cho tim, nhưng lười vận động là yếu tố nguy cơ hàng đầu. Hướng dẫn tính nhịp tim an toàn và phác đồ tập luyện từng bước.",
        "key_takeaways": [
            "Hiệp hội Tim Mạch khuyến cáo: Tối thiểu 150 phút vận động vừa phải hoặc 75 phút vận động mạnh mỗi tuần.",
            "Công thức tính nhịp tim tối đa: 220 - Tuổi của bạn.",
            "Vùng nhịp tim rèn luyện tim mạch an toàn: 50% - 70% nhịp tim tối đa.",
            "Luôn khởi động 5-10 phút trước khi tập và giảm tốc độ từ từ trước khi kết thúc."
        ],
        "content": """
### 1. Lợi ích của vận động thể lực đối với cơ tim
Khi bạn vận động thể chất thường xuyên:
* Cơ tim dày và khỏe hơn, thể tích tống máu của mỗi nhịp đập tăng lên, giúp nhịp tim lúc nghỉ ngơi chậm lại và tim được nghỉ ngơi nhiều hơn.
* Kích thích tăng sinh mạng lưới mao mạch bàng hệ xung quanh tim, phòng ngừa biến chứng khi có nhánh mạch vành bị hẹp.
* Tăng nồng độ HDL-C (Cholesterol 'bảo vệ') và giảm nồng độ Triglyceride trong máu.
* Cải thiện độ nhạy của hormone insulin, hỗ trợ phòng ngừa và điều trị đái tháo đường type 2.

### 2. Các bài tập lý tưởng cho tim mạch
* **Đi bộ nhanh (Brisk Walking):** Hình thức vận động an toàn nhất cho mọi lứa tuổi, tốc độ khoảng 5 - 6 km/h.
* **Bơi lội:** Giúp toàn bộ các nhóm cơ hoạt động mà không tạo áp lực lên các khớp gối và cột sống.
* **Đạp xe:** Tăng cường tuần hoàn máu chi dưới, thúc đẩy máu tĩnh mạch hồi lưu về tim tốt hơn.
* **Yoga & Khí công dưỡng sinh:** Giúp giảm căng thẳng giao cảm, hạ nhịp tim và điều hòa huyết áp thông qua nhịp thở sâu.
        """
    },
    {
        "id": "understanding-cholesterol-and-atherosclerosis",
        "title": "Hiểu về mỡ máu & mảng xơ vữa: Phân biệt cholesterol tốt (HDL) và xấu (LDL)",
        "category": "Nguyên nhân & nguy cơ",
        "category_id": "causes",
        "read_time": "5 phút đọc",
        "author": "PGS.TS Vũ Đình Hoàng - Trưởng bộ môn Tim mạch",
        "date": "05/10/2026",
        "icon": "🔬",
        "badge_color": "#8B5CF6",
        "summary": "Không phải mọi loại cholesterol đều có hại. Tìm hiểu cơ chế mảng xơ vữa bám vào thành mạch, nứt vỡ và tạo thành cục máu đông gây nhồi máu cơ tim cấp.",
        "key_takeaways": [
            "LDL-C (Cholesterol xấu): Thủ phạm chính lắng đọng vào thành mạch tạo mảng xơ vữa.",
            "HDL-C (Cholesterol tốt): Đóng vai trò như 'xe rác', dọn dẹp cholesterol dư thừa về gan tiêu hủy.",
            "Mục tiêu LDL-C ở người nguy cơ tim mạch cao là dưới 1.8 mmol/L (70 mg/dL).",
            "Mảng xơ vữa không ổn định khi nứt ra sẽ kích hoạt tiểu cầu bám vào tạo thành huyết khối bít tắc mạch."
        ],
        "content": """
### 1. Cholesterol đến từ đâu và hoạt động ra sao?
Cholesterol là một chất béo sáp thiết yếu để cơ thể sản sinh màng tế bào, vitamin D và các hormone sinh dục. Cơ thể nhận cholesterol từ hai nguồn: 75% do gan tự tổng hợp và 25% hấp thụ từ thức ăn hàng ngày.
Vì chất béo không tan trong máu, nó phải được bao bọc bởi các protein gọi là Lipoprotein:
* **LDL (Low-Density Lipoprotein):** Vận chuyển cholesterol từ gan đến các mô. Khi có quá nhiều LDL, chúng xâm nhập qua lớp nội mạc mạch máu, bị oxy hóa và tạo nên các vệt mỡ, dần phát triển thành mảng xơ vữa xơ cứng.
* **HDL (High-Density Lipoprotein):** Hút cholesterol dư thừa từ thành mạch và đưa về gan để bài tiết ra dịch mật, giúp bảo vệ lòng mạch luôn thông thoáng.

### 2. Các mốc chỉ số xét nghiệm mỡ máu chuẩn
* **Cholesterol toàn phần:** < 5.2 mmol/L (Lý tưởng) | 5.2 - 6.2 mmol/L (Hơi cao) | > 6.2 mmol/L (Rất cao).
* **Triglyceride (Chất béo trung tính):** < 1.7 mmol/L (Bình thường) | > 2.3 mmol/L (Nguy cơ viêm tụy và tim mạch).
* **LDL-C:** Càng thấp càng tốt đối với người có tiền sử tim mạch hoặc đái tháo đường.
        """
    },
    {
        "id": "10-golden-rules-heart-health",
        "title": "10 lời khuyên vàng bảo vệ trái tim suốt đời từ các chuyên gia tim mạch",
        "category": "Lời khuyên chuyên gia",
        "category_id": "advice",
        "read_time": "4 phút đọc",
        "author": "Ban Chỉ Đạo Dự Án Phòng Chống Bệnh Tim Mạch Quốc Gia",
        "date": "01/10/2026",
        "icon": "⭐",
        "badge_color": "#0284C7",
        "summary": "Tập hợp 10 nguyên tắc vàng đơn giản, dễ nhớ mà mọi người từ 30 tuổi trở lên đều có thể áp dụng ngay hôm nay để giữ cho trái tim luôn đập khỏe mạnh.",
        "key_takeaways": [
            "Biết rõ 4 con số sức khỏe của bản thân: Huyết áp, Đường huyết, Mỡ máu và Chỉ số BMI.",
            "Ăn sáng đầy đủ, không bỏ bữa, không ăn khuya sát giờ đi ngủ.",
            "Ngủ đủ 7 - 8 tiếng mỗi đêm và kiểm soát căng thẳng bằng thư giãn, thiền định.",
            "Khám sức khỏe định kỳ ít nhất 1 lần mỗi năm để phát hiện sớm các bất thường."
        ],
        "content": """
### 10 Nguyên tắc vàng vì một trái tim khỏe:
1. **Nói KHÔNG với thuốc lá:** Cả hút thuốc chủ động và hút thuốc thụ động đều tàn phá tế bào nội mô mạch máu.
2. **Kiểm soát cân nặng:** Duy trì chỉ số khối cơ thể (BMI) từ 18.5 đến 22.9 kg/m² (chuẩn người Châu Á).
3. **Giảm muối, tăng rau xanh:** Ăn ít nhất 400g rau xanh và quả chín mỗi ngày.
4. **Vận động đều đặn:** Ít nhất 30 phút mỗi ngày, 5 ngày mỗi tuần.
5. **Hạn chế đồ uống có cồn:** Nam giới không quá 2 đơn vị cồn/ngày, nữ giới không quá 1 đơn vị cồn/ngày.
6. **Kiểm tra huyết áp định kỳ:** Đo huyết áp tại nhà đúng phương pháp ít nhất 1 lần mỗi tháng.
7. **Uống đủ nước:** Uống từ 1.5 - 2 lít nước lọc mỗi ngày để hỗ trợ lưu thông máu.
8. **Ngủ đủ giấc:** Giấc ngủ sâu giúp hệ thần kinh thực vật nghỉ ngơi và hạ huyết áp sinh lý ban đêm.
9. **Cười nhiều hơn, giảm căng thẳng:** Căng thẳng mạn tính giải phóng cortisol và adrenaline làm co mạch, tăng huyết áp.
10. **Tuân thủ điều trị:** Nếu đã được chẩn đoán bệnh tim mạch, tuyệt đối không tự ý ngưng hoặc giảm liều thuốc mà không hỏi ý kiến bác sĩ.
        """
    }
]

STANDARD_HEALTH_METRICS = [
    {
        "name": "Huyết áp lâm sàng (Blood Pressure)",
        "unit": "mmHg",
        "optimal": "< 120/80 mmHg",
        "warning": "120-139 / 80-89 mmHg",
        "danger": "≥ 140/90 mmHg",
        "advice": "Đo vào buổi sáng sau khi ngủ dậy và nghỉ ngơi 5 phút."
    },
    {
        "name": "Cholesterol toàn phần (Total Cholesterol)",
        "unit": "mmol/L",
        "optimal": "< 5.2 mmol/L",
        "warning": "5.2 - 6.2 mmol/L",
        "danger": "> 6.2 mmol/L",
        "advice": "Xét nghiệm sau khi nhịn ăn ít nhất 8-10 tiếng."
    },
    {
        "name": "Đường huyết lúc đói (Fasting Glucose)",
        "unit": "mmol/L",
        "optimal": "< 5.6 mmol/L",
        "warning": "5.6 - 6.9 mmol/L",
        "danger": "≥ 7.0 mmol/L",
        "advice": "Chỉ số cao báo hiệu tiền đái tháo đường hoặc đái tháo đường."
    },
    {
        "name": "Chỉ số khối cơ thể (BMI - Thể trạng)",
        "unit": "kg/m²",
        "optimal": "18.5 - 22.9 kg/m²",
        "warning": "23.0 - 24.9 kg/m² (Thừa cân)",
        "danger": "≥ 25.0 kg/m² (Béo phì)",
        "advice": "Tính bằng Cân nặng (kg) chia cho bình phương Chiều cao (m)."
    }
]

EMERGENCY_CONTACTS = [
    {"name": "Tổng đài Cấp cứu Toàn quốc", "phone": "115", "desc": "Cấp cứu 24/7 khi có dấu hiệu nhồi máu cơ tim, đột quỵ"},
    {"name": "Viện Tim Mạch Quốc Gia (BV Bạch Mai - Hà Nội)", "phone": "024 3869 3731", "desc": "Trung tâm can thiệp tim mạch hàng đầu miền Bắc"},
    {"name": "Viện Tim TP. Hồ Chí Minh", "phone": "028 3865 1586", "desc": "Chuyên khoa tim mạch kỹ thuật cao miền Nam"},
    {"name": "Bệnh Viện Chợ Rẫy (Khoa Tim Mạch Can Thiệp)", "phone": "028 3855 4137", "desc": "Trung tâm cấp cứu tim mạch can thiệp 24/24"},
    {"name": "BV Đại Học Y Dược TP.HCM", "phone": "028 3855 4269", "desc": "Chẩn đoán và điều trị tim mạch chuyên sâu"}
]


def get_all_articles() -> List[Dict]:
    """Returns all articles."""
    return ARTICLES_DATA


def get_article_by_id(article_id: str) -> Optional[Dict]:
    """Finds article by its ID."""
    for art in ARTICLES_DATA:
        if art["id"] == article_id:
            return art
    return None


def get_categories() -> List[str]:
    """Returns unique list of article categories."""
    cats = ["Tất cả"]
    for art in ARTICLES_DATA:
        if art["category"] not in cats:
            cats.append(art["category"])
    return cats
