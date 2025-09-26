import { Controller } from "@hotwired/stimulus";

/**
 * RefreshController - Handles sample table refresh notifications with accessibility features
 *
 * This Stimulus controller manages refresh notifications that appear when sample table data
 * is updated via Turbo streams. It provides comprehensive accessibility support including
 * screen reader announcements, keyboard navigation, focus management, and respect for
 * user preferences like reduced motion.
 *
 * @example
 * <!-- Basic usage -->
 * <div data-controller="refresh">
 *   <div data-refresh-target="source" data-turbo-stream-from="samples"></div>
 *   <div data-refresh-target="notice" class="hidden">
 *     <p data-refresh-message>New samples are available</p>
 *     <button data-refresh-target="dismissButton">Dismiss</button>
 *   </div>
 * </div>
 *
 * @example
 * <!-- With auto-dismiss and progress bar -->
 * <div data-controller="refresh" data-refresh-auto-dismiss-value="10000">
 *   <div data-refresh-target="progressContainer" class="hidden">
 *     <div data-refresh-target="progressBar"></div>
 *     <span data-refresh-target="countdown"></span>
 *   </div>
 * </div>
 */
export default class extends Controller {
  // ============================================================================
  // STIMULUS CONFIGURATION
  // ============================================================================

  static targets = [
    "notice",              // Main notification container
    "source",              // Turbo stream source element
    "progressContainer",   // Container for auto-dismiss progress bar
    "progressBar",         // Visual progress bar element
    "countdown",           // Countdown timer text
    "liveRegion",          // ARIA live region for screen reader announcements
    "dismissButton"        // Button to manually dismiss notification
  ];

