/**
 * CardioCare AI - Medical Articles Component Logic
 */

function renderArticlesGrid(containerId = 'articles-grid') {
  const container = document.getElementById(containerId);
  if (!container || typeof ARTICLES === 'undefined') return;

  container.innerHTML = ARTICLES.map(art => `
    <div class="bg-white rounded-2xl border border-slate-200 hover-card flex flex-col p-6">
      <div class="flex items-center justify-between mb-3">
        <span class="text-xs font-semibold px-2.5 py-1 rounded-full ${art.badgeColor}">
          ${art.category}
        </span>
        <span class="text-xs text-slate-400 flex items-center gap-1">
          <i class="fa-regular fa-clock"></i> ${art.readTime}
        </span>
      </div>
      <h3 class="text-lg font-bold text-slate-900 mb-2 leading-snug hover:text-sky-600 cursor-pointer transition" onclick="openArticleModal('${art.id}')">
        ${art.title}
      </h3>
      <p class="text-sm text-slate-600 mb-4 line-clamp-3 leading-relaxed">
        ${art.summary}
      </p>
      <div class="mt-auto pt-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
        <span class="font-medium text-slate-700">
          <i class="fa-solid fa-user-doctor mr-1 text-sky-600"></i> ${art.author.split(' - ')[0]}
        </span>
        <button onclick="openArticleModal('${art.id}')" class="text-sky-600 hover:text-sky-800 font-bold flex items-center gap-1 active:scale-95">
          Đọc tiếp <i class="fa-solid fa-arrow-right text-[10px]"></i>
        </button>
      </div>
    </div>
  `).join('');
}

function openArticleModal(id) {
  if (typeof ARTICLES === 'undefined') return;
  const art = ARTICLES.find(a => a.id === id);
  if (!art) return;
  const modal = document.getElementById('article-modal');
  const container = document.getElementById('modal-article-body');
  if (!modal || !container) return;

  container.innerHTML = `
    <div class="flex items-center gap-2 mb-3">
      <span class="text-xs font-semibold px-2.5 py-1 rounded-full ${art.badgeColor}">${art.category}</span>
      <span class="text-xs text-slate-400"><i class="fa-regular fa-clock mr-1"></i>${art.readTime}</span>
    </div>
    <h2 class="text-2xl font-bold text-slate-900 mb-3">${art.title}</h2>
    <div class="text-xs text-slate-500 mb-6 pb-4 border-b border-slate-100 flex items-center justify-between">
      <span><i class="fa-solid fa-user-doctor mr-1.5 text-sky-600"></i><b>Tác giả:</b> ${art.author}</span>
      <span><b>Ngày đăng:</b> ${art.date}</span>
    </div>
    <div class="bg-sky-50 rounded-xl p-4 mb-6 border border-sky-100">
      <h4 class="font-bold text-xs tracking-wider text-sky-800 mb-2">Điểm cốt lõi cần nhớ:</h4>
      <ul class="text-xs space-y-1.5 text-slate-700 pl-4 list-disc">
        ${art.takeaways.map(t => `<li>${t}</li>`).join('')}
      </ul>
    </div>
    <div class="text-sm leading-relaxed text-slate-700 space-y-4">
      ${art.content}
    </div>
  `;
  modal.classList.remove('hidden');
  document.body.style.overflow = 'hidden';
}

function closeArticleModal() {
  const modal = document.getElementById('article-modal');
  if (modal) {
    modal.classList.add('hidden');
    document.body.style.overflow = '';
  }
}

// Modal event listeners
document.addEventListener('DOMContentLoaded', () => {
  const modal = document.getElementById('article-modal');
  if (modal) {
    modal.addEventListener('click', (e) => {
      if (e.target.id === 'article-modal') closeArticleModal();
    });
  }
  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeArticleModal();
  });
});
