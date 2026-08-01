/**
 * Animation Controller (~2KB)
 * Handles: scroll reveals, counter animations, stagger delays.
 * Framework-agnostic — initialized by per-framework wrappers.
 */

export function initAnimations() {
  if (typeof window === 'undefined') return;
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    document.querySelectorAll('.reveal, .reveal-fade-up, .reveal-fade-in, .reveal-scale, .reveal-slide-left, .reveal-slide-right, .reveal-blur, .text-reveal, .stagger-children').forEach(el => {
      el.classList.add('revealed');
    });
    return;
  }

  initScrollReveals();
  initCounters();
}

function initScrollReveals() {
  const revealSelectors = '.reveal, .reveal-fade-up, .reveal-fade-in, .reveal-scale, .reveal-slide-left, .reveal-slide-right, .reveal-blur, .text-reveal, .stagger-children';
  const elements = document.querySelectorAll(revealSelectors);
  if (!elements.length) return;

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;

      const el = entry.target;

      if (el.classList.contains('stagger-children')) {
        const staggerDelay = parseInt(el.dataset.staggerDelay || '100', 10);
        Array.from(el.children).forEach((child, i) => {
          child.style.transitionDelay = `${i * staggerDelay}ms`;
        });
      }

      el.classList.add('revealed');
      observer.unobserve(el);
    });
  }, {
    threshold: 0.15,
    rootMargin: '0px 0px -50px 0px'
  });

  elements.forEach(el => observer.observe(el));
}

function initCounters() {
  const counters = document.querySelectorAll('.counter-animate');
  if (!counters.length) return;

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (!entry.isIntersecting) return;
      animateCounter(entry.target);
      observer.unobserve(entry.target);
    });
  }, { threshold: 0.5 });

  counters.forEach(el => observer.observe(el));
}

function animateCounter(el) {
  const target = parseInt(el.dataset.count || '0', 10);
  const duration = 1500;
  const start = performance.now();

  function easeOutCubic(t) {
    return 1 - Math.pow(1 - t, 3);
  }

  function update(now) {
    const elapsed = now - start;
    const progress = Math.min(elapsed / duration, 1);
    const eased = easeOutCubic(progress);
    el.textContent = Math.round(target * eased).toLocaleString();

    if (progress < 1) {
      requestAnimationFrame(update);
    }
  }

  requestAnimationFrame(update);
}
