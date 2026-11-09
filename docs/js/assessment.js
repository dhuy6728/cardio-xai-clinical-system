/**
 * CardioCare AI - Patient Self-Assessment Component Logic
 */

function calcPatientBMI() {
  const hInput = document.getElementById('p-height');
  const wInput = document.getElementById('p-weight');
  const badge = document.getElementById('p-bmi-badge');

  const h = parseFloat(hInput?.value || 165);
  const w = parseFloat(wInput?.value || 68);

  if (h > 0 && w > 0 && badge) {
    const bmi = (w / Math.pow(h / 100, 2)).toFixed(2);
    let status = "Bình thường";
    if (bmi < 18.5) status = "Thiếu cân";
    else if (bmi >= 25.0) status = "Béo phì";
    else if (bmi >= 23.0) status = "Thừa cân nhẹ";
    badge.innerText = `${bmi} kg/m² (${status})`;
  }
}

function submitPatientAssessment(e) {
  e.preventDefault();

  const age = parseInt(document.getElementById('p-age').value);
  const gender = parseInt(document.querySelector('input[name="p-gender"]:checked').value);
  const height = parseFloat(document.getElementById('p-height').value);
  const weight = parseFloat(document.getElementById('p-weight').value);
  const ap_hi = parseInt(document.getElementById('p-ap-hi').value);
  const ap_lo = parseInt(document.getElementById('p-ap-lo').value);
  const chol = parseInt(document.getElementById('p-chol').value);
  const gluc = parseInt(document.getElementById('p-gluc').value);
  const smoke = document.getElementById('p-smoke').checked ? 1 : 0;
  const alco = document.getElementById('p-alco').checked ? 1 : 0;
  const active = document.getElementById('p-active').checked ? 1 : 0;

  const params = {
    age, gender, height, weight, ap_hi, ap_lo, chol, gluc, smoke, alco, active
  };

  const res = evaluateCardioRisk(params);

  // Format examination timestamp
  const now = new Date();
  const dateFormatted = `${String(now.getDate()).padStart(2, '0')}/${String(now.getMonth() + 1).padStart(2, '0')}/${now.getFullYear()} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

  // Automatically save to local repository (privacy-preserving, by date and status)
  addSubmittedRecord({
    roleType: 'patient',
    patientName: 'Bệnh nhân',
    date: dateFormatted,
    riskProb: res.prob,
    riskLevel: res.level,
    bp: `${params.ap_hi}/${params.ap_lo}`,
    bmi: res.bmi,
    chol: params.chol,
    gluc: params.gluc,
    recommendation: res.advice
  });

  // Render Result Box
  const resultBox = document.getElementById('patient-result-box');
  if (resultBox) {
    resultBox.classList.remove('hidden');
    resultBox.innerHTML = `
      <div class="bg-white rounded-2xl border-2 border-slate-200 p-6 sm:p-8 shadow-xl space-y-6 fade-in">
        <div class="flex items-center justify-between border-b pb-4">
          <div>
            <span class="text-xs font-bold text-slate-400 tracking-wider">Kết quả phân tích AI</span>
            <h2 class="text-2xl font-extrabold text-slate-900 mt-0.5">Báo cáo sức khỏe tim mạch</h2>
          </div>
          <span class="px-4 py-1.5 rounded-full text-xs font-bold ${res.badge}">
            ${res.level}
          </span>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div class="p-4 rounded-xl bg-slate-50 border border-slate-200">
            <span class="text-xs font-semibold text-slate-500">Điểm nguy cơ AI</span>
            <div class="text-3xl font-extrabold mt-1" style="color: ${res.color};">${(res.prob * 100).toFixed(1)}%</div>
            <span class="text-xs text-slate-400">Mô hình Gradient Boosting</span>
          </div>
          <div class="p-4 rounded-xl bg-slate-50 border border-slate-200">
            <span class="text-xs font-semibold text-slate-500">Huyết áp lâm sàng</span>
            <div class="text-3xl font-extrabold text-slate-900 mt-1">${params.ap_hi}/${params.ap_lo} <span class="text-sm font-normal text-slate-500">mmHg</span></div>
            <span class="text-xs ${params.ap_hi >= 140 ? 'text-red-600 font-bold' : 'text-slate-400'}">${params.ap_hi >= 140 ? 'Huyết áp cao' : 'Mức bình thường'}</span>
          </div>
          <div class="p-4 rounded-xl bg-slate-50 border border-slate-200">
            <span class="text-xs font-semibold text-slate-500">Thể trạng BMI</span>
            <div class="text-3xl font-extrabold text-slate-900 mt-1">${res.bmi} <span class="text-sm font-normal text-slate-500">kg/m²</span></div>
            <span class="text-xs text-slate-400">${params.weight}kg / ${params.height}cm</span>
          </div>
        </div>

        <div class="p-5 rounded-xl border-l-4 ${res.prob >= 0.65 ? 'bg-red-50 border-red-500 text-red-900' : res.prob >= 0.35 ? 'bg-amber-50 border-amber-500 text-amber-900' : 'bg-emerald-50 border-emerald-500 text-emerald-900'}">
          <h4 class="font-bold text-base mb-1.5 flex items-center gap-2">
            <i class="fa-solid fa-notes-medical"></i> Lời khuyên dành riêng cho bạn:
          </h4>
          <p class="text-sm leading-relaxed">${res.advice}</p>
        </div>

        <div class="flex items-center gap-3 bg-emerald-50 text-emerald-800 p-4 rounded-xl border border-emerald-200 text-sm">
          <i class="fa-solid fa-circle-check text-emerald-600 text-lg"></i>
          <div>
            <b>Đã tự động ghi nhận vào Kho lưu trữ sức khỏe của bạn!</b><br>
            Lưu trữ ngày <b>${dateFormatted}</b> với tình trạng <b>${res.level}</b> mà không cần công khai danh tính.
          </div>
        </div>

        <div class="flex justify-end pt-2">
          <a href="history.html" class="px-5 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-semibold text-sm transition active:scale-95 inline-flex items-center gap-1.5">
            Xem trong kho lưu trữ <i class="fa-solid fa-arrow-right text-xs"></i>
          </a>
        </div>
      </div>
    `;

    showToast("Đã lưu kết quả vào kho lưu trữ thành công!", "success");
    resultBox.scrollIntoView({ behavior: 'smooth' });
  }
}
