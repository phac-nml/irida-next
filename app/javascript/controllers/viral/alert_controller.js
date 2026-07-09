import { Controller } from "@hotwired/stimulus";
import { announce, createLiveRegion } from "utilities/live_region";

/**
 * 🚨 Alert Controller - The Brain Behind Alert Messages! 🧠
 *
 * This controller handles all the interactive magic for alert components:
 * - 🎯 Dismissing alerts (with keyboard shortcuts!)
 * - ⌨️  Keyboard navigation for accessibility
 * - ⏰ Auto-dismiss countdown with a cool progress bar
 * - ♿ Screen reader announcements
 * - 🎭 Pause/resume auto-dismiss on hover/focus
 *
 * Think of it as the "smart assistant" that makes alerts user-friendly!
 *
 * @example
 * <!-- In your HTML -->
 * <div data-controller="viral--alert"
 *      data-viral--alert-dismissible-value="true"
 *      data-viral--alert-auto-dismiss-value="true">
 *   <button data-action="viral--alert#dismiss">Close</button>
 * </div>
 *
 */
export default class extends Controller {
  /**
   * 🎯 Available Targets - Elements this controller can control
   *
   * @type {string[]}
   */
  static targets = ["progressBar"];

  /**
   * 📊 Configuration Values - Settings that control behavior
   *
   * @type {Object}
   * @property {boolean} dismissible - Can the user close this alert? 🚪
   * @property {boolean} autoDismiss - Should it disappear automatically? ⏰
   * @property {boolean} announceAlert - Should it alert be announced? ⏰
   * @property {string} type - What kind of alert? (danger, info, success, warning) 🏷️
   * @property {string} alertId - Unique identifier for this alert 🆔
   * @property {string} dismissButtonId - ID of the close button 🔘
   *
   */
  static values = {
    dismissible: Boolean,
    autoDismiss: Boolean,
    announceAlert: Boolean,
    type: String,
    alertId: String,
    dismissButtonId: String,
    autoDismissDuration: Number,
    dismissedText: String,
  };

  // 🔒 Private Properties - Internal state (only accessible within this class)
  /**
   * ⏱️ Timer for auto-dismiss countdown
   * @private
   * @type {number|null}
   */
  #autoDismissInterval = null;

  /**
   * 📝 Map to track all event listeners for easy cleanup
   * @private
   * @type {Map<string, Function>}
   */
  #eventHandlers = new Map();

  // 🚀 LIFECYCLE METHODS - Called automatically by Stimulus

  /**
   * 🎬 Called when the controller connects to the DOM
   *
   * This is like the "startup sequence" for our alert controller.
   * We set up all the features and get ready to handle user interactions!
   *
   * @fires console.error - If initialization fails
   */
  connect() {
    try {
      if (this.announceAlertValue) {
        this.#setupAccessibility(); // ♿ Make it screen reader friendly
      }
      this.#setupKeyboardNavigation(); // ⌨️  Handle keyboard shortcuts
      this.#setupAutoDismiss(); // ⏰ Start countdown if needed
    } catch (error) {
      console.error("❌ Failed to initialize alert controller:", error);
    }
  }

  /**
   * 🧹 Called when the controller disconnects from the DOM
   *
   * This is our cleanup crew - we remove all event listeners
   * and clear any timers to prevent memory leaks!
   */
  disconnect() {
    this.#cleanup();
  }

  // 🌟 PUBLIC METHODS - These can be called from HTML or other controllers

  /**
   * 🚪 Dismiss (close) the alert immediately
   *
   * This is the main action users can trigger! It announces the dismissal
   * to screen readers and removes the alert from the page.
   *
   * @example
   * // From HTML
   * <button data-action="viral--alert#dismiss">Close Alert</button>
   *
   * // From JavaScript
   * this.dispatch('dismiss');
   *
   * @fires console.error - If dismissal fails
   * @fires console.warn - If fallback hiding is used
   */
  dismiss() {
    try {
      this.#announceDismissal(); // 📢 Tell screen readers
      this.element.dispatchEvent(
        new CustomEvent("viral--alert:dismissed", { bubbles: true }),
      );
      this.element.remove(); // 🗑️  Remove from DOM
    } catch (error) {
      console.error("❌ Failed to dismiss alert:", error);
      // 🆘 Fallback: try to hide the element instead
      this.element.style.display = "none";
    }
  }

