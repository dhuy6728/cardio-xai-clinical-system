/**
 * CardioCare AI - Doctor Clinical Decision Support & XAI Component Logic
 * Manages clinical data entry, SHAP attribution, and Cloud Firestore sync.
 */

function calcDoctorBMI() {
  const hInput = document.getElementById('doc-height');
  const wInput = document.getElementById('doc-weight');
  const badge = document.getElementById('doc-bmi-badge');

  const h = parseFloat(hInput?.value || 0);
  const w = parseFloat(wInput?.value || 0);

  if (h > 0 && w > 0 && badge) {
    const bmi = (w / Math.pow(h / 100, 2)).toFixed(1);
    let status = "Bình thường";
    let badgeColor = "text-emerald-700 bg-emerald-50 border-emerald-200";
    if (bmi < 18.5) {
      status = "Thiếu cân";
      badgeColor = "text-amber-700 bg-amber-50 border-amber-200";
    } else if (bmi >= 25.0) {
      status = "Béo phì";
      badgeColor = "text-rose-700 bg-rose-50 border-rose-200";
    } else if (bmi >= 23.0) {
      status = "Thừa cân nhẹ";
      badgeColor = "text-amber-700 bg-amber-50 border-amber-200";
    }
    badge.className = `font-bold text-xs px-2.5 py-1 rounded-full border ${badgeColor}`;
    badge.innerText = `BMI: ${bmi} (${status})`;
  } else if (badge) {
    badge.className = "font-semibold text-xs px-2.5 py-1 rounded-full bg-slate-100 text-slate-500 border border-slate-200";
    badge.innerText = "BMI: --";
  }
}

function executeDoctorXAI(notify = true) {
  const nameInput = document.getElementById('doc-patient-name');
  const ageInput = document.getElementById('doc-age');
  const heightInput = document.getElementById('doc-height');
  const weightInput = document.getElementById('doc-weight');
  const apHiInput = document.getElementById('doc-ap-hi');
  const apLoInput = document.getElementById('doc-ap-lo');
  const cholInput = document.getElementById('doc-chol');
  const glucInput = document.getElementById('doc-gluc');

  const name = nameInput?.value.trim();
  if (!name) {
    if (notify && typeof showToast === 'function') showToast("Vui lòng nhập họ và tên bệnh nhân!", "warning");
    nameInput?.focus();
    return false;
  }
  if (!ageInput?.value) {
    if (notify && typeof showToast === 'function') showToast("Vui lòng nhập tuổi bệnh nhân!", "warning");
    ageInput?.focus();
    return false;
  }
  if (!heightInput?.value) {
    if (notify && typeof showToast === 'function') showToast("Vui lòng nhập chiều cao!", "warning");
    heightInput?.focus();
    return false;
  }
  if (!weightInput?.value) {
    if (notify && typeof showToast === 'function') showToast("Vui lòng nhập cân nặng!", "warning");
    weightInput?.focus();
    return false;
  }
  if (!apHiInput?.value) {
    if (notify && typeof showToast === 'function') showToast("Vui lòng nhập Huyết áp tâm thu!", "warning");
    apHiInput?.focus();
    return false;
  }
  if (!apLoInput?.value) {
    if (notify && typeof showToast === 'function') showToast("Vui lòng nhập Huyết áp tâm trương!", "warning");
    apLoInput?.focus();
    return false;
  }

  const params = {
    age: parseInt(ageInput.value),
    gender: parseInt(document.getElementById('doc-gender')?.value || 2),
    height: parseFloat(heightInput.value),
    weight: parseFloat(weightInput.value),
    ap_hi: parseInt(apHiInput.value),
    ap_lo: parseInt(apLoInput.value),
    chol: parseInt(cholInput?.value || 1),
    gluc: parseInt(glucInput?.value || 1),
    smoke: document.getElementById('doc-smoke')?.checked ? 1 : 0,
    alco: document.getElementById('doc-alco')?.checked ? 1 : 0,
    active: document.getElementById('doc-active')?.checked ? 1 : 0
  };

  const res = evaluateCardioRisk(params);

  // 1. Render 4 Thẻ chỉ số tổng quan
  const metricsRow = document.getElementById('doc-metrics-row');
  if (metricsRow) {
    metricsRow.innerHTML = `
      <div class="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
        <span class="text-[11px] font-bold text-slate-400">Xác suất tim mạch</span>
        <div class="text-2xl font-extrabold mt-1" style="color: ${res.color};">${(res.prob * 100).toFixed(1)}%</div>
        <span class="text-[11px] text-slate-400">Mô hình Gradient Boost</span>
      </div>
      <div class="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
        <span class="text-[11px] font-bold text-slate-400">Phân tầng rủi ro</span>
        <div class="text-base font-extrabold mt-1">
          <span class="px-2 py-0.5 rounded text-xs font-bold ${res.badge}">${res.level}</span>
        </div>
        <span class="text-[11px] text-slate-400">Tiêu chuẩn ESC/ACC</span>
      </div>
      <div class="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
        <span class="text-[11px] font-bold text-slate-400">Chỉ số BMI</span>
        <div class="text-2xl font-extrabold text-slate-800 mt-1">${res.bmi} <span class="text-xs font-normal text-slate-400">kg/m²</span></div>
        <span class="text-[11px] text-slate-400">${res.bmi >= 25 ? 'Béo phì' : res.bmi >= 23 ? 'Thừa cân' : 'Bình thường'}</span>
      </div>
      <div class="bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
        <span class="text-[11px] font-bold text-slate-400">Huyết áp khám</span>
        <div class="text-2xl font-extrabold text-slate-800 mt-1">${params.ap_hi}/${params.ap_lo}</div>
        <span class="text-[11px] ${params.ap_hi >= 140 ? 'text-red-600 font-bold' : 'text-slate-400'}">${params.ap_hi >= 140 ? 'HA giai đoạn 2' : 'HA tối ưu'}</span>
      </div>
    `;
  }

  // 2. Render Biểu đồ thanh giải thích XAI SHAP
  const xaiContainer = document.getElementById('doc-xai-factors-container');
  if (xaiContainer) {
    xaiContainer.innerHTML = res.factors.map(f => {
      const isBad = f.isRisk && f.impact > 0;
      const barColor = isBad ? 'bg-red-500' : 'bg-emerald-500';
      const textColor = isBad ? 'text-red-700' : 'text-emerald-700';
      const sign = f.impact > 0 ? '+' : '';
      const absVal = Math.min(Math.abs(f.impact) * 3, 100);
      return `
        <div>
          <div class="flex justify-between text-xs font-semibold mb-1">
            <span class="text-slate-700">${f.name}</span>
            <span class="${textColor}">${sign}${f.impact.toFixed(1)}% rủi ro</span>
          </div>
          <div class="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
            <div class="h-full ${barColor} rounded-full" style="width: ${absVal}%;"></div>
          </div>
        </div>
      `;
    }).join('');
  }

  // 3. Render Khuyến nghị & phác đồ lâm sàng
  const protContainer = document.getElementById('doc-protocol-container');
  if (protContainer) {
    protContainer.innerHTML = `
      <h3 class="text-base font-bold text-slate-900 flex items-center gap-2 mb-2">
        <i class="fa-solid fa-clipboard-check text-sky-600"></i> Khuyến nghị & phác đồ lâm sàng đề xuất
      </h3>
      <p class="text-sm text-slate-600 mb-3 leading-relaxed">
        ${res.prob >= 0.65 ? 
          `Bệnh nhân <b>${name}</b> có nguy cơ tim mạch cao (${(res.prob * 100).toFixed(1)}%). Đề nghị bác sĩ chỉ định Điện tâm đồ (ECG), siêu âm tim Doppler màu, xét nghiệm bộ mỡ máu chuyên sâu (LDL-C, Triglyceride) và cân nhắc khởi trị thuốc hạ áp phối hợp.` :
          res.prob >= 0.35 ?
          `Bệnh nhân <b>${name}</b> có nguy cơ trung bình (${(res.prob * 100).toFixed(1)}%). Khuyến nghị theo dõi huyết áp lưu động 24h (Holter HA), tư vấn chế độ ăn giảm muối và tái khám sau 3 tháng.` :
          `Bệnh nhân <b>${name}</b> có các chỉ số hiện tại trong ngưỡng an toàn (${(res.prob * 100).toFixed(1)}%). Hướng dẫn duy trì rèn luyện thể thao và kiểm tra sức khỏe định kỳ hàng năm.`
        }
      </p>
      <div class="text-xs text-slate-400 border-t pt-2 flex items-center justify-between">
        <span>Tiêu chuẩn khuyến cáo: <b>VNHA / ESC Guidelines 2024</b></span>
        <span>Mã hồ sơ: <b>#CC-${Math.floor(res.prob * 9999)}</b></span>
      </div>
    `;
  }

  if (notify && typeof showToast === 'function') {
    showToast("Phân tích XAI hoàn tất!", "success");
  }
  return true;
}

