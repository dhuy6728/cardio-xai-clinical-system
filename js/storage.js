/**
 * CardioCare AI - LocalStorage Repository Manager
 * Manages genuinely submitted patient and doctor cases.
 */

const REPO_KEY = 'cardiocare_submitted_records';

function getSubmittedRecords() {
  try {
    const raw = localStorage.getItem(REPO_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) return parsed;
    }
  } catch (e) {
    console.error("Lỗi đọc dữ liệu kho lưu trữ:", e);
  }
  return []; // Không có mẫu bệnh nhân ví dụ ảo! Chỉ hiển thị các ca thật đã submit.
}

function addSubmittedRecord(record) {
  const records = getSubmittedRecords();
  record.id = Date.now();
  records.unshift(record);
  localStorage.setItem(REPO_KEY, JSON.stringify(records));
  return record;
}

function deleteSubmittedRecord(id, onDeletedCallback) {
  if (!confirm("Bạn có chắc chắn muốn xóa hồ sơ này khỏi kho lưu trữ?")) return;
  let records = getSubmittedRecords();
  records = records.filter(r => r.id !== id);
  localStorage.setItem(REPO_KEY, JSON.stringify(records));
  if (typeof showToast === 'function') {
    showToast("Đã xóa hồ sơ khỏi kho lưu trữ", "info");
  }
  if (typeof onDeletedCallback === 'function') {
    onDeletedCallback();
  }
}
