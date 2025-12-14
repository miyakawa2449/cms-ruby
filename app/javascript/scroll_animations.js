// Scroll-triggered animations for sections
document.addEventListener('DOMContentLoaded', () => {
  // Add animation classes to sections
  const animateSections = document.querySelectorAll('section');
  
  animateSections.forEach(section => {
    // Skip hero section
    if (section.id === 'hero') return;
    
    // Add initial hidden state
    section.classList.add('opacity-0', 'translate-y-10', 'transition-all', 'duration-700');
  });
  
  // Intersection Observer for scroll animations
  const observerOptions = {
    threshold: 0.1,
    rootMargin: '-50px 0px'
  };
  
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        // Animate in
        entry.target.classList.remove('opacity-0', 'translate-y-10');
        entry.target.classList.add('opacity-100', 'translate-y-0');
        
        // Stagger animations for child elements
        const animateElements = entry.target.querySelectorAll('.animate-fade-in');
        animateElements.forEach((el, index) => {
          setTimeout(() => {
            el.classList.add('opacity-100', 'translate-y-0');
            el.classList.remove('opacity-0', 'translate-y-4');
          }, index * 100);
        });
      }
    });
  }, observerOptions);
  
  // Observe all sections
  animateSections.forEach(section => {
    if (section.id !== 'hero') {
      observer.observe(section);
    }
  });
  
  // Add animation classes to specific elements
  const fadeInElements = document.querySelectorAll('.section-title, .section-description, article, .feature-card');
  fadeInElements.forEach(el => {
    el.classList.add('animate-fade-in', 'opacity-0', 'translate-y-4', 'transition-all', 'duration-500');
  });
});