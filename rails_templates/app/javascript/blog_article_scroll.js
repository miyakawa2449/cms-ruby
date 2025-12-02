// ブログ記事詳細ページのスクロールプログレスバー
document.addEventListener('DOMContentLoaded', function() {
  const progressBar = document.getElementById('progressBar');
  
  if (progressBar) {
    window.addEventListener('scroll', function() {
      const scrollTop = window.pageYOffset || document.documentElement.scrollTop;
      const docHeight = document.body.scrollHeight - window.innerHeight;
      const scrollPercent = (scrollTop / docHeight) * 100;
      progressBar.style.width = scrollPercent + '%';
    });
  }
});
