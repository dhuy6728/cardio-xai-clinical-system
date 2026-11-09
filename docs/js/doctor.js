/**
 * CardioCare AI - Doctor Clinical Decision Support & XAI Component Logic
 */

function loadDoctorPreset(presetKey) {
  const nameInput = document.getElementById('doc-patient-name');
  const ageInput = document.getElementById('doc-age');
  const genderInput = document.getElementById('doc-gender');
  const heightInput = document.getElementById('doc-height');
  const weightInput = document.getElementById('doc-weight');
  const apHiInput = document.getElementById('doc-ap-hi');
  const apLoInput = document.getElementById('doc-ap-lo');
  const cholInput = document.getElementById('doc-chol');
  const glucInput = document.getElementById('doc-gluc');
  const smokeInput = document.getElementById('doc-smoke');
  const alcoInput = document.getElementById('doc-alco');
  const activeInput = document.getElementById('doc-active');

  if (presetKey === 'high_risk') {
    if (nameInput) nameInput.value = 'Trần Văn Cao';
    if (ageInput) ageInput.value = 54;
    if (genderInput) genderInput.value = 2; // Nam
    if (heightInput) heightInput.value = 168;
    if (weightInput) weightInput.value = 86;
    if (apHiInput) apHiInput.value = 155;
    if (apLoInput) apLoInput.value = 98;
    if (cholInput) cholInput.value = 3; // Rất cao
    if (glucInput) glucInput.value = 2; // Tiền ĐTĐ
    if (smokeInput) smokeInput.checked = true;
    if (alcoInput) alcoInput.checked = true;
    if (activeInput) activeInput.checked = false;
  } else if (presetKey === 'healthy') {
    if (nameInput) nameInput.value = 'Lê Thị Mai';
    if (ageInput) ageInput.value = 32;
    if (genderInput) genderInput.value = 1; // Nữ
    if (heightInput) heightInput.value = 162;
    if (weightInput) weightInput.value = 52;
    if (apHiInput) apHiInput.value = 112;
    if (apLoInput) apLoInput.value = 74;
    if (cholInput) cholInput.value = 1; // Bình thường
    if (glucInput) glucInput.value = 1;
    if (smokeInput) smokeInput.checked = false;
    if (alcoInput) alcoInput.checked = false;
    if (activeInput) activeInput.checked = true;
  } else {
    // Default standard case
    if (nameInput) nameInput.value = 'Nguyễn Văn A';
    if (ageInput) ageInput.value = 50;
    if (genderInput) genderInput.value = 2;
    if (heightInput) heightInput.value = 165;
    if (weightInput) weightInput.value = 72;
    if (apHiInput) apHiInput.value = 135;
    if (apLoInput) apLoInput.value = 88;
    if (cholInput) cholInput.value = 2;
    if (glucInput) glucInput.value = 1;
    if (smokeInput) smokeInput.checked = false;
    if (alcoInput) alcoInput.checked = false;
    if (activeInput) activeInput.checked = true;
  }

  // Re-run analysis without toast
  executeDoctorXAI(false);
}

function executeDoctorXAI(notify = false) {
  const name = document.getElementById('doc-patient-name')?.value.trim() || "Bệnh nhân";
  const params = {
    age: parseInt(document.getElementById('doc-age')?.value || 50),
    gender: parseInt(document.getElementById('doc-gender')?.value || 2),
    height: parseFloat(document.getElementById('doc-height')?.value || 165),
    weight: parseFloat(document.getElementById('doc-weight')?.value || 72),
    ap_hi: parseInt(document.getElementById('doc-ap-hi')?.value || 135),
    ap_lo: parseInt(document.getElementById('doc-ap-lo')?.value || 88),
    chol: parseInt(document.getElementById('doc-chol')?.value || 2),
    gluc: parseInt(document.getElementById('doc-gluc')?.value || 1),
    smoke: document.getElementById('doc-smoke')?.checked ? 1 : 0,
    alco: document.getElementById('doc-alco')?.checked ? 1 : 0,
    active: document.getElementById('doc-active')?.checked ? 1 : 0
  };

  const res = evaluateCardioRisk(params);

  // 1. Render 4 Quick Metric Cards
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

  // 2. Render XAI SHAP Factor Breakdown Bars
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

  // 3. Render Recommendation & Clinical Protocol
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

  // ONLY notify if user explicitly triggered via button click (NEVER on page load)
  if (notify && typeof showToast === 'function') {
    showToast("Phân tích XAI hoàn tất!", "info");
  }
}

function saveDoctorCaseToRepo() {
  const nameInput = document.getElementById('doc-patient-name');
  const name = nameInput?.value.trim();
  if (!name) {
    showToast("Vui lòng nhập họ và tên bệnh nhân trước khi lưu!", "warning");
    nameInput?.focus();
    return;
  }

  const params = {
    age: parseInt(document.getElementById('doc-age').value),
    gender: parseInt(document.getElementById('doc-gender').value),
    height: parseFloat(document.getElementById('doc-height').value),
    weight: parseFloat(document.getElementById('doc-weight').value),
    ap_hi: parseInt(document.getElementById('doc-ap-hi').value),
    ap_lo: parseInt(document.getElementById('doc-ap-lo').value),
    chol: parseInt(document.getElementById('doc-chol').value),
    gluc: parseInt(document.getElementById('doc-gluc').value),
    smoke: document.getElementById('doc-smoke').checked ? 1 : 0,
    alco: document.getElementById('doc-alco').checked ? 1 : 0,
    active: document.getElementById('doc-active').checked ? 1 : 0
  };

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
    recommendation: `Bác sĩ ghi nhận ca khám ${name}: ${res.level} (${(res.prob * 100).toFixed(1)}%). ${res.advice}`
  });

  showToast(`Đã lưu bệnh án cho "${name}" vào kho lưu trữ thành công!`, "success");
}
