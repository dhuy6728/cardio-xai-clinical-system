/**
 * CardioCare AI - Header & Navigation Management
 * Sets active state on navigation tabs and coordinates patient / doctor roles.
 */

document.addEventListener('DOMContentLoaded', () => {
  // Determine current page from URL
  const currentPath = window.location.pathname.split('/').pop() || 'index.html';
  
  // Update Patient tabs
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

  // Highlight active role button
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
});
