/**
 * CardioCare AI - Toast Notification System
 */

let toastTimeout = null;

function ensureToastContainer() {
  if (document.getElementById('toast-notification')) return;
  const container = document.createElement('div');
  container.id = 'toast-notification';
  container.className = 'fixed top-5 right-5 z-[100] transform translate-y-[-120%] opacity-0 pointer-events-none transition-all duration-300 max-w-md w-full px-4';
  container.innerHTML = `
    <div id="toast-body" class="bg-slate-900 text-white rounded-2xl p-4 shadow-2xl flex items-center gap-3 border border-slate-700">
      <div id="toast-icon" class="text-xl text-emerald-400">
        <i class="fa-solid fa-circle-check"></i>
      </div>
      <div class="flex-1 text-sm font-medium" id="toast-message">Thông báo thành công</div>
      <button onclick="hideToast()" class="text-slate-400 hover:text-white text-sm p-1">
        <i class="fa-solid fa-xmark"></i>
      </button>
    </div>
  `;
  document.body.appendChild(container);
}

function showToast(message, type = 'success') {
  ensureToastContainer();
  const toast = document.getElementById('toast-notification');
  const msg = document.getElementById('toast-message');
  const icon = document.getElementById('toast-icon');

  msg.innerText = message;
  if (type === 'success') {
    icon.className = "text-xl text-emerald-400";
    icon.innerHTML = '<i class="fa-solid fa-circle-check"></i>';
  } else if (type === 'info') {
    icon.className = "text-xl text-sky-400";
    icon.innerHTML = '<i class="fa-solid fa-circle-info"></i>';
  } else {
    icon.className = "text-xl text-amber-400";
    icon.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i>';
  }

  toast.classList.remove('opacity-0', 'pointer-events-none', 'translate-y-[-120%]');
  toast.classList.add('opacity-100', 'translate-y-0');

  if (toastTimeout) clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => {
    hideToast();
  }, 3500);
}

function hideToast() {
  const toast = document.getElementById('toast-notification');
  if (!toast) return;
  toast.classList.remove('opacity-100', 'translate-y-0');
  toast.classList.add('opacity-0', 'pointer-events-none', 'translate-y-[-120%]');
}
