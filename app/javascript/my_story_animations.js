// My Story ページのスクロールアニメーション
document.addEventListener('DOMContentLoaded', function() {
  // スクロールアニメーション
  function revealOnScroll() {
    const reveals = document.querySelectorAll('.scroll-reveal');
    
    reveals.forEach(element => {
      const windowHeight = window.innerHeight;
      const elementTop = element.getBoundingClientRect().top;
      const elementVisible = 150;
      
      if (elementTop < windowHeight - elementVisible) {
        element.classList.add('revealed');
      }
    });
  }

  window.addEventListener('scroll', revealOnScroll);
  
  // 初期表示時もチェック
  revealOnScroll();
});
