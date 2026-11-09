/**
 * CardioCare AI - History & Records Component Logic
 */

function renderPatientHistory(containerId = 'patient-records-container') {
  const container = document.getElementById(containerId);
  if (!container || typeof getSubmittedRecords !== 'function') return;

  const records = getSubmittedRecords();

  if (records.length === 0) {
    container.innerHTML = `
      <div class="text-center py-16 bg-white rounded-2xl border border-slate-200 p-8 shadow-sm">
        <div class="w-16 h-16 rounded-2xl bg-sky-50 text-sky-500 flex items-center justify-center mx-auto text-3xl mb-4">
          <i class="fa-solid fa-folder-open"></i>
        </div>
        <h3 class="text-lg font-bold text-slate-800">Kho lưu trữ hiện chưa có dữ liệu</h3>
        <p class="text-sm text-slate-500 mt-1 max-w-md mx-auto">
          Hệ thống chỉ hiển thị những ca bệnh thực sự được xác nhận. Hãy thực hiện lượt tự đánh giá đầu tiên của bạn để lưu lại lịch sử theo dõi sức khỏe.
        </p>
        <a href="assessment.html" class="mt-5 px-5 py-2.5 rounded-xl bg-sky-600 hover:bg-sky-700 text-white text-sm font-bold shadow transition active:scale-95 inline-flex items-center gap-2">
          <i class="fa-solid fa-heart-pulse"></i> Tự đánh giá ngay
        </a>
      </div>
    `;
    return;
  }

  container.innerHTML = records.map(rec => {
    const isHigh = rec.riskProb >= 0.65 || (rec.riskLevel && rec.riskLevel.includes('cao'));
    const isMod = !isHigh && (rec.riskProb >= 0.35 || (rec.riskLevel && rec.riskLevel.includes('trung')));
    const badge = isHigh ? 'badge-high' : isMod ? 'badge-mod' : 'badge-low';
    const borderColor = isHigh ? 'border-red-200' : isMod ? 'border-amber-200' : 'border-emerald-200';

    return `
      <div class="bg-white rounded-2xl border ${borderColor} p-5 sm:p-6 shadow-sm hover:shadow-md transition">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 border-b border-slate-100 pb-3 mb-3">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-sky-50 text-sky-600 flex items-center justify-center font-bold text-lg">
              <i class="fa-regular fa-calendar-check"></i>
            </div>
            <div>
              <div class="text-sm font-bold text-slate-900">Ngày khám: ${rec.date}</div>
              <div class="text-xs text-slate-400">Kho lưu trữ an toàn</div>
            </div>
          </div>
          <div class="flex items-center gap-3">
            <span class="px-3 py-1 rounded-full text-xs font-bold ${badge}">
              ${rec.riskLevel} (${(rec.riskProb * 100).toFixed(1)}%)
            </span>
            <button onclick="deleteSubmittedRecord(${rec.id}, () => renderPatientHistory('${containerId}'))" title="Xóa bản ghi này" class="text-slate-300 hover:text-red-500 transition p-1">
              <i class="fa-solid fa-trash-can"></i>
            </button>
          </div>
        </div>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs mb-3 bg-slate-50 p-3 rounded-xl">
          <div>
            <span class="text-slate-400">Huyết áp đo:</span>
            <div class="font-bold text-slate-800 text-sm mt-0.5">${rec.bp} mmHg</div>
          </div>
          <div>
            <span class="text-slate-400">Thể trạng BMI:</span>
            <div class="font-bold text-slate-800 text-sm mt-0.5">${rec.bmi} kg/m²</div>
          </div>
          <div>
            <span class="text-slate-400">Cholesterol:</span>
            <div class="font-bold text-slate-800 text-sm mt-0.5">Mức ${rec.chol || 1}</div>
          </div>
          <div>
            <span class="text-slate-400">Đường huyết:</span>
            <div class="font-bold text-slate-800 text-sm mt-0.5">Mức ${rec.gluc || 1}</div>
          </div>
        </div>
        <p class="text-xs text-slate-600 bg-sky-50/50 p-3 rounded-lg border border-sky-100/50">
          <b>Lời khuyên chuyên môn:</b> ${rec.recommendation}
        </p>
      </div>
    `;
  }).join('');
}

