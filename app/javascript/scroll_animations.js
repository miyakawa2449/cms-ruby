// Scroll-triggered animations for sections
document.addEventListener('DOMContentLoaded', () => {
  // ========================================
  // 1. Section animations (既存のTailwindベース)
  // ========================================
  const animateSections = document.querySelectorAll('section');
  
  animateSections.forEach(section => {
    if (section.id === 'hero') return;
    section.classList.add('opacity-0', 'translate-y-10', 'transition-all', 'duration-700');
  });
  
  const sectionObserverOptions = {
    threshold: 0.1,
    rootMargin: '-50px 0px'
  };
  
  const sectionObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.remove('opacity-0', 'translate-y-10');
        entry.target.classList.add('opacity-100', 'translate-y-0');
        
        const animateElements = entry.target.querySelectorAll('.animate-fade-in');
        animateElements.forEach((el, index) => {
          setTimeout(() => {
            el.classList.add('opacity-100', 'translate-y-0');
            el.classList.remove('opacity-0', 'translate-y-4');
          }, index * 100);
        });
      }
    });
  }, sectionObserverOptions);
  
  animateSections.forEach(section => {
    if (section.id !== 'hero') {
      sectionObserver.observe(section);
    }
  });
  
  // ブログ記事ページではarticleタグのアニメーションを除外
  // （articleはIntersectionObserverで監視されていないため透明のまま残る問題を回避）
  const fadeInElements = document.querySelectorAll('.section-title, .section-description, .feature-card');
  fadeInElements.forEach(el => {
    el.classList.add('animate-fade-in', 'opacity-0', 'translate-y-4', 'transition-all', 'duration-500');
  });

});

// ========================================
// 2. scroll-reveal animations (CSSクラスベース)
// 旧実装はscrollイベント依存で、アンカーリンクの一発ジャンプでは判定が走らず
// My Story年表が透明のまま残っていた。IntersectionObserverなら到達手段に
// かかわらず「見えたら表示」が発火する。Turbo遷移後も動くようturbo:loadでも初期化
// ========================================
function setupScrollReveal() {
  const reveals = document.querySelectorAll('.scroll-reveal:not(.revealed)');
  if (reveals.length === 0) return;

  const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('revealed');
        revealObserver.unobserve(entry.target);
      }
    });
  }, { threshold: 0.1 });

  reveals.forEach(el => revealObserver.observe(el));
}

document.addEventListener('DOMContentLoaded', setupScrollReveal);
document.addEventListener('turbo:load', setupScrollReveal);