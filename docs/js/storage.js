/**
 * CardioCare AI - Repository Manager with Firebase Cloud Sync
 * Manages genuinely submitted patient and doctor cases.
 * Supports dual-sync: Cloud Firestore (realtime) with LocalStorage fallback.
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
  return [];
}

function saveLocalRecords(records) {
  try {
    localStorage.setItem(REPO_KEY, JSON.stringify(records));
  } catch (e) {
    console.error("Lỗi ghi dữ liệu kho lưu trữ:", e);
  }
}

function addSubmittedRecord(record) {
  const records = getSubmittedRecords();
  record.id = record.id || Date.now();
  records.unshift(record);
  saveLocalRecords(records);

  // Đồng bộ lên Firebase Firestore nếu đã cấu hình
  if (typeof isFirebaseConfigured === 'function' && isFirebaseConfigured() && typeof db !== 'undefined' && db) {
    db.collection('assessment_records').doc(String(record.id)).set(record)
      .then(() => {
        console.log("Đã đồng bộ ca khám lên Firebase Firestore thành công!");
      })
      .catch((err) => {
        console.warn("Lỗi đồng bộ lên Firebase:", err);
      });
  }

  return record;
}

function deleteSubmittedRecord(id, onDeletedCallback) {
  if (!confirm("Bạn có chắc chắn muốn xóa hồ sơ này khỏi kho lưu trữ?")) return;

  let records = getSubmittedRecords();
  records = records.filter(r => r.id !== id);
  saveLocalRecords(records);

  // Xóa trên Firebase Firestore nếu có
  if (typeof isFirebaseConfigured === 'function' && isFirebaseConfigured() && typeof db !== 'undefined' && db) {
    db.collection('assessment_records').doc(String(id)).delete()
      .then(() => {
        console.log("Đã xóa hồ sơ trên Firebase Firestore!");
      })
      .catch((err) => {
        console.warn("Lỗi xóa hồ sơ trên Firebase:", err);
      });
  }

  if (typeof showToast === 'function') {
    showToast("Đã xóa hồ sơ khỏi kho lưu trữ", "info");
  }
  if (typeof onDeletedCallback === 'function') {
    onDeletedCallback();
  }
}

// Lắng nghe dữ liệu thời gian thực từ Firebase Firestore
function initRealtimeFirestoreSync(onUpdateCallback) {
  if (typeof isFirebaseConfigured === 'function' && isFirebaseConfigured() && typeof db !== 'undefined' && db) {
    db.collection('assessment_records').onSnapshot((snapshot) => {
      const firestoreRecords = [];
      snapshot.forEach((doc) => {
        firestoreRecords.push(doc.data());
      });
      // Sắp xếp mới nhất lên đầu
      firestoreRecords.sort((a, b) => (b.id || 0) - (a.id || 0));

      if (firestoreRecords.length > 0) {
        saveLocalRecords(firestoreRecords);
        if (typeof onUpdateCallback === 'function') {
          onUpdateCallback();
        }
      }
    }, (error) => {
      console.warn("Lỗi theo dõi realtime Firestore:", error);
    });
  }
}