  // 🔧 PRIVATE SETUP METHODS - Internal configuration

  /**
   * ♿ Setup accessibility features for screen readers
   *
   * Makes sure screen readers know about this alert and can
   * announce it properly to users with visual impairments.
   *
   * @private
   */
  #setupAccessibility() {
    const { element } = this;

    // 📢 Tell screen readers this is an important alert
    element.setAttribute("aria-live", "assertive");
    element.setAttribute("aria-atomic", "true");

    // 🎯 Make it focusable if it can be dismissed
    if (this.dismissibleValue) {
      element.setAttribute("tabindex", "-1");
    }
  }

  /**
   * ⌨️  Setup keyboard navigation for accessibility
   *
   * Allows users to interact with the alert using only their keyboard.
   * This is crucial for accessibility and power users!
   *
   * @private
   */
  #setupKeyboardNavigation() {
    const handler = this.#handleKeydown.bind(this);
    this.#eventHandlers.set("keydown", handler);
    this.element.addEventListener("keydown", handler);
  }

  /**
   * ⏰ Setup auto-dismiss if enabled
   *
   * If the alert is configured to auto-dismiss, we start the countdown.
   * Danger alerts never auto-dismiss (they're too important!).
   *
   * @private
   */
  #setupAutoDismiss() {
    const shouldAutoDismiss =
      this.autoDismissValue && this.typeValue !== "danger";

    if (shouldAutoDismiss) {
      this.#setupAutoDismissPause();
      this.#startAutoDismiss();
    }
  }

  // 🎮 EVENT HANDLERS - Respond to user interactions

  /**
   * ⌨️  Handle keyboard events for accessibility
   *
   * Maps keyboard shortcuts to actions:
   * - Escape: Close the alert
   * - Enter/Space: Close the alert (when focused)
   *
   * @private
   * @param {KeyboardEvent} event - The keyboard event
   */
  #handleKeydown = (event) => {
    const { key, target } = event;

    // 🚫 Only handle keys if the alert can be dismissed
    if (!this.dismissibleValue) return;

    // 🎯 Map keyboard keys to actions
    const keyActions = {
      Escape: () => {
        event.preventDefault();
        this.dismiss();
      },
      Enter: () => {
        if (target === this.element) {
          event.preventDefault();
          this.dismiss();
        }
      },
      " ": () => {
        if (target === this.element) {
          event.preventDefault();
          this.dismiss();
        }
      },
    };

    // 🚀 Execute the action for the pressed key
    const action = keyActions[key];
    if (action) action();
  };

  // ⏰ AUTO-DISMISS METHODS - Countdown and progress bar

  /**
   * ⏱️  Start the auto-dismiss countdown with progress bar
   *
   * Creates a 5-second countdown that updates every 50ms for smooth animation.
   * The progress bar shrinks as time runs out, giving users a visual cue!
   *
   * @private
   * @fires console.error - If countdown encounters an error
   */
  #startAutoDismiss() {
    const duration = this.autoDismissDurationValue; // ⏰ 5 seconds total
    const interval = 50; // 🔄 Update every 50ms for smooth animation
    const steps = duration / interval;
    let currentStep = 0;

    // ⏱️  Start the countdown timer
    this.#autoDismissInterval = setInterval(() => {
      try {
        currentStep++;
        const progress = ((steps - currentStep) / steps) * 100;

        // 📊 Update the progress bar if it exists
        if (this.hasProgressBarTarget) {
          this.progressBarTarget.style.width = `${progress}%`;
        }

        // 🚪 Time's up! Dismiss the alert
        if (currentStep >= steps) {
          this.dismiss();
        }
      } catch (error) {
        console.error("❌ Auto-dismiss error:", error);
        this.#clearAutoDismissInterval();
      }
    }, interval);
  }

  /**
   * 🎭 Setup pause/resume for auto-dismiss
   *
   * When users hover over or focus on the alert, we pause the countdown.
   * This gives them time to read the message without it disappearing!
   *
   * @private
   */
  #setupAutoDismissPause() {
    const pauseEvents = ["mouseenter", "focusin"]; // 🖱️  Pause on hover/focus
    const resumeEvents = ["mouseleave", "focusout"]; // ▶️  Resume when leaving

    // 🖱️  Pause countdown when user interacts
    pauseEvents.forEach((eventType) => {
      const handler = this.#pauseAutoDismiss.bind(this);
      this.#eventHandlers.set(eventType, handler);
      this.element.addEventListener(eventType, handler);
    });

    // ▶️  Resume countdown when user stops interacting
    resumeEvents.forEach((eventType) => {
      const handler = this.#resumeAutoDismiss.bind(this);
      this.#eventHandlers.set(eventType, handler);
      this.element.addEventListener(eventType, handler);
    });
  }

  /**
   * ⏸️  Pause the auto-dismiss countdown
   *
   * Called when user hovers over or focuses on the alert.
   * Gives them time to read without the alert disappearing!
   *
   * @private
   */
  #pauseAutoDismiss() {
    this.#clearAutoDismissInterval();
  }

  /**
   * ▶️  Resume the auto-dismiss countdown
   *
   * Called when user stops hovering or focusing on the alert.
   * Only resumes if auto-dismiss is still enabled and it's not a danger alert.
   *
   * @private
   */
  #resumeAutoDismiss() {
    const shouldResume = this.autoDismissValue && this.typeValue !== "danger";

    if (shouldResume) {
      this.#startAutoDismiss();
    }
  }

  /**
   * 🧹 Clear the auto-dismiss interval
   *
   * Stops the countdown timer and cleans up the interval.
   * This prevents memory leaks and stops the countdown.
   *
   * @private
   */
  #clearAutoDismissInterval() {
    if (this.#autoDismissInterval) {
      clearInterval(this.#autoDismissInterval);
      this.#autoDismissInterval = null;
    }
  }

  // ♿ ACCESSIBILITY METHODS - Screen reader support

  /**
   * 📢 Announce dismissal to screen readers
   *
   * Creates a temporary announcement element that screen readers
   * will announce to users, letting them know the alert was closed.
   *
   * @private
   * @fires console.error - If announcement creation fails
   * @fires console.warn - If cleanup fails
   */
  #announceDismissal() {
    try {
      // 📝 Create the announcement element
      const announcement = createLiveRegion({
        id: `alert-announcement-${this.alertIdValue}`,
        politeness: "polite",
        atomic: true,
      });

      announce(this.dismissedTextValue, { element: announcement });

      // 🧹 Clean it up after screen readers have announced it
      // Using 3000ms to ensure all screen readers have time to detect and announce
      setTimeout(() => {
        try {
          announcement.remove();
        } catch (error) {
          console.warn("⚠️  Failed to remove announcement element:", error);
        }
      }, 3000);
    } catch (error) {
      console.error("❌ Failed to announce dismissal:", error);
    }
  }

  // 🧹 CLEANUP METHODS - Prevent memory leaks

  /**
   * 🧹 Main cleanup method
   *
   * Called when the controller disconnects. We clean up all
   * timers and event listeners to prevent memory leaks!
   *
   * @private
   */
  #cleanup() {
    this.#clearAutoDismissInterval(); // ⏱️  Stop countdown
    this.#removeAllEventListeners(); // 🎧 Remove event listeners
  }

  /**
   * 🎧 Remove all event listeners
   *
   * Goes through our event handler map and removes each listener.
   * This prevents memory leaks and ensures clean disconnection.
   *
   * @private
   * @fires console.warn - If event listener removal fails
   */
  #removeAllEventListeners() {
    this.#eventHandlers.forEach((handler, eventType) => {
      try {
        this.element.removeEventListener(eventType, handler);
      } catch (error) {
        console.warn(
          `⚠️  Failed to remove ${eventType} event listener:`,
          error,
        );
      }
    });

    // 🗑️  Clear the map to free memory
    this.#eventHandlers.clear();
  }
}
