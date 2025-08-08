import { Controller } from "@hotwired/stimulus";

/**
 * Alert Controller - Handles dismiss functionality, keyboard navigation,
 * auto-dismiss with progress bar, and accessibility features for alert components.
 */
export default class extends Controller {
  static targets = ["progressBar"];
  static values = {
    dismissible: Boolean,
    autoDismiss: Boolean,
    type: String,
    alertId: String,
    dismissButtonId: String
  };

  connect() {
    this.setupAccessibility();
    this.setupKeyboardNavigation();

    if (this.autoDismissValue && this.typeValue !== 'danger') {
      this.startAutoDismiss();
    }
  }

  disconnect() {
    this.cleanup();
  }

  /**
   * Setup accessibility features
   */
  setupAccessibility() {
    // Ensure the alert is announced to screen readers
    this.element.setAttribute('aria-live', 'assertive');
    this.element.setAttribute('aria-atomic', 'true');

    // Add focus management
    if (this.dismissibleValue) {
      this.element.setAttribute('tabindex', '-1');
    }
  }

  /**
   * Setup keyboard navigation
   */
  setupKeyboardNavigation() {
    this.element.addEventListener('keydown', this.handleKeydown.bind(this));
  }

  /**
   * Handle keyboard events for accessibility
   */
  handleKeydown(event) {
    switch (event.key) {
      case 'Escape':
        if (this.dismissibleValue) {
          event.preventDefault();
          this.dismiss();
        }
        break;
      case 'Enter':
      case ' ':
        if (event.target === this.element && this.dismissibleValue) {
          event.preventDefault();
          this.dismiss();
        }
        break;
    }
  }

  /**
   * Start auto-dismiss countdown with progress bar
   */
  startAutoDismiss() {
    const duration = 5000; // 5 seconds
    const interval = 50; // Update every 50ms for smooth animation
    const steps = duration / interval;
    let currentStep = 0;

    this.autoDismissInterval = setInterval(() => {
      currentStep++;
      const progress = ((steps - currentStep) / steps) * 100;

      if (this.hasProgressBarTarget) {
        this.progressBarTarget.style.width = `${progress}%`;
      }

      if (currentStep >= steps) {
        this.dismiss();
      }
    }, interval);

    // Pause auto-dismiss on hover
    this.element.addEventListener('mouseenter', this.pauseAutoDismiss.bind(this));
    this.element.addEventListener('mouseleave', this.resumeAutoDismiss.bind(this));
    this.element.addEventListener('focusin', this.pauseAutoDismiss.bind(this));
    this.element.addEventListener('focusout', this.resumeAutoDismiss.bind(this));
  }

  /**
   * Pause auto-dismiss timer
   */
  pauseAutoDismiss() {
    if (this.autoDismissInterval) {
      clearInterval(this.autoDismissInterval);
      this.autoDismissInterval = null;
    }
  }

  /**
   * Resume auto-dismiss timer
   */
  resumeAutoDismiss() {
    if (this.autoDismissValue && this.typeValue !== 'danger') {
      this.startAutoDismiss();
    }
  }

  /**
   * Dismiss the alert with smooth animation
   */
  dismiss() {
    // Announce dismissal to screen readers
    this.announceDismissal();

    // Add dismiss animation class
    this.element.classList.add("dismissing");

    // Remove element after animation completes
    setTimeout(() => {
      this.element.remove();
    }, 300);
  }

  /**
   * Announce dismissal to screen readers
   */
  announceDismissal() {
    const announcement = document.createElement('div');
    announcement.setAttribute('aria-live', 'polite');
    announcement.setAttribute('aria-atomic', 'true');
    announcement.className = 'sr-only';
    announcement.textContent = 'Alert dismissed';

    document.body.appendChild(announcement);

    // Remove announcement after it's been read
    setTimeout(() => {
      document.body.removeChild(announcement);
    }, 1000);
  }

  /**
   * Cleanup event listeners and timers
   */
  cleanup() {
    if (this.autoDismissInterval) {
      clearInterval(this.autoDismissInterval);
    }

    this.element.removeEventListener('keydown', this.handleKeydown.bind(this));
    this.element.removeEventListener('mouseenter', this.pauseAutoDismiss.bind(this));
    this.element.removeEventListener('mouseleave', this.resumeAutoDismiss.bind(this));
    this.element.removeEventListener('focusin', this.pauseAutoDismiss.bind(this));
    this.element.removeEventListener('focusout', this.resumeAutoDismiss.bind(this));
  }
}
