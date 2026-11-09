/**
 * CardioCare AI - Medical Articles & Standard Reference Data
 * Curated from European Society of Cardiology (ESC), American Heart Association (AHA),
 * and Vietnam National Heart Association (VNHA).
 */

const ARTICLES = [
  {
    id: "warning-signs-heart-attack",
    title: "5 dấu hiệu cảnh báo nhồi máu cơ tim sớm: Khi nào cần gọi cấp cứu 115?",
    category: "Dấu hiệu cảnh báo",
    readTime: "4 phút đọc",
    author: "TS.BS Nguyễn Văn An - Hội Tim Mạch Việt Nam",
    date: "15/10/2026",
    badgeColor: "bg-red-100 text-red-700",
    summary: "Nhồi máu cơ tim có thể diễn ra đột ngột nhưng thường phát tín hiệu cảnh báo trước nhiều giờ hoặc nhiều ngày. Nắm rõ quy tắc 'Thời gian vàng' giúp cứu sống tính mạng.",
    takeaways: [
      "Cơn đau thắt ngực kéo dài trên 15 phút, lan ra vai, hàm, lưng là dấu hiệu kinh điển.",
      "Khó thở đột ngột, vã mồ hôi lạnh, choáng váng đặc biệt nguy hiểm ở người cao tuổi và phụ nữ.",
      "Quy tắc thời gian vàng: 1 - 2 giờ đầu từ khi khởi phát cơn đau là lúc tái thông mạch vành hiệu quả nhất.",
      "Không tự ý lái xe đi cấp cứu, hãy gọi ngay 115 hoặc nhờ người nhà đưa đến cơ sở y tế gần nhất."
    ],
    content: `
      <h4 class="text-lg font-bold text-slate-800 mb-2">1. Nhận diện cơn đau thắt ngực điển hình</h4>
      <p class="text-slate-600 mb-3">Cơn đau do thiếu máu cơ tim thường mang cảm giác bóp nghẹt, đè nặng sau xương ức, lan lên cổ, hàm, vai trái hoặc ra sau lưng. Cơn đau kéo dài trên 10-15 phút và không giảm khi nghỉ ngơi.</p>
      <h4 class="text-lg font-bold text-slate-800 mb-2">2. Dấu hiệu không điển hình</h4>
      <p class="text-slate-600 mb-3">Phụ nữ và người đái tháo đường thường có biểu hiện khó thở đột ngột, vã mồ hôi lạnh, buồn nôn, mệt lả và choáng váng.</p>
      <h4 class="text-lg font-bold text-slate-800 mb-2">3. Quy tắc xử trí khẩn cấp 5 phút đầu</h4>
      <p class="text-slate-600 mb-2">• Ngừng mọi hoạt động, ngồi tựa lưng 45 độ thoải mái.</p>
      <p class="text-slate-600 mb-2">• Gọi ngay đường dây nóng <b>115</b> thông báo nghi ngờ nhồi máu cơ tim.</p>
      <p class="text-slate-600">• Không tự ý lái xe đến bệnh viện.</p>
    `
  },
  {
    id: "hypertension-silent-killer",
    title: "Tăng huyết áp – 'Kẻ giết người thầm lặng' & cách kiểm soát không dùng thuốc",
    category: "Nguyên nhân & nguy cơ",
    readTime: "5 phút đọc",
    author: "ThS.BS Trần Mai Lan - Viện Tim Mạch Quốc Gia",
    date: "12/10/2026",
    badgeColor: "bg-amber-100 text-amber-700",
    summary: "Gần 50% người bị tăng huyết áp không hề có triệu chứng cho đến khi xảy ra tai biến đột quỵ hoặc suy tim. Khám phá các phương pháp hạ áp tự nhiên.",
    takeaways: [
      "Huyết áp tối ưu là dưới 120/80 mmHg; tăng huyết áp khi từ 140/90 mmHg trở lên.",
      "Giảm muối ăn xuống dưới 5g/ngày giúp hạ 5-8 mmHg huyết áp.",
      "Tập thể dục 150 phút/tuần giúp mạch máu duy trì độ đàn hồi tốt.",
      "Đo huyết áp đúng cách tại nhà: nghỉ ngơi 5 phút, ngồi thẳng lưng, tay ngang tim."
    ],
    content: `
      <h4 class="text-lg font-bold text-slate-800 mb-2">1. Nguy cơ tiềm ẩn từ huyết áp cao</h4>
      <p class="text-slate-600 mb-3">Huyết áp cao âm thầm phá hủy thành động mạch, dẫn đến xơ vữa, phì đại cơ tim, suy tim và đột quỵ xuất huyết não.</p>
      <h4 class="text-lg font-bold text-slate-800 mb-2">2. Biện pháp hạ huyết áp tự nhiên</h4>
      <p class="text-slate-600 mb-2">• Chế độ ăn giảm muối DASH: tăng cường rau xanh, trái cây giàu kali (chuối, bơ, cải xoăn).</p>
      <p class="text-slate-600 mb-2">• Giảm cân: Cứ giảm 1kg cân nặng dư thừa có thể giúp hạ 1 mmHg huyết áp tâm thu.</p>
      <p class="text-slate-600">• Hạn chế tối đa rượu bia và bỏ thuốc lá hoàn toàn.</p>
    `
  },
  {
    id: "mediterranean-diet-for-heart",
    title: "Chế độ ăn Địa Trung Hải: 'Tấm khiên vàng' bảo vệ mạch máu & giảm mỡ máu",
    category: "Dinh dưỡng & ăn uống",
    readTime: "6 phút đọc",
    author: "BS. Dinh dưỡng Lê Hoàng Quân - ĐH Y Hà Nội",
    date: "10/10/2026",
    badgeColor: "bg-emerald-100 text-emerald-700",
    summary: "Nghiên cứu PREDIMED chứng minh chế độ ăn Địa Trung Hải giảm tới 30% nguy cơ biến cố tim mạch lớn. Hướng dẫn ứng dụng thực tế vào mâm cơm Việt.",
    takeaways: [
      "Ưu tiên chất béo tốt không bão hòa đơn: Dầu olive, quả bơ, hạt óc chó, hạt điều.",
      "Ăn cá béo (cá hồi, cá thu, cá trích) ít nhất 2 bữa/tuần để bổ sung Omega-3.",
      "Tăng chất xơ hòa tan từ ngũ cốc nguyên cám, yến mạch và các loại đậu.",
      "Hạn chế thịt đỏ và thực phẩm chế biến sẵn (xúc xích, thịt xông khói)."
    ],
    content: `
      <h4 class="text-lg font-bold text-slate-800 mb-2">1. Cấu trúc kim tự tháp Địa Trung Hải</h4>
      <p class="text-slate-600 mb-3">Tầng đáy ăn hàng ngày gồm rau củ, quả chín, dầu olive và các loại đậu. Tầng giữa là cá biển giàu Omega-3 và gia cầm nạc. Tầng đỉnh hạn chế là thịt đỏ và đường ngọt.</p>
      <h4 class="text-lg font-bold text-slate-800 mb-2">2. Ứng dụng vào mâm cơm Việt Nam</h4>
      <p class="text-slate-600 mb-2">• Dùng dầu thực vật thay mỡ heo khi xào nấu, ưu tiên các món luộc, hấp.</p>
      <p class="text-slate-600 mb-2">• Thay một phần cơm trắng bằng gạo lứt hoặc khoai lang luộc.</p>
      <p class="text-slate-600">• Ăn thêm các loại hạt dinh dưỡng như hạt sen, hạt óc chó trong bữa phụ.</p>
    `
  },
  {
    id: "exercise-guidelines-heart-health",
    title: "Vận động thể lực đúng cách cho trái tim: Quy tắc 150 phút & nhịp tim đích",
    category: "Lối sống & thể thao",
    readTime: "5 phút đọc",
    author: "BS.CKI Phạm Thanh Tùng - Y học Thể thao",
    date: "08/10/2026",
    badgeColor: "bg-blue-100 text-blue-700",
    summary: "Tập luyện đúng cách giúp cơ tim dày khỏe và tăng sinh mao mạch bàng hệ. Hướng dẫn tính nhịp tim an toàn trong từng buổi tập.",
    takeaways: [
      "Tối thiểu 150 phút vận động vừa phải (đi bộ nhanh, bơi, đạp xe) mỗi tuần.",
      "Công thức nhịp tim tối đa an toàn: 220 trừ đi số tuổi của bạn.",
      "Vùng nhịp tim rèn luyện lý tưởng: 50% - 70% nhịp tim tối đa.",
      "Khởi động kỹ 5-10 phút trước khi bắt đầu và hạ nhiệt dần trước khi nghỉ."
    ],
    content: `
      <h4 class="text-lg font-bold text-slate-800 mb-2">1. Tác động của vận động lên cơ tim</h4>
      <p class="text-slate-600 mb-3">Vận động thường xuyên làm tăng thể tích tống máu của mỗi nhịp tim, giúp nhịp tim lúc nghỉ ngơi hạ thấp và tim có nhiều thời gian nghỉ ngơi hơn giữa các chu kỳ co bóp.</p>
      <h4 class="text-lg font-bold text-slate-800 mb-2">2. Môn thể thao thích hợp</h4>
      <p class="text-slate-600 mb-2">• Đi bộ nhanh: 30-45 phút mỗi ngày, an toàn cho mọi lứa tuổi.</p>
      <p class="text-slate-600">• Bơi lội và đạp xe: Giúp tuần hoàn chi dưới mà không đau khớp gối.</p>
    `
  },
  {
    id: "understanding-cholesterol-and-atherosclerosis",
    title: "Hiểu về mỡ máu & mảng xơ vữa: Phân biệt cholesterol tốt (HDL) và xấu (LDL)",
    category: "Nguyên nhân & nguy cơ",
    readTime: "5 phút đọc",
    author: "PGS.TS Vũ Đình Hoàng - Trưởng bộ môn Tim mạch",
    date: "05/10/2026",
    badgeColor: "bg-purple-100 text-purple-700",
    summary: "Phân biệt rõ vai trò của LDL và HDL trong cơ thể, cơ chế mảng xơ vữa nứt vỡ kích hoạt cục máu đông gây tắc động mạch vành.",
    takeaways: [
      "LDL-C (xấu): Thủ phạm chính tích tụ vào thành mạch gây xơ vữa.",
      "HDL-C (tốt): 'Xe dọn rác' vận chuyển cholesterol dư thừa về gan xử lý.",
      "Mục tiêu LDL-C ở người nguy cơ cao nên dưới 1.8 mmol/L (70 mg/dL).",
      "Triglyceride tăng cao cũng là yếu tố thúc đẩy xơ cứng mạch máu."
    ],
    content: `
      <h4 class="text-lg font-bold text-slate-800 mb-2">1. Cholesterol đến từ đâu?</h4>
      <p class="text-slate-600 mb-3">75% cholesterol do gan sản sinh tự nhiên và 25% hấp thu từ thực phẩm hàng ngày. Cơ thể cần cholesterol để xây dựng màng tế bào và tạo hormone.</p>
      <h4 class="text-lg font-bold text-slate-800 mb-2">2. Tại sao mảng xơ vữa gây nguy hiểm?</h4>
      <p class="text-slate-600 mb-3">Khi mảng xơ vữa bị viêm và nứt ra, các tiểu cầu sẽ lập tức bám vào tạo thành cục huyết khối bịt kín lòng động mạch chỉ trong vài phút, gây nhồi máu cơ tim cấp.</p>
    `
  },
  {
    id: "10-golden-rules-heart-health",
    title: "10 lời khuyên vàng bảo vệ trái tim suốt đời từ các chuyên gia tim mạch",
    category: "Lời khuyên chuyên gia",
    readTime: "4 phút đọc",
    author: "Ban Dự Án Phòng Chống Bệnh Tim Mạch Quốc Gia",
    date: "01/10/2026",
    badgeColor: "bg-sky-100 text-sky-700",
    summary: "Tổng hợp 10 thói quen vàng đơn giản, thiết thực mà mỗi người từ 30 tuổi trở lên đều có thể áp dụng ngay để giữ trái tim luôn khỏe mạnh.",
    takeaways: [
      "Nắm rõ 4 con số: Huyết áp, Đường huyết, Mỡ máu và chỉ số BMI.",
      "Nói KHÔNG hoàn toàn với khói thuốc lá.",
      "Giảm muối trong mọi bữa ăn, ăn nhiều rau quả tươi.",
      "Ngủ đủ 7-8 tiếng mỗi đêm và giữ tinh thần lạc quan, giảm căng thẳng."
    ],
    content: `
      <h4 class="text-lg font-bold text-slate-800 mb-2">10 thói quen bảo vệ trái tim:</h4>
      <ol class="list-decimal pl-5 space-y-1.5 text-slate-600">
        <li>Không hút thuốc lá chủ động và tránh xa khói thuốc thụ động.</li>
        <li>Duy trì BMI từ 18.5 đến 22.9 kg/m².</li>
        <li>Ăn tối thiểu 400g rau xanh và trái cây mỗi ngày.</li>
        <li>Tập thể dục ít nhất 30 phút/ngày, 5 ngày/tuần.</li>
        <li>Hạn chế rượu bia tối đa.</li>
        <li>Đo huyết áp tại nhà định kỳ hàng tháng.</li>
        <li>Uống đủ 1.5 - 2 lít nước lọc mỗi ngày.</li>
        <li>Ngủ đủ giấc và kiểm soát stress.</li>
        <li>Cười nhiều hơn và tham gia các hoạt động xã hội.</li>
        <li>Khám tim mạch định kỳ và tuân thủ hướng dẫn của bác sĩ.</li>
      </ol>
    `
  }
];

