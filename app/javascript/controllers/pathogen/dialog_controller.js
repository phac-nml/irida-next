import { Controller } from "@hotwired/stimulus";
import { createFocusTrap } from "focus-trap";

// Persistent dialog state between connect/disconnects for Turbo navigation
const savedDialogStates = new Map();

/**
 * Pathogen Dialog Controller
 * Manages modal dialog behavior including focus trap, scroll shadows,
 * keyboard events, and animations.
 *
 * Targets:
 *   - dialog: The main dialog element
 *   - backdrop: The backdrop overlay container
 *   - body: The scrollable content area
 *   - topShadow: The top scroll shadow indicator
 *   - bottomShadow: The bottom scroll shadow indicator
 *   - closeButton: The close button (for dismissible dialogs)
 *
 * Values:
 *   - dismissible (Boolean): Whether dialog can be dismissed via ESC/backdrop click
 *   - open (Boolean): Current open state of the dialog
 */
export default class extends Controller {
  static targets = [
    "dialog",
    "backdrop",
    "body",
    "topShadow",
    "bottomShadow",
    "closeButton",
  ];
  static values = { dismissible: Boolean, open: Boolean };

  #focusTrap = null;
  #triggerId = null;

  /**
   * Initialize controller on connection
   * Sets up focus trap and restores state if needed
   */
  connect() {
    this.#focusTrap = createFocusTrap(this.backdropTarget, {
      onActivate: () => this.backdropTarget.classList.add("focus-trap"),
      onDeactivate: () => this.backdropTarget.classList.remove("focus-trap"),
      clickOutsideDeactivates: false,
      escapeDeactivates: false,
    });

    // Check if dialog should be open based on saved state
    if (this.openValue) {
      this.open();
    } else {
      this.restoreFocusState();
    }

    // Initialize scroll shadows on connect
    this.updateScrollShadows();

    // Listen for Turbo form submission success to close dialog
    this.element.addEventListener(
      "turbo:submit-end",
      this.handleFormSubmit.bind(this),
    );

    this.element.setAttribute("data-controller-connected", "true");
  }

  /**
   * Cleanup on disconnect
   * Deactivates focus trap and saves state for Turbo navigation
   */
  disconnect() {
    this.#focusTrap.deactivate();
    // Remove Turbo event listener
    this.element.removeEventListener(
      "turbo:submit-end",
      this.handleFormSubmit.bind(this),
    );
    if (this.openValue) {
      this.close();
      if (this.#triggerId) {
        // Re-add refocusTrigger on save for Turbo page loads
        savedDialogStates.set(this.dialogTarget.id, { refocusTrigger: true });
      }
    }
  }

  /**
   * Open the dialog with animation
   * Activates focus trap and prevents page scroll
   *
   * @param {Event} event - Optional event (for trigger button reference)
   */
  open(event) {
    // Store trigger element ID for focus restoration
    if (event && event.currentTarget && event.currentTarget.id) {
      this.#triggerId = event.currentTarget.id;
    }

    // Mark as turbo-permanent during open state
    this.element.setAttribute("data-turbo-permanent", "");

    // Save state for Turbo navigation
    if (this.#triggerId) {
      savedDialogStates.set(this.dialogTarget.id, { refocusTrigger: true });
    }

    // Set open state
    this.openValue = true;

    // Show backdrop and dialog
    this.backdropTarget.classList.remove("hidden");

    // Prevent page scroll
    document.body.style.overflow = "hidden";

    // Show dialog (we're using div role="dialog" not native <dialog>)
    this.dialogTarget.classList.remove("hidden");

    // Activate focus trap
    this.#focusTrap.activate();

    // Animate in
    this.animateIn();

    // Update scroll shadows after rendering
    requestAnimationFrame(() => {
      this.updateScrollShadows();
    });
  }

  /**
   * Close the dialog with animation
   * Deactivates focus trap and restores focus to trigger
   */
  close() {
    // Animate out
    this.animateOut();

    // Wait for animation to complete
    setTimeout(() => {
      this.element.removeAttribute("data-turbo-permanent");
      this.openValue = false;

      // Deactivate focus trap
      this.#focusTrap.deactivate();

      // Hide dialog (we're using div role="dialog" not native <dialog>)
      this.dialogTarget.classList.add("hidden");

      // Hide backdrop
      this.backdropTarget.classList.add("hidden");

      // Restore page scroll
      document.body.style.overflow = "";

      // Restore focus to trigger element by ID
      if (this.#triggerId) {
        savedDialogStates.set(this.dialogTarget.id, { refocusTrigger: false });
        const triggerElement = document.getElementById(this.#triggerId);
        if (triggerElement) {
          triggerElement.focus();
        }
      }
    }, 150); // Match animation duration
  }

  /**
   * Handle backdrop click
   * Only closes if dismissible is true
   *
   * @param {Event} event - Click event
   */
  closeOnBackdrop(event) {
    // Only close if clicking directly on backdrop (not dialog content)
    if (event.target === event.currentTarget && this.dismissibleValue) {
      this.close();
    }
  }

  /**
   * Handle ESC key for non-dismissible dialogs
   * Prevents default ESC behavior
   *
   * @param {Event} event - Keyboard event
   */
  handleEsc(event) {
    if (!this.dismissibleValue) {
      event.preventDefault();
    }
  }

  /**
   * Update scroll shadow indicators based on scroll position
   * Shows top shadow when scrolled down, bottom shadow when more content below
   */
  updateScrollShadows() {
    if (!this.hasBodyTarget) return;

    const { scrollTop, scrollHeight, clientHeight } = this.bodyTarget;

    // Show top shadow if scrolled down from top
    const showTopShadow = scrollTop > 0;
    // Show bottom shadow if can scroll further down
    const showBottomShadow = scrollTop + clientHeight < scrollHeight - 1;

    // Update shadow visibility
    if (this.hasTopShadowTarget) {
      this.topShadowTarget.style.opacity = showTopShadow ? "1" : "0";
    }

    if (this.hasBottomShadowTarget) {
      this.bottomShadowTarget.style.opacity = showBottomShadow ? "1" : "0";
    }
  }

  /**
   * Restore focus state after Turbo navigation
   */
  restoreFocusState() {
    const state = savedDialogStates.get(this.dialogTarget.id);
    if (state && state.refocusTrigger && this.#triggerId) {
      const triggerElement = document.getElementById(this.#triggerId);
      if (triggerElement) {
        triggerElement.focus();
      }
      savedDialogStates.set(this.dialogTarget.id, { refocusTrigger: false });
    }
  }

  /**
   * Update trigger element ID
   * Used for programmatic dialog opening
   *
   * @param {HTMLElement} button - The new trigger element
   */
  updateTrigger(button) {
    if (button && button.id) {
      this.#triggerId = button.id;
    }
  }

  /**
   * Handle Turbo form submission completion
   * Only closes dialog if submission was successful (no validation errors)
   *
   * @param {Event} event - Turbo submit-end event
   */
  handleFormSubmit(event) {
    // Check if submission was successful (2xx status code)
    // If there are validation errors, the server responds with 422 Unprocessable Entity
    // and re-renders the form with errors, so the dialog should stay open
    if (event.detail.success) {
      this.close();
    }
  }

  /**
   * Animate dialog in (fade and scale)
   * Uses GPU-accelerated properties for smooth animation
   */
  animateIn() {
    // Initial state
    this.dialogTarget.style.opacity = "0";
    this.dialogTarget.style.transform = "scale(0.95)";

    // Animate to visible state
    requestAnimationFrame(() => {
      this.dialogTarget.style.transition =
        "opacity 150ms ease-in-out, transform 150ms ease-in-out";
      this.dialogTarget.style.opacity = "1";
      this.dialogTarget.style.transform = "scale(1)";
    });
  }

  /**
   * Animate dialog out (fade and scale)
   * Uses GPU-accelerated properties for smooth animation
   */
  animateOut() {
    this.dialogTarget.style.transition =
      "opacity 150ms ease-in-out, transform 150ms ease-in-out";
    this.dialogTarget.style.opacity = "0";
    this.dialogTarget.style.transform = "scale(0.95)";
  }
}
