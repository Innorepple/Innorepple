/**
 * Main script for Donation For Maitree website.
 * Handles navigation, animations, and form interactions.
 */
document.addEventListener('DOMContentLoaded', () => {

  // --- Element Selections ---
  const header = document.getElementById('header');
  const mobileToggle = document.getElementById('mobileToggle');
  const mobileMenu = document.getElementById('mobileMenu');
  const hamburgerIcon = document.getElementById('hamburgerIcon');
  const closeIcon = document.getElementById('closeIcon');
  const navLinks = document.querySelectorAll('.nav-link');
  const presetButtons = document.querySelectorAll('.preset');
  const customAmountInput = document.getElementById('customAmount');
  const donateBtn = document.getElementById('donateBtn');

  /**
   * Initializes the mobile menu functionality.
   */
  function initMobileMenu() {
    if (!mobileToggle || !mobileMenu) return;

    const toggleMenu = (forceClose = false) => {
      const isOpen = !mobileMenu.classList.contains('hidden');
      if (forceClose || isOpen) {
        mobileMenu.classList.add('hidden');
        hamburgerIcon.classList.remove('hidden');
        closeIcon.classList.add('hidden');
        mobileToggle.setAttribute('aria-expanded', 'false');
        document.body.classList.remove('overflow-hidden');
      } else {
        mobileMenu.classList.remove('hidden');
        hamburgerIcon.classList.add('hidden');
        closeIcon.classList.remove('hidden');
        mobileToggle.setAttribute('aria-expanded', 'true');
        document.body.classList.add('overflow-hidden');
      }
    };

    mobileToggle.addEventListener('click', () => toggleMenu());
    mobileMenu.querySelectorAll('a').forEach(link => {
      link.addEventListener('click', () => toggleMenu(true));
    });
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') toggleMenu(true);
    });
  }

  /**
   * Initializes scroll-related effects like the sticky header and active nav link highlighting.
   */
  function initScrollEffects() {
    let ticking = false;

    const handleScroll = () => {
      // Sticky header
      header.classList.toggle('scrolled', window.scrollY > 50);

      // Active nav link highlighting
      let currentSection = '';
      const sections = Array.from(navLinks).map(link => document.querySelector(link.getAttribute('href'))).filter(Boolean);
      
      sections.forEach(section => {
        const sectionTop = section.offsetTop - 80; // Adjusted offset
        if (window.scrollY >= sectionTop) {
          currentSection = section.getAttribute('id');
        }
      });

      navLinks.forEach(link => {
        const linkHref = link.getAttribute('href').substring(1);
        const isHeroLink = link.getAttribute('href') === '#home';
        
        // Handle nav link text color on transparent vs. scrolled header
        if (window.scrollY < 50 && !isHeroLink) {
             link.classList.remove('text-blue-600');
        } else {
            link.classList.toggle('text-blue-600', linkHref === currentSection);
        }
      });
    };

    window.addEventListener('scroll', () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          handleScroll();
          ticking = false;
        });
        ticking = true;
      }
    }, { passive: true });
    
    handleScroll(); // Initial check on page load
  }

  /**
   * Initializes the fade-in animations on scroll.
   */
  function initAnimations() {
    const animatedElements = document.querySelectorAll('.fade-in');
    if (!animatedElements.length) return;

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('in-view');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.1 });

    animatedElements.forEach(el => observer.observe(el));
  }

  /**
   * Initializes the donation form interactions.
   */
  function initDonationForm() {
    if (!presetButtons.length || !customAmountInput || !donateBtn) return;

    presetButtons.forEach(btn => {
      btn.addEventListener('click', (e) => {
        presetButtons.forEach(b => b.classList.remove('ring-2', 'ring-blue-500', 'border-blue-500'));
        e.currentTarget.classList.add('ring-2', 'ring-blue-500', 'border-blue-500');

        if (e.currentTarget.dataset.custom) {
            customAmountInput.value = '';
            customAmountInput.focus();
        } else {
            const amountText = e.currentTarget.textContent.replace(/[^\d]/g, '');
            customAmountInput.value = amountText;
        }
      });
    });

    donateBtn.addEventListener('click', () => {
      const value = parseFloat(customAmountInput.value);
      if (isNaN(value) || value <= 0) {
        alert('Please enter a valid donation amount.');
        customAmountInput.focus();
        return;
      }
      if (confirm(`You are about to donate ₹${value.toFixed(2)}. Proceed?`)) {
        alert('Thank you! Redirecting to payment gateway...');
        // In a real application, you would redirect or open a payment modal here.
        customAmountInput.value = '500'; // Reset to default
        presetButtons.forEach(b => b.classList.remove('ring-2', 'ring-blue-500', 'border-blue-500'));
        document.querySelector('.preset.active').classList.add('ring-2', 'ring-blue-500', 'border-blue-500');
      }
    });
  }

  /**
   * Initializes smooth scrolling for anchor links.
   */
  function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
      anchor.addEventListener('click', function(e) {
        e.preventDefault();
        const targetId = this.getAttribute('href');
        const targetElement = document.querySelector(targetId);
        if (targetElement) {
          targetElement.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      });
    });
  }

  // --- Initialize all modules ---
  initMobileMenu();
  initScrollEffects();
  initAnimations();
  initDonationForm();
  initSmoothScroll();
});