function saveDoctorCaseToRepo() {
  const success = executeDoctorXAI(false);
  if (!success) return;

  const name = document.getElementById('doc-patient-name').value.trim();
  const age = parseInt(document.getElementById('doc-age').value);
  const gender = parseInt(document.getElementById('doc-gender').value);
  const height = parseFloat(document.getElementById('doc-height').value);
  const weight = parseFloat(document.getElementById('doc-weight').value);
  const ap_hi = parseInt(document.getElementById('doc-ap-hi').value);
  const ap_lo = parseInt(document.getElementById('doc-ap-lo').value);
  const chol = parseInt(document.getElementById('doc-chol').value);
  const gluc = parseInt(document.getElementById('doc-gluc').value);
  const smoke = document.getElementById('doc-smoke').checked ? 1 : 0;
  const alco = document.getElementById('doc-alco').checked ? 1 : 0;
  const active = document.getElementById('doc-active').checked ? 1 : 0;

  const params = { age, gender, height, weight, ap_hi, ap_lo, chol, gluc, smoke, alco, active };
  const res = evaluateCardioRisk(params);

  const now = new Date();
  const dateFormatted = `${String(now.getDate()).padStart(2, '0')}/${String(now.getMonth() + 1).padStart(2, '0')}/${now.getFullYear()} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

  addSubmittedRecord({
    roleType: 'doctor',
    patientName: name,
    date: dateFormatted,
    riskProb: res.prob,
    riskLevel: res.level,
    bp: `${params.ap_hi}/${params.ap_lo}`,
    bmi: res.bmi,
    chol: params.chol,
    gluc: params.gluc,
    smoke: params.smoke,
    alco: params.alco,
    active: params.active,
    recommendation: `Bác sĩ ghi nhận ca khám ${name}: ${res.level} (${(res.prob * 100).toFixed(1)}%). ${res.advice}`
  });

  if (typeof showToast === 'function') {
    showToast(`Đã lưu bệnh án cho "${name}" vào kho lưu trữ thành công!`, "success");
  }
}