function renderDoctorHistory(containerId = 'doctor-records-container') {
  const container = document.getElementById(containerId);
  if (!container || typeof getSubmittedRecords !== 'function') return;

  const records = getSubmittedRecords();

  if (records.length === 0) {
    container.innerHTML = `
      <div class="text-center py-16 p-8">
        <div class="w-16 h-16 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center mx-auto text-3xl mb-4">
          <i class="fa-solid fa-folder-closed"></i>
        </div>
        <h3 class="text-lg font-bold text-slate-800">Chưa có bệnh án nào trong kho lưu trữ</h3>
        <p class="text-sm text-slate-500 mt-1 max-w-md mx-auto">
          Khi bác sĩ thực hiện hội chẩn và bấm "Lưu hồ sơ", thông tin bệnh án cùng phân tích XAI sẽ được lưu lại tại đây.
        </p>
        <a href="doctor.html" class="mt-5 px-5 py-2.5 rounded-xl bg-sky-600 hover:bg-sky-700 text-white text-sm font-bold shadow transition active:scale-95 inline-flex items-center gap-2">
          <i class="fa-solid fa-stethoscope"></i> Khám ca mới
        </a>
      </div>
    `;
    return;
  }

  container.innerHTML = `
    <div class="overflow-x-auto">
      <table class="w-full text-left border-collapse text-sm">
        <thead>
          <tr class="bg-slate-50 border-b border-slate-200 text-xs font-bold text-slate-500">
            <th class="py-3.5 px-4">Tên bệnh nhân</th>
            <th class="py-3.5 px-4">Ngày khám</th>
            <th class="py-3.5 px-4">Phân tầng rủi ro</th>
            <th class="py-3.5 px-4">Huyết áp</th>
            <th class="py-3.5 px-4">BMI</th>
            <th class="py-3.5 px-4">Khuyến nghị & phác đồ</th>
            <th class="py-3.5 px-4 text-center">Thao tác</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          ${records.map(r => {
            const isHigh = r.riskProb >= 0.65 || (r.riskLevel && r.riskLevel.includes('cao'));
            const isMod = !isHigh && (r.riskProb >= 0.35 || (r.riskLevel && r.riskLevel.includes('trung')));
            const badge = isHigh ? 'badge-high' : isMod ? 'badge-mod' : 'badge-low';
            return `
              <tr class="hover:bg-slate-50/80 transition">
                <td class="py-3 px-4 font-bold text-slate-900">
                  <i class="fa-solid fa-user-circle text-slate-400 mr-1.5"></i> ${r.patientName || 'Bệnh nhân'}
                </td>
                <td class="py-3 px-4 text-xs text-slate-500">${r.date}</td>
                <td class="py-3 px-4">
                  <span class="px-2.5 py-1 rounded-full text-xs font-bold ${badge}">
                    ${r.riskLevel} (${(r.riskProb * 100).toFixed(1)}%)
                  </span>
                </td>
                <td class="py-3 px-4 font-semibold text-slate-800">${r.bp}</td>
                <td class="py-3 px-4 font-semibold text-slate-800">${r.bmi}</td>
                <td class="py-3 px-4 text-xs text-slate-600 max-w-xs truncate" title="${r.recommendation}">
                  ${r.recommendation}
                </td>
                <td class="py-3 px-4 text-center">
                  <button onclick="deleteSubmittedRecord(${r.id}, () => renderDoctorHistory('${containerId}'))" class="text-slate-300 hover:text-red-500 transition p-1" title="Xóa bệnh án này">
                    <i class="fa-solid fa-trash-can"></i>
                  </button>
                </td>
              </tr>
            `;
          }).join('')}
        </tbody>
      </table>
    </div>
  `;
}
