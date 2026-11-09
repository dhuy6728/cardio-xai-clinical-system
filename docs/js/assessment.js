/**
/**
 * CardioCare AI - Patient Self-Assessment Component Logic
 */

function calcPatientBMI() {
  const hInput = document.getElementById('p-height');
  const wInput = document.getElementById('p-weight');
  const badge = document.getElementById('p-bmi-badge');

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
    badge.innerText = `BMI: ${bmi} kg/m² (${status})`;
  } else if (badge) {
    badge.className = "font-semibold text-xs px-2.5 py-1 rounded-full bg-slate-100 text-slate-500 border border-slate-200";
    badge.innerText = "BMI: --";
  }
}

function initPatientAssessmentPage() {
  calcPatientBMI();

  // Kiểm tra phiên người dùng
  if (typeof getCurrentUser === 'function') {
    const user = getCurrentUser();
    const banner = document.getElementById('patient-auth-banner');
    if (banner) {
      if (user) {
        banner.classList.remove('hidden');
        banner.innerHTML = `
          <div class="bg-gradient-to-r from-sky-50 to-indigo-50 border border-sky-200 rounded-2xl p-4 flex items-center justify-between shadow-sm">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-full bg-sky-600 text-white font-bold flex items-center justify-center text-sm shadow">
                ${user.fullName ? user.fullName.charAt(0).toUpperCase() : 'B'}
              </div>
              <div>
                <div class="text-sm font-bold text-slate-800">Xin chào, ${user.fullName || 'Bệnh nhân'}</div>
                <div class="text-xs text-slate-500">Kết quả đánh giá sẽ tự động lưu vào kho lưu trữ của bạn</div>
              </div>
            </div>
            <span class="px-2.5 py-1 rounded-full text-xs font-bold bg-sky-100 text-sky-800">
              🫀 ${user.role === 'doctor' ? 'Bác sĩ' : 'Bệnh nhân'}
            </span>
          </div>
        `;
      } else {
        banner.classList.remove('hidden');
        banner.innerHTML = `
          <div class="bg-amber-50 border border-amber-200 rounded-2xl p-4 flex items-center justify-between shadow-sm text-xs text-amber-900">
            <div class="flex items-center gap-2.5">
              <i class="fa-solid fa-circle-info text-amber-600 text-base"></i>
              <span>Bạn đang đánh giá ở chế độ <b>Khách</b>. Hãy đăng nhập để đồng bộ kết quả sang ứng dụng di động.</span>
            </div>
            <a href="auth.html" class="px-3 py-1.5 rounded-lg bg-amber-600 hover:bg-amber-700 text-white font-bold transition flex-shrink-0">
              Đăng nhập ngay
            </a>
          </div>
        `;
      }
    }
  }
}

function submitPatientAssessment(e) {
  e.preventDefault();

  const ageInput = document.getElementById('p-age');
  const heightInput = document.getElementById('p-height');
  const weightInput = document.getElementById('p-weight');
  const apHiInput = document.getElementById('p-ap-hi');
  const apLoInput = document.getElementById('p-ap-lo');
  const cholInput = document.getElementById('p-chol');
  const glucInput = document.getElementById('p-gluc');

  if (!ageInput.value) {
    if (typeof showToast === 'function') showToast("Vui lòng nhập tuổi của bạn!", "warning");
    ageInput.focus();
    return;
  }
  if (!heightInput.value) {
    if (typeof showToast === 'function') showToast("Vui lòng nhập chiều cao!", "warning");
    heightInput.focus();
    return;
  }
  if (!weightInput.value) {
    if (typeof showToast === 'function') showToast("Vui lòng nhập cân nặng!", "warning");
    weightInput.focus();
    return;
  }
  if (!apHiInput.value) {
    if (typeof showToast === 'function') showToast("Vui lòng nhập Huyết áp tâm thu (tối đa)!", "warning");
    apHiInput.focus();
    return;
  }
  if (!apLoInput.value) {
    if (typeof showToast === 'function') showToast("Vui lòng nhập Huyết áp tâm trương (tối thiểu)!", "warning");
    apLoInput.focus();
    return;
  }
  if (!cholInput.value) {
    if (typeof showToast === 'function') showToast("Vui lòng chọn mức Cholesterol!", "warning");
    cholInput.focus();
    return;
  }
  if (!glucInput.value) {
    if (typeof showToast === 'function') showToast("Vui lòng chọn mức Glucose đường huyết!", "warning");
    glucInput.focus();
    return;
  }

  const age = parseInt(ageInput.value);
  const gender = parseInt(document.querySelector('input[name="p-gender"]:checked').value);
  const height = parseFloat(heightInput.value);
  const weight = parseFloat(weightInput.value);
  const ap_hi = parseInt(apHiInput.value);
  const ap_lo = parseInt(apLoInput.value);
  const chol = parseInt(cholInput.value);
  const gluc = parseInt(glucInput.value);
  const smoke = document.getElementById('p-smoke').checked ? 1 : 0;
  const alco = document.getElementById('p-alco').checked ? 1 : 0;
  const active = document.getElementById('p-active').checked ? 1 : 0;

  const params = {
    age, gender, height, weight, ap_hi, ap_lo, chol, gluc, smoke, alco, active
  };

  const res = evaluateCardioRisk(params);

  // Lấy tên bệnh nhân nếu đã đăng nhập
  const currentUser = (typeof getCurrentUser === 'function') ? getCurrentUser() : null;
  const patientDisplayName = currentUser ? currentUser.fullName : 'Bệnh nhân';

  // Format examination timestamp
  const now = new Date();
  const dateFormatted = `${String(now.getDate()).padStart(2, '0')}/${String(now.getMonth() + 1).padStart(2, '0')}/${now.getFullYear()} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

  // Automatically save to repository (Cloud Firestore & Local)
  addSubmittedRecord({
    roleType: 'patient',
    patientName: patientDisplayName,
    userId: currentUser ? currentUser.id : null,
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
    recommendation: res.advice
  });

  if (typeof showToast === 'function') {
    showToast("Đã phân tích và lưu vào kho lưu trữ sức khỏe thành công!", "success");
  }

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

        <div class="flex flex-wrap gap-4 pt-2">
          <a href="history.html" class="flex-1 py-3 px-4 rounded-xl bg-sky-600 hover:bg-sky-700 text-white font-bold text-center text-sm shadow transition">
            <i class="fa-solid fa-folder-open mr-1.5"></i> Xem kho lưu trữ của bạn
          </a>
          <button type="button" onclick="window.scrollTo({top: 0, behavior: 'smooth'})" class="py-3 px-5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-semibold text-sm transition">
            Làm lại đánh giá khác
          </button>
        </div>
      </div>
    `;

    resultBox.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
}
