/**
/**
 * CardioCare AI - Authentication & Session Management
 * Đồng bộ logic đăng nhập, đăng ký và vai trò người dùng (Bác sĩ / Bệnh nhân)
 * Hỗ trợ Dual-Storage: LocalStorage + Cloud Firestore collection "users"
 */

const USER_SESSION_KEY = 'cardiocare_current_user';
const USERS_REPO_KEY = 'cardiocare_registered_users';

// Lấy thông tin người dùng đang đăng nhập
function getCurrentUser() {
  try {
    const raw = localStorage.getItem(USER_SESSION_KEY);
    if (raw) return JSON.parse(raw);
  } catch (e) {
    console.error("Lỗi đọc phiên người dùng:", e);
  }
  return null;
}

// Lưu phiên đăng nhập
function setCurrentUser(user) {
  try {
    if (user) {
      localStorage.setItem(USER_SESSION_KEY, JSON.stringify(user));
    } else {
      localStorage.removeItem(USER_SESSION_KEY);
    }
  } catch (e) {
    console.error("Lỗi ghi phiên người dùng:", e);
  }
}

// Đăng xuất
function logoutUser() {
  localStorage.removeItem(USER_SESSION_KEY);
  if (typeof showToast === 'function') {
    showToast("Đã đăng xuất tài khoản thành công!", "info");
  }
  setTimeout(() => {
    window.location.href = 'index.html';
  }, 500);
}

// Lấy danh sách tài khoản đã đăng ký trong máy
function getRegisteredUsers() {
  try {
    const raw = localStorage.getItem(USERS_REPO_KEY);
    if (raw) {
      const list = JSON.parse(raw);
      if (Array.isArray(list)) return list;
    }
  } catch (e) {}
  return [];
}

// Lưu danh sách tài khoản
function saveRegisteredUsers(users) {
  try {
    localStorage.setItem(USERS_REPO_KEY, JSON.stringify(users));
  } catch (e) {}
}

// Đăng ký tài khoản mới (đồng bộ với Mobile Flutter)
async function registerUser({ email, phone, password, fullName, role = 'patient' }) {
  const cleanEmail = (email || '').trim().toLowerCase();
  const cleanPhone = (phone || '').trim();
  const cleanName = (fullName || '').trim();

  if (!cleanName) throw new Error("Vui lòng nhập họ và tên");
  if (!password || password.length < 6) throw new Error("Mật khẩu tối thiểu 6 ký tự");

  const users = getRegisteredUsers();

  // Kiểm tra trùng lặp
  for (const u of users) {
    if (cleanEmail && (u.email || '').toLowerCase() === cleanEmail) {
      throw new Error("Email này đã được đăng ký trong hệ thống! Vui lòng đăng nhập hoặc chọn email khác.");
    }
    if (cleanPhone && (u.phone || '').trim() === cleanPhone) {
      throw new Error("Số điện thoại này đã được đăng ký trong hệ thống! Vui lòng đăng nhập hoặc chọn số khác.");
    }
  }

  const newUser = {
    id: Date.now(),
    fullName: cleanName,
    email: cleanEmail || `${cleanPhone}@cardiocare.vn`,
    phone: cleanPhone || null,
    password: password,
    role: role, // 'patient' hoặc 'doctor'
    createdAt: new Date().toISOString()
  };

  users.push(newUser);
  saveRegisteredUsers(users);

  // Đồng bộ lên Firebase Firestore nếu có kết nối
  if (typeof isFirebaseConfigured === 'function' && isFirebaseConfigured() && typeof db !== 'undefined' && db) {
    try {
      await db.collection('users').doc(String(newUser.id)).set({
        id: newUser.id,
        full_name: newUser.fullName,
        email: newUser.email,
        phone: newUser.phone,
        role: newUser.role,
        created_at: newUser.createdAt
      });
      console.log("Đã đồng bộ tài khoản mới lên Firestore collection 'users'");
    } catch (err) {
      console.warn("Lưu tài khoản lên Firestore lưu ý:", err);
    }
  }

  // Tự động thiết lập phiên đăng nhập
  setCurrentUser({
    id: newUser.id,
    fullName: newUser.fullName,
    email: newUser.email,
    phone: newUser.phone,
    role: newUser.role
  });

  return newUser;
}

// Đăng nhập tài khoản
async function loginUser({ identifier, password, role }) {
  const cleanId = (identifier || '').trim().toLowerCase();
  if (!cleanId) throw new Error("Vui lòng nhập email hoặc số điện thoại");
  if (!password) throw new Error("Vui lòng nhập mật khẩu");

  const users = getRegisteredUsers();
  let matchedUser = null;

  for (const u of users) {
    const uEmail = (u.email || '').toLowerCase();
    const uPhone = (u.phone || '').trim();
    if (uEmail === cleanId || uPhone === cleanId || uEmail.startsWith(`${cleanId}@`)) {
      matchedUser = u;
      break;
    }
  }

  // Thử tìm trên Firebase Firestore nếu máy chưa có
  if (!matchedUser && typeof isFirebaseConfigured === 'function' && isFirebaseConfigured() && typeof db !== 'undefined' && db) {
    try {
      const snap = await db.collection('users').get();
      snap.forEach(doc => {
        const d = doc.data();
        const dEmail = (d.email || '').toLowerCase();
        const dPhone = (d.phone || '').trim();
        if (dEmail === cleanId || dPhone === cleanId || dEmail.startsWith(`${cleanId}@`)) {
          matchedUser = {
            id: d.id || doc.id,
            fullName: d.full_name || d.fullName || 'Người dùng',
            email: d.email,
            phone: d.phone,
            role: d.role || role || 'patient',
            password: password // Giả lập khớp nếu từ cloud
          };
        }
      });
    } catch (e) {
      console.warn("Tìm user trên Firestore:", e);
    }
  }

  if (!matchedUser) {
    throw new Error("Tài khoản chưa được đăng ký trong hệ thống! Vui lòng kiểm tra lại hoặc đăng ký tài khoản mới.");
  }

  if (matchedUser.password && matchedUser.password !== password) {
    throw new Error("Mật khẩu không chính xác! Vui lòng kiểm tra lại.");
  }

  // Cập nhật vai trò nếu người dùng chọn vai trò cụ thể khi đăng nhập
  if (role) {
    matchedUser.role = role;
  }

  const sessionData = {
    id: matchedUser.id,
    fullName: matchedUser.fullName || matchedUser.full_name || 'Người dùng',
    email: matchedUser.email,
    phone: matchedUser.phone,
    role: matchedUser.role || 'patient'
  };

  setCurrentUser(sessionData);
  return sessionData;
}
