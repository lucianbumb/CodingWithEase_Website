document.documentElement.classList.add('js');

const header = document.querySelector('[data-header]');
const audienceTabs = [...document.querySelectorAll('[data-audience]')];
const audiencePanels = [...document.querySelectorAll('[data-panel]')];
const year = document.querySelector('[data-year]');

const updateHeader = () => {
  header?.classList.toggle('is-scrolled', window.scrollY > 30);
};

window.addEventListener('scroll', updateHeader, { passive: true });
updateHeader();

audienceTabs.forEach((tab) => {
  tab.addEventListener('click', () => {
    const target = tab.dataset.audience;

    audienceTabs.forEach((item) => {
      const selected = item === tab;
      item.setAttribute('aria-selected', selected ? 'true' : 'false');
      item.tabIndex = selected ? 0 : -1;
    });

    audiencePanels.forEach((panel) => {
      const active = panel.dataset.panel === target;
      panel.hidden = !active;
      panel.classList.toggle('is-active', active);
    });
  });

  tab.addEventListener('keydown', (event) => {
    if (!['ArrowLeft', 'ArrowRight'].includes(event.key)) return;
    event.preventDefault();
    const current = audienceTabs.indexOf(tab);
    const direction = event.key === 'ArrowRight' ? 1 : -1;
    const next = audienceTabs[(current + direction + audienceTabs.length) % audienceTabs.length];
    next.click();
    next.focus();
  });
});

if (year) year.textContent = new Date().getFullYear();