  static values = {
    autoDismiss: { type: Number, default: 0 },    // Auto-dismiss delay in milliseconds (0 = disabled)
    debounce: { type: Number, default: 500 }      // Debounce delay for rapid refresh events
  };

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  /**
   * Initialize controller state and bind event handlers
   * Sets up debounced methods, timers, and accessibility preferences
   */
  initialize() {
    // Bound event handlers to maintain proper 'this' context
    this.boundMessageHandler = this.messageHandler.bind(this);
    this.boundKeydownHandler = this.handleKeydown.bind(this);

    // Create debounced version of showNotice to handle rapid refresh events
    this.showNoticeDebounced = this.debounce(this.showNotice.bind(this), this.debounceValue);

    // Timer management
    this.autoDismissTimer = null;
    this.progressTimer = null;

    // State tracking
    this.refreshCount = 0;
    this.previouslyFocusedElement = null;

    // Respect user's motion preferences for animations
    this.respectsReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  /**
   * Connect keyboard event listeners when controller is attached to DOM
   */
  connect() {
    document.addEventListener('keydown', this.boundKeydownHandler);
  }

  /**
   * Clean up timers and event listeners when controller is detached from DOM
   */
  disconnect() {
    this.clearTimers();
    if (this.boundKeydownHandler) {
      document.removeEventListener('keydown', this.boundKeydownHandler);
    }
  }

  // ============================================================================
  // TURBO STREAM SOURCE MANAGEMENT
  // ============================================================================

  /**
   * Set up message listener when source target is connected to DOM
   * @param {HTMLElement} element - The source element that receives Turbo stream messages
   */
  sourceTargetConnected(element) {
    element.addEventListener("message", this.boundMessageHandler, true);
  }

  /**
   * Remove message listener when source target is disconnected from DOM
   * @param {HTMLElement} element - The source element being disconnected
   */
  sourceTargetDisconnected(element) {
    element.removeEventListener("message", this.boundMessageHandler, true);
  }

  /**
   * Handle incoming Turbo stream messages and trigger refresh notifications
   * Filters for refresh action messages and increments refresh counter
   * @param {MessageEvent} event - Message event from Turbo stream source
   */
  messageHandler(event) {
    // Only process refresh action messages from Turbo streams
    if (
      typeof event.data === "string" &&
      event.data === '<turbo-stream action="refresh"></turbo-stream>'
    ) {
      this.refreshCount++;
      this.showNoticeDebounced();
      event.stopImmediatePropagation();
    }
  }

  // ============================================================================
  // NOTIFICATION DISPLAY MANAGEMENT
  // ============================================================================

  /**
   * Display the refresh notification with full accessibility support
   * Manages ARIA attributes, focus handling, and auto-dismiss scheduling
   */
  showNotice() {
    // Store current focus for potential restoration after dismissal
    this.previouslyFocusedElement = document.activeElement;

    // Make notification visible
    this.noticeTarget.classList.remove("hidden");

    // Configure ARIA attributes for proper screen reader behavior
    this.noticeTarget.setAttribute("aria-live", "polite");
    this.noticeTarget.setAttribute("aria-atomic", "true");
    this.noticeTarget.setAttribute("tabindex", "-1");

    // Update message text if multiple refreshes have occurred
    if (this.refreshCount > 1) {
      this.updateNoticeText();
    }

    // Announce notification appearance to screen readers
    this.announceToScreenReader(
      "Samples table refresh notification displayed. Use Tab to navigate to refresh or dismiss buttons."
    );

    // Reset any existing timers before starting new ones
    this.clearTimers();

    // Start auto-dismiss sequence if enabled
    if (this.autoDismissValue > 0) {
      this.scheduleAutoDismiss();
    }
  }

  /**
   * Hide the refresh notification and reset controller state
   * Includes proper focus restoration and cleanup of ARIA attributes
   */
  hideNotice() {
    // Hide notification and reset state
    this.noticeTarget.classList.add("hidden");
    this.refreshCount = 0;
    this.clearTimers();
    this.hideProgressBar();

    // Clean up ARIA attributes
    this.noticeTarget.removeAttribute("aria-live");
    this.noticeTarget.removeAttribute("aria-atomic");
    this.noticeTarget.removeAttribute("tabindex");

    // Announce dismissal to screen readers
    this.announceToScreenReader("Refresh notification dismissed.");

    // Restore focus if user was interacting with dismiss button
    this.restorePreviousFocus();
  }

  /**
   * Update notification text to show multiple refresh count
   * Preserves original message while appending update count
   */
  updateNoticeText() {
    const messageElement = this.noticeTarget.querySelector('[data-refresh-message]');
    if (messageElement) {
      // Store or retrieve original message text
      const originalMessage = messageElement.dataset.refreshMessage || messageElement.textContent;
      const updatedMessage = `${originalMessage} (${this.refreshCount} updates)`;

      // Update display text and store original for future reference
      messageElement.textContent = updatedMessage;
      messageElement.dataset.refreshMessage = originalMessage;

      // Announce the update count change to screen readers
      this.announceToScreenReader(`Refresh notification updated. ${this.refreshCount} updates available.`);
    }
  }

  // ============================================================================
  // AUTO-DISMISS AND PROGRESS BAR MANAGEMENT
  // ============================================================================

  /**
   * Schedule automatic dismissal of the notification
   * Respects user interaction state and delays dismissal when user is actively engaging
   */
  scheduleAutoDismiss() {
    // Determine if user is currently interacting with the page
    const isUserInteracting = this.isUserCurrentlyInteracting();

    if (isUserInteracting) {
      // Delay auto-dismiss while user is focused on interactive elements
      this.hideProgressBar();
      this.autoDismissTimer = setTimeout(() => {
        this.scheduleAutoDismiss(); // Recheck user interaction state
      }, 2000);
    } else {
      // Start normal auto-dismiss sequence with progress indication
      this.startProgressBar();
      this.autoDismissTimer = setTimeout(() => {
        this.hideNotice();
      }, this.autoDismissValue);
    }
  }

  /**
   * Initialize and display the auto-dismiss progress bar
   * Sets up ARIA attributes and starts countdown timer
   */
  startProgressBar() {
    if (this.hasProgressContainerTarget) {
      // Make progress container visible
      this.progressContainerTarget.classList.remove("hidden");

      // Configure progress bar with full accessibility support
      if (this.hasProgressBarTarget) {
        this.progressBarTarget.style.width = "100%";
        this.progressBarTarget.setAttribute("aria-valuenow", "100");
        this.progressBarTarget.setAttribute("aria-valuemin", "0");
        this.progressBarTarget.setAttribute("aria-valuemax", "100");
        this.progressBarTarget.setAttribute("aria-label", "Auto-dismiss countdown progress");
      }

      // Start visual countdown timer
      this.startCountdown();

      // Announce progress bar activation
      this.announceToScreenReader(
        "Auto-dismiss countdown started. Alert will dismiss automatically unless you interact with it."
      );
    }
  }

  /**
   * Start the visual countdown timer with progress bar animation
   * Respects reduced motion preferences and provides periodic screen reader announcements
   */
  startCountdown() {
    if (!this.hasCountdownTarget) return;

    const totalTime = this.autoDismissValue;
    let remainingTime = totalTime;
    let lastAnnouncedSecond = Math.ceil(remainingTime / 1000);

    // Adjust update frequency based on user's motion preferences
    const updateInterval = this.respectsReducedMotion ? 1000 : 100;

    this.progressTimer = setInterval(() => {
      remainingTime -= updateInterval;

      // Stop countdown when time expires
      if (remainingTime <= 0) {
        this.clearProgressTimer();
        return;
      }

      // Update countdown display
      const seconds = Math.ceil(remainingTime / 1000);
      this.countdownTarget.textContent = `${seconds}s`;

      // Update progress bar visual and ARIA values
      this.updateProgressBarVisual(remainingTime, totalTime);

      // Announce countdown at key intervals for screen reader users
      this.announceCountdownMilestones(seconds, lastAnnouncedSecond);
      lastAnnouncedSecond = seconds;
    }, updateInterval);
  }

  /**
   * Update progress bar visual appearance and ARIA attributes
   * @param {number} remainingTime - Time remaining in milliseconds
   * @param {number} totalTime - Total countdown time in milliseconds
   */
  updateProgressBarVisual(remainingTime, totalTime) {
    if (this.hasProgressBarTarget) {
      const percentage = (remainingTime / totalTime) * 100;
      this.progressBarTarget.style.width = `${percentage}%`;
      this.progressBarTarget.setAttribute("aria-valuenow", Math.round(percentage));

      // Disable transitions for users who prefer reduced motion
      if (this.respectsReducedMotion) {
        this.progressBarTarget.style.transition = "none";
      }
    }
  }

  /**
   * Announce countdown milestones to screen reader users
   * @param {number} seconds - Current seconds remaining
   * @param {number} lastAnnouncedSecond - Last announced second to avoid repetition
   */
  announceCountdownMilestones(seconds, lastAnnouncedSecond) {
    const milestones = [10, 5, 3, 2, 1];
    if (milestones.includes(seconds) && seconds !== lastAnnouncedSecond) {
      const pluralSuffix = seconds !== 1 ? 's' : '';
      this.announceToScreenReader(`${seconds} second${pluralSuffix} remaining until auto-dismiss.`);
    }
  }

  /**
   * Hide progress bar and clean up its ARIA attributes
   */
  hideProgressBar() {
    if (this.hasProgressContainerTarget) {
      this.progressContainerTarget.classList.add("hidden");

      // Reset ARIA attributes on progress bar
      if (this.hasProgressBarTarget) {
        this.progressBarTarget.removeAttribute("aria-valuenow");
        this.progressBarTarget.removeAttribute("aria-valuemin");
        this.progressBarTarget.removeAttribute("aria-valuemax");
        this.progressBarTarget.removeAttribute("aria-label");
      }
    }
  }

  // ============================================================================
  // KEYBOARD EVENT HANDLING
  // ============================================================================

  /**
   * Handle keyboard events for notification interaction
   * Currently supports Escape key to dismiss notifications
   * @param {KeyboardEvent} event - Keyboard event
   */
  handleKeydown(event) {
    // Handle Escape key to dismiss active notifications
    if (event.key === 'Escape' && !this.noticeTarget.classList.contains('hidden')) {
      event.preventDefault();
      this.hideNotice();
    }
  }

  // ============================================================================
  // ACCESSIBILITY AND FOCUS MANAGEMENT
  // ============================================================================

  /**
   * Announce messages to screen readers via ARIA live region
   * Uses a brief delay to ensure reliable announcement delivery
   * @param {string} message - Message to announce to screen readers
   */
  announceToScreenReader(message) {
    if (this.hasLiveRegionTarget) {
      // Clear existing content first to ensure new message is announced
      this.liveRegionTarget.textContent = '';

      // Brief delay ensures screen readers detect the content change
      setTimeout(() => {
        this.liveRegionTarget.textContent = message;
      }, 100);
    }
  }

  /**
   * Restore focus to previously focused element when appropriate
   * Only restores focus if user was interacting with the dismiss button
   */
  restorePreviousFocus() {
    const shouldRestoreFocus =
      this.previouslyFocusedElement &&
      this.hasDismissButtonTarget &&
      document.activeElement === this.dismissButtonTarget &&
      this.previouslyFocusedElement !== document.body;

    if (shouldRestoreFocus) {
      this.previouslyFocusedElement.focus();
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /**
   * Check if user is currently interacting with page elements
   * Used to determine whether to delay auto-dismiss functionality
   * @returns {boolean} True if user is focused on interactive elements
   */
  isUserCurrentlyInteracting() {
    const activeElement = document.activeElement;

    return activeElement && (
      activeElement.tagName === 'INPUT' ||
      activeElement.tagName === 'TEXTAREA' ||
      activeElement.tagName === 'SELECT' ||
      activeElement.tagName === 'BUTTON' ||
      activeElement.isContentEditable ||
      activeElement.closest('[contenteditable="true"]')
    );
  }

  /**
   * Clear all active timers
   */
  clearTimers() {
    if (this.autoDismissTimer) {
      clearTimeout(this.autoDismissTimer);
      this.autoDismissTimer = null;
    }
    this.clearProgressTimer();
  }

  /**
   * Clear progress timer specifically
   */
  clearProgressTimer() {
    if (this.progressTimer) {
      clearInterval(this.progressTimer);
      this.progressTimer = null;
    }
  }

  /**
   * Create a debounced version of a function to prevent excessive calls
   * @param {Function} func - Function to debounce
   * @param {number} wait - Debounce delay in milliseconds
   * @returns {Function} Debounced function
   */
  debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }
}
