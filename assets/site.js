document.documentElement.classList.add('js');

const header = document.querySelector('[data-header]');
const audienceTabs = [...document.querySelectorAll('[data-audience]')];
const audiencePanels = [...document.querySelectorAll('[data-panel]')];
const year = document.querySelector('[data-year]');
const navToggle = document.querySelector('[data-nav-toggle]');
const siteNav = document.querySelector('[data-site-nav]');

const setNavigationOpen = (open) => {
  if (!navToggle || !siteNav) return;
  navToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
  navToggle.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation');
  siteNav.classList.toggle('is-open', open);
  document.body.classList.toggle('nav-is-open', open);
};

navToggle?.addEventListener('click', () => {
  setNavigationOpen(navToggle.getAttribute('aria-expanded') !== 'true');
});

siteNav?.querySelectorAll('a').forEach((link) => {
  link.addEventListener('click', () => setNavigationOpen(false));
});

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
    if (document.querySelector('[data-diagram-dialog][open]')) return;
    setNavigationOpen(false);
    navToggle?.focus();
  }
});

window.addEventListener('resize', () => {
  if (window.innerWidth > 1000) setNavigationOpen(false);
});

const updateHeader = () => {
  header?.classList.toggle('is-scrolled', window.scrollY > 30);
};

window.addEventListener('scroll', updateHeader, { passive: true });
updateHeader();

const diagramLinks = [...document.querySelectorAll('.architecture-diagram > a, .engineering-diagram > a')];

if (diagramLinks.length && typeof HTMLDialogElement !== 'undefined') {
  const diagramDialog = document.createElement('dialog');
  diagramDialog.className = 'diagram-dialog';
  diagramDialog.dataset.diagramDialog = '';
  diagramDialog.setAttribute('aria-labelledby', 'diagram-dialog-title');
  diagramDialog.innerHTML = `
    <div class="diagram-dialog__shell">
      <header class="diagram-dialog__header">
        <div>
          <span class="diagram-dialog__eyebrow">Architecture diagram</span>
          <h2 id="diagram-dialog-title">Diagram</h2>
        </div>
        <button class="diagram-dialog__close" type="button" aria-label="Close diagram viewer">
          <span aria-hidden="true">×</span>
          <strong>Close</strong>
        </button>
      </header>
      <div class="diagram-dialog__viewport">
        <img class="diagram-dialog__image" alt="">
      </div>
    </div>`;
  document.body.append(diagramDialog);

  const diagramImage = diagramDialog.querySelector('.diagram-dialog__image');
  const diagramTitle = diagramDialog.querySelector('#diagram-dialog-title');
  const diagramClose = diagramDialog.querySelector('.diagram-dialog__close');
  let diagramTrigger = null;

  const closeDiagram = () => {
    if (diagramDialog.open) diagramDialog.close();
  };

  diagramLinks.forEach((link) => {
    link.setAttribute('aria-haspopup', 'dialog');
    link.addEventListener('click', (event) => {
      event.preventDefault();
      const sourceImage = link.querySelector('img');
      const figure = link.closest('figure');
      const caption = figure?.querySelector('figcaption strong');

      diagramTrigger = link;
      diagramImage.src = sourceImage?.currentSrc || sourceImage?.src || link.href;
      diagramImage.alt = sourceImage?.alt || '';
      diagramTitle.textContent = caption?.textContent?.trim() || 'Architecture diagram';
      document.body.classList.add('diagram-viewer-is-open');
      diagramDialog.showModal();
      diagramClose.focus();
    });
  });

  diagramClose.addEventListener('click', closeDiagram);
  diagramDialog.addEventListener('click', (event) => {
    if (event.target === diagramDialog) closeDiagram();
  });
  diagramDialog.addEventListener('close', () => {
    document.body.classList.remove('diagram-viewer-is-open');
    diagramImage.removeAttribute('src');
    diagramTrigger?.focus();
    diagramTrigger = null;
  });
}

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
