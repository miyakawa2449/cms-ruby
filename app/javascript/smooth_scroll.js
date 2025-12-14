// Smooth scroll functionality for anchor links
document.addEventListener('DOMContentLoaded', () => {
  // Get all anchor links that start with #
  const anchorLinks = document.querySelectorAll('a[href^="#"]');
  
  anchorLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      
      const targetId = link.getAttribute('href');
      if (targetId === '#') return;
      
      const targetSection = document.querySelector(targetId);
      if (!targetSection) return;
      
      // Calculate the offset (accounting for fixed header)
      const headerOffset = 80;
      const elementPosition = targetSection.getBoundingClientRect().top;
      const offsetPosition = elementPosition + window.pageYOffset - headerOffset;
      
      // Smooth scroll to the target
      window.scrollTo({
        top: offsetPosition,
        behavior: 'smooth'
      });
      
      // Update active state
      updateActiveLink(link);
    });
  });
  
  // Update active link based on current position
  function updateActiveLink(activeLink) {
    anchorLinks.forEach(link => {
      link.classList.remove('text-blue-600', 'font-semibold');
      link.classList.add('text-gray-700');
    });
    
    activeLink.classList.remove('text-gray-700');
    activeLink.classList.add('text-blue-600', 'font-semibold');
  }
  
  // Highlight active section on scroll
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('nav a[href^="#"]');
  
  function highlightActiveSection() {
    const scrollY = window.pageYOffset;
    
    sections.forEach((section) => {
      const sectionHeight = section.offsetHeight;
      const sectionTop = section.offsetTop - 100;
      const sectionId = section.getAttribute('id');
      
      if (scrollY > sectionTop && scrollY <= sectionTop + sectionHeight) {
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
  
  // Throttle scroll event
  let scrollTimer;
  window.addEventListener('scroll', () => {
    if (scrollTimer) {
      window.cancelAnimationFrame(scrollTimer);
    }
    scrollTimer = window.requestAnimationFrame(highlightActiveSection);
  });
});