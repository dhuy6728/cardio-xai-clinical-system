/**
 * CardioCare AI - Header, Session & Navigation Manager
 * Sets active state on navigation tabs and renders authentication controls on every page.
 */

document.addEventListener('DOMContentLoaded', () => {
  // 1. Xác định trang hiện tại
  const currentPath = window.location.pathname.split('/').pop() || 'index.html';
  
  // 2. Cập nhật trạng thái active của các tab navigation
  const navLinks = document.querySelectorAll('.nav-tab-link');
  navLinks.forEach(link => {
    const href = link.getAttribute('href');
    if (href === currentPath || (currentPath === '' && href === 'index.html')) {
      link.classList.remove('border-transparent', 'text-slate-600');
      link.classList.add('border-sky-600', 'text-sky-600', 'font-bold');
    } else {
      link.classList.remove('border-sky-600', 'text-sky-600', 'font-bold');
      link.classList.add('border-transparent', 'text-slate-600');
    }
  });

  // 3. Highlight vai trò Bệnh nhân / Bác sĩ
  const isDoctorPage = currentPath.includes('doctor');
  const patientRoleBtn = document.getElementById('role-patient-btn');
  const doctorRoleBtn = document.getElementById('role-doctor-btn');

  if (patientRoleBtn && doctorRoleBtn) {
    if (isDoctorPage) {
      doctorRoleBtn.className = "flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-sm font-semibold transition-all shadow-sm bg-white text-sky-700";
      patientRoleBtn.className = "flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-sm font-semibold transition-all text-slate-600 hover:text-slate-900";
    } else {
      patientRoleBtn.className = "flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-sm font-semibold transition-all shadow-sm bg-white text-sky-700";
      doctorRoleBtn.className = "flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-sm font-semibold transition-all text-slate-600 hover:text-slate-900";
    }
  }

  // 4. Render khu vực xác thực tài khoản (Auth State) trên Header
  renderNavbarAuthArea();
});

function renderNavbarAuthArea() {
  const authContainer = document.getElementById('navbar-auth-container');
  if (!authContainer) return;

  const user = (typeof getCurrentUser === 'function') ? getCurrentUser() : null;

  if (user) {
    const isDoctor = user.role === 'doctor';
    const roleIcon = isDoctor ? '👨‍⚕️' : '🫀';
    const roleLabel = isDoctor ? 'Bác sĩ' : 'Bệnh nhân';
    const roleBadgeColor = isDoctor ? 'bg-sky-100 text-sky-800' : 'bg-emerald-100 text-emerald-800';

    authContainer.innerHTML = `
      <div class="flex items-center gap-2.5 bg-slate-50 border border-slate-200 px-3 py-1.5 rounded-xl text-xs">
        <span class="w-7 h-7 rounded-full bg-sky-600 text-white flex items-center justify-center font-bold text-xs shadow-sm">
          ${user.fullName ? user.fullName.charAt(0).toUpperCase() : 'U'}
        </span>
        <div class="hidden sm:block text-left">
          <div class="font-bold text-slate-800 leading-tight">${user.fullName || 'Người dùng'}</div>
          <span class="px-1.5 py-0.2 rounded text-[10px] font-semibold ${roleBadgeColor}">
            ${roleIcon} ${roleLabel}
          </span>
        </div>
        <button onclick="logoutUser()" title="Đăng xuất" class="ml-1 p-1.5 text-slate-400 hover:text-rose-600 rounded-lg hover:bg-slate-100 transition">
          <i class="fa-solid fa-arrow-right-from-bracket text-sm"></i>
        </button>
      </div>
    `;
  } else {
    authContainer.innerHTML = `
      <a href="auth.html" class="flex items-center gap-2 px-4 py-2 rounded-xl bg-sky-600 hover:bg-sky-700 text-white text-xs sm:text-sm font-bold shadow-sm transition active:scale-95">
        <i class="fa-solid fa-user"></i>
        <span>Đăng nhập</span>
      </a>
    `;
  }
}
