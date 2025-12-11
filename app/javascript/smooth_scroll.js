document.addEventListener('turbo:load', () => {
  // ページ内リンクのスムーズスクロール
  const smoothScrollLinks = document.querySelectorAll('a[href^="#"]');
  
  smoothScrollLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      
      const targetId = link.getAttribute('href');
      if (targetId === '#') return;
      
      const targetElement = document.querySelector(targetId);
      if (targetElement) {
        // ヘッダーの高さを考慮したオフセット
        const headerHeight = document.querySelector('header').offsetHeight;
        const targetPosition = targetElement.offsetTop - headerHeight - 20;
        
        window.scrollTo({
          top: targetPosition,
          behavior: 'smooth'
        });
        
        // URLにハッシュを追加（履歴に残す）
        history.pushState(null, null, targetId);
      }
    });
  });
  
  // スクロール時のアクティブリンクハイライト
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('nav a[href^="#"]');
  
  function highlightActiveSection() {
    const scrollPosition = window.scrollY;
    const headerHeight = document.querySelector('header').offsetHeight;
    
    sections.forEach(section => {
      const sectionTop = section.offsetTop - headerHeight - 100;
      const sectionBottom = sectionTop + section.offsetHeight;
      
      if (scrollPosition >= sectionTop && scrollPosition < sectionBottom) {
        const sectionId = section.getAttribute('id');
        
        navLinks.forEach(link => {
          link.classList.remove('text-blue-600', 'font-semibold');
          link.classList.add('text-gray-700');
          
          if (link.getAttribute('href') === `#${sectionId}`) {
            link.classList.remove('text-gray-700');
            link.classList.add('text-blue-600', 'font-semibold');
          }
        });
      }
    });
  }
  
  // スクロールイベントのデバウンス処理
  let scrollTimer;
  window.addEventListener('scroll', () => {
    if (scrollTimer) clearTimeout(scrollTimer);
    scrollTimer = setTimeout(highlightActiveSection, 10);
  });
  
  // 初期状態でもハイライト
  highlightActiveSection();
  
  // ページ読み込み時にハッシュがある場合の処理
  if (window.location.hash) {
    setTimeout(() => {
      const targetElement = document.querySelector(window.location.hash);
      if (targetElement) {
        const headerHeight = document.querySelector('header').offsetHeight;
        const targetPosition = targetElement.offsetTop - headerHeight - 20;
        
        window.scrollTo({
          top: targetPosition,
          behavior: 'instant'
        });
      }
    }, 100);
  }
});