const STANDARD_METRICS = [
  {
    name: "Huyết áp lâm sàng (Blood Pressure)",
    unit: "mmHg",
    optimal: "< 120/80 mmHg",
    warning: "120-139 / 80-89 mmHg",
    danger: "≥ 140/90 mmHg",
    advice: "Đo vào buổi sáng sau khi ngủ dậy và nghỉ ngơi 5 phút."
  },
  {
    name: "Cholesterol toàn phần (Total Cholesterol)",
    unit: "mmol/L",
    optimal: "< 5.2 mmol/L",
    warning: "5.2 - 6.2 mmol/L",
    danger: "> 6.2 mmol/L",
    advice: "Xét nghiệm sau khi nhịn ăn ít nhất 8-10 tiếng."
  },
  {
    name: "Đường huyết lúc đói (Fasting Glucose)",
    unit: "mmol/L",
    optimal: "< 5.6 mmol/L",
    warning: "5.6 - 6.9 mmol/L",
    danger: "≥ 7.0 mmol/L",
    advice: "Chỉ số cao báo hiệu tiền đái tháo đường hoặc đái tháo đường."
  },
  {
    name: "Chỉ số khối cơ thể (BMI - Thể trạng)",
    unit: "kg/m²",
    optimal: "18.5 - 22.9 kg/m²",
    warning: "23.0 - 24.9 kg/m² (Thừa cân)",
    danger: "≥ 25.0 kg/m² (Béo phì)",
    advice: "Tính bằng Cân nặng (kg) chia cho bình phương Chiều cao (m)."
  }
];

const EMERGENCY_CONTACTS = [
  {
    name: "Tổng đài Cấp cứu Toàn quốc",
    phone: "115",
    desc: "Cấp cứu 24/7 khi có dấu hiệu nhồi máu cơ tim, đột quỵ"
  },
  {
    name: "Viện Tim Mạch Quốc Gia (BV Bạch Mai - Hà Nội)",
    phone: "024 3869 3731",
    desc: "Trung tâm can thiệp tim mạch hàng đầu miền Bắc"
  },
  {
    name: "Viện Tim TP. Hồ Chí Minh",
    phone: "028 3865 1586",
    desc: "Chuyên khoa tim mạch kỹ thuật cao miền Nam"
  },
  {
    name: "Bệnh Viện Chợ Rẫy (Khoa Tim Mạch Can Thiệp)",
    phone: "028 3855 4137",
    desc: "Trung tâm cấp cứu tim mạch can thiệp 24/24"
  },
  {
    name: "BV Đại Học Y Dược TP.HCM",
    phone: "028 3855 4269",
    desc: "Chẩn đoán và điều trị tim mạch chuyên sâu"
  }
];
