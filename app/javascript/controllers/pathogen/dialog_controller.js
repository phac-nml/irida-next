import { Controller } from "@hotwired/stimulus";
import { createFocusTrap } from "focus-trap";
import { announce } from "controllers/pathogen/announcement_utils";

// Persistent dialog state between connect/disconnects for Turbo navigation
const savedDialogStates = new Map();

/**
 * Pathogen Dialog Controller
 *
 * Manages modal dialog behavior including focus trap, scroll shadows,
 * keyboard events, animations, and screen reader announcements.
 *
 * Implements WCAG 2.1 Level AA accessibility standards for modal dialogs:
 * - Focus trap to prevent keyboard navigation outside dialog
 * - ARIA attributes (role="dialog", aria-modal, aria-labelledby, aria-describedby)
 * - Screen reader announcements for open/close events
 * - Hides background content from screen readers when dialog is open
 * - Restores focus to trigger element when dialog closes
 * - Keyboard support (ESC key for dismissible dialogs)
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
 *   - openAnnouncement (String): I18n key for screen reader announcement when dialog opens
 *   - closeAnnouncement (String): I18n key for screen reader announcement when dialog closes
 *
 * @example Basic usage with show button
 * <div data-controller="pathogen--dialog"
 *      data-pathogen--dialog-dismissible-value="true">
 *   <button data-action="click->pathogen--dialog#open">Open Dialog</button>
 * </div>
 *
 * @example Programmatic usage
 * // Get controller instance
 * const controller = this.application.getControllerForElementAndIdentifier(
 *   element, 'pathogen--dialog'
 * );
 *
 * // Open dialog programmatically
 * controller.open();
 *
 * // Update trigger element for focus restoration
 * controller.updateTrigger(buttonElement);
 *
 * // Close dialog
 * controller.close();
 *
 * @example With custom announcements
 * <div data-controller="pathogen--dialog"
 *      data-pathogen--dialog-open-announcement-value="pathogen.dialog_component.announcements.open"
 *      data-pathogen--dialog-close-announcement-value="pathogen.dialog_component.announcements.close">
 * </div>
 *
 * @example Non-dismissible dialog (critical actions)
 * <div data-controller="pathogen--dialog"
 *      data-pathogen--dialog-dismissible-value="false">
 *   <!-- ESC key and backdrop clicks will not close this dialog -->
 * </div>
 *
 * @example Turbo navigation integration
 * The controller automatically handles Turbo navigation:
 * - Saves dialog state (open/closed) during page transitions
 * - Restores focus to trigger element after navigation
 * - Maintains dialog open state across Turbo Drive visits
 * - Uses data-turbo-permanent to preserve dialog during morphing
 *
 * @example Multiple dialogs
 * When multiple dialogs are present:
 * - Each dialog manages its own ARIA hidden state
 * - Focus trap is scoped to the active dialog
 * - Only the topmost dialog receives keyboard events
 *
 * @example Error handling
 * The controller gracefully handles errors:
 * - Focus trap failures: Continues without focus trap (logs error)
 * - Missing targets: Defensive checks prevent crashes
 * - Disconnected elements: Cleanup handles edge cases
 * - Animation timeouts: Properly tracked and cleared
 *
 * @see https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/
 * @see https://www.w3.org/WAI/WCAG21/Understanding/focus-order.html
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
  static values = {
    dismissible: Boolean,
    open: Boolean,
    openAnnouncement: String,
    closeAnnouncement: String,
  };

  // Animation and timing constants
  static ANIMATION_DURATION = 150; // ms
  static SCROLL_THRESHOLD = 1; // pixels

  #focusTrap = null;
  #triggerId = null;
  #animationTimeout = null;
  #scrollUpdateFrame = null; // RAF ID for scroll shadow debouncing
  #hiddenElements = []; // Track elements hidden for ARIA management
  #bodyScrollPosition = 0; // Store body scroll position before locking
  #bodyStyleOverflow = null; // Store original body overflow style
  #bodyStylePosition = null; // Store original body position style
  #bodyStyleTop = null; // Store original body top style
  #bodyStyleWidth = null; // Store original body width style

  /**
   * Initialize controller on connection
   * Sets up focus trap and restores state if needed
   */
  connect() {
    this.#initializeFocusTrap();
    this.#restoreState();
    this.updateScrollShadows();
    this.#setupEventListeners();
    this.element.setAttribute("data-controller-connected", "true");
  }

  /**
   * Cleanup on disconnect
   * Deactivates focus trap and saves state for Turbo navigation
   */
  disconnect() {
    this.#clearAnimationTimeout();
    this.#cancelScrollUpdate();
    this.#deactivateFocusTrap();
    this.#restoreAriaVisibility();
    this.#removeEventListeners();
    this.#saveStateForTurbo();
    this.#cleanupDialogState();
  }

  /**
   * Open the dialog with animation
   * Activates focus trap and prevents page scroll
   *
   * @param {Event} [event] - Optional event (for trigger button reference)
   */
  open(event) {
    this.#storeTriggerElement(event);
    this.#markTurboPermanent();
    this.openValue = true;
    this.#prepareDialogForOpening();
    this.#activateFocusTrap();
    this.animateIn();
    this.#announceDialogOpened();
    requestAnimationFrame(() => this.updateScrollShadows());
  }

  /**
   * Close the dialog with animation
   * Deactivates focus trap and restores focus to trigger
   *
   * Dispatches a cancelable 'before-close' event before closing.
   * Call event.preventDefault() in the event handler to cancel closing.
   */
  close() {
    // Dispatch cancelable before-close event
    const event = new CustomEvent('pathogen-dialog:before-close', {
      cancelable: true,
      bubbles: true,
      detail: { controller: this }
    });

    const shouldClose = this.element.dispatchEvent(event);

    // If event was prevented, don't close
    if (!shouldClose) {
      return;
    }

    this.#clearAnimationTimeout();
    this.animateOut();
    this.#announceDialogClosed();
    this.#scheduleDialogCleanup();
  }

  /**
   * Handle backdrop click
   * Only closes if dismissible is true
   *
   * Prevents closing if click originates from within dialog content
   * (only closes when clicking directly on backdrop)
   *
   * @param {Event} event - Click event
   * @example
   * <!-- Automatically wired via data-action in component template -->
   * <div data-action="click->pathogen--dialog#closeOnBackdrop">
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
   * For non-dismissible dialogs, ESC key is prevented from closing the dialog.
   * This is useful for critical actions that must be explicitly confirmed or cancelled.
   *
   * @param {Event} event - Keyboard event
   * @example
   * <!-- Automatically wired via data-action in component template for non-dismissible dialogs -->
   * <div data-action="keydown.esc->pathogen--dialog#handleEsc">
   */
  handleEsc(event) {
    if (!this.dismissibleValue) {
      event.preventDefault();
    }
  }

  /**
   * Update scroll shadow indicators based on scroll position
   * Shows top shadow when scrolled down, bottom shadow when more content below
   * Debounced using requestAnimationFrame for performance
   */
  updateScrollShadows() {
    // Cancel any pending update
    if (this.#scrollUpdateFrame) {
      cancelAnimationFrame(this.#scrollUpdateFrame);
    }

    // Schedule update on next animation frame
    this.#scrollUpdateFrame = requestAnimationFrame(() => {
      this.#scrollUpdateFrame = null;
      this.#performScrollShadowUpdate();
    });
  }

  /**
   * Perform the actual scroll shadow update
   * @private
   */
  #performScrollShadowUpdate() {
    if (!this.hasBodyTarget) return;

    const { scrollTop, scrollHeight, clientHeight } = this.bodyTarget;

    // Show top shadow if scrolled down from top
    const showTopShadow = scrollTop > this.constructor.SCROLL_THRESHOLD;
    // Show bottom shadow if can scroll further down
    const showBottomShadow =
      scrollTop + clientHeight <
      scrollHeight - this.constructor.SCROLL_THRESHOLD;

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
   *
   * Called during connect() if dialog was not initially open.
   * Restores focus to trigger element if it was saved during previous navigation.
   *
   * @private
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
   * Call this method when opening a dialog programmatically to ensure
   * focus is restored to the correct element when the dialog closes.
   *
   * @param {HTMLElement} button - The new trigger element (must have an id attribute)
   * @example
   * const button = document.getElementById('my-button');
   * controller.updateTrigger(button);
   * controller.open();
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
   * If form submission fails (e.g., validation errors with 422 status),
   * the dialog remains open so users can see and fix the errors.
   *
   * @param {Event} event - Turbo submit-end event
   * @param {boolean} event.detail.success - Whether submission was successful
   * @example
   * <!-- Automatically wired via addEventListener in connect() -->
   * <!-- Form submission with success closes dialog automatically -->
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
      const duration = this.constructor.ANIMATION_DURATION;
      this.dialogTarget.style.transition = `opacity ${duration}ms ease-in-out, transform ${duration}ms ease-in-out`;
      this.dialogTarget.style.opacity = "1";
      this.dialogTarget.style.transform = "scale(1)";
    });
  }

  /**
   * Animate dialog out (fade and scale)
   * Uses GPU-accelerated properties for smooth animation
   */
  animateOut() {
    const duration = this.constructor.ANIMATION_DURATION;
    this.dialogTarget.style.transition = `opacity ${duration}ms ease-in-out, transform ${duration}ms ease-in-out`;
    this.dialogTarget.style.opacity = "0";
    this.dialogTarget.style.transform = "scale(0.95)";
  }

  /**
   * Set aria-hidden on sibling elements to hide page content from screen readers
   * when dialog is open. This is critical for modal dialogs to prevent screen readers
   * from accessing background content.
   *
   * @private
   * @param {boolean} shouldHide - Whether to hide siblings (true) or restore (false)
   */
  #setAriaHiddenOnSiblings(shouldHide) {
    if (shouldHide) {
      // Find all direct children of body (excluding the dialog wrapper)
      const bodyChildren = Array.from(document.body.children);
      this.#hiddenElements = [];

      bodyChildren.forEach((child) => {
        // Skip the dialog wrapper and elements already hidden
        if (
          child === this.element ||
          child.getAttribute("aria-hidden") === "true"
        ) {
          return;
        }

        // Store original state
        const originalAriaHidden = child.getAttribute("aria-hidden");
        this.#hiddenElements.push({
          element: child,
          originalAriaHidden: originalAriaHidden,
        });

        // Hide from screen readers
        child.setAttribute("aria-hidden", "true");
      });
    } else {
      this.#restoreAriaVisibility();
    }
  }

  /**
   * Restore aria-hidden attributes to their original state
   *
   * @private
   */
  #restoreAriaVisibility() {
    this.#hiddenElements.forEach(({ element, originalAriaHidden }) => {
      if (originalAriaHidden === null) {
        element.removeAttribute("aria-hidden");
      } else {
        element.setAttribute("aria-hidden", originalAriaHidden);
      }
    });
    this.#hiddenElements = [];
  }

  /**
   * Lock body scroll to prevent background page scrolling
   * Preserves scroll position and allows dialog body to scroll
   *
   * @private
   */
  #lockBodyScroll() {
    // Store current scroll position
    this.#bodyScrollPosition =
      window.scrollY || document.documentElement.scrollTop;

    // Store original styles
    this.#bodyStyleOverflow = document.body.style.overflow;
    this.#bodyStylePosition = document.body.style.position;
    this.#bodyStyleTop = document.body.style.top;
    this.#bodyStyleWidth = document.body.style.width;

    // Lock scroll by setting position fixed and preserving scroll position
    document.body.style.overflow = "hidden";
    document.body.style.position = "fixed";
    document.body.style.top = `-${this.#bodyScrollPosition}px`;
    document.body.style.width = "100%";

    // Also lock html element to prevent scroll on some browsers
    const html = document.documentElement;
    if (!html.style.overflow) {
      html.style.overflow = "hidden";
    }
  }

  /**
   * Unlock body scroll and restore original scroll position
   *
   * @private
   */
  #unlockBodyScroll() {
    // Restore original styles
    document.body.style.overflow = this.#bodyStyleOverflow || "";
    document.body.style.position = this.#bodyStylePosition || "";
    document.body.style.top = this.#bodyStyleTop || "";
    document.body.style.width = this.#bodyStyleWidth || "";

    // Restore scroll position
    window.scrollTo(0, this.#bodyScrollPosition);

    // Restore html overflow
    document.documentElement.style.overflow = "";

    // Reset stored values
    this.#bodyScrollPosition = 0;
    this.#bodyStyleOverflow = null;
    this.#bodyStylePosition = null;
    this.#bodyStyleTop = null;
    this.#bodyStyleWidth = null;
  }

  // Private helper methods for connect()

  /**
   * Initialize focus trap with error handling
   * @private
   */
  #initializeFocusTrap() {
    try {
      this.#focusTrap = createFocusTrap(this.backdropTarget, {
        onActivate: () => this.backdropTarget.classList.add("focus-trap"),
        onDeactivate: () => this.backdropTarget.classList.remove("focus-trap"),
        clickOutsideDeactivates: false,
        escapeDeactivates: false,
      });
    } catch (error) {
      console.error("[pathogen--dialog] Failed to create focus trap:", error);
      this.#focusTrap = null;
    }
  }

  /**
   * Restore dialog state from Turbo navigation
   * @private
   */
  #restoreState() {
    if (this.openValue) {
      this.open();
    } else {
      this.restoreFocusState();
    }
  }

  /**
   * Setup event listeners for Turbo form submissions
   * @private
   */
  #setupEventListeners() {
    this.element.addEventListener(
      "turbo:submit-end",
      this.handleFormSubmit.bind(this),
    );
  }

  // Private helper methods for disconnect()

  /**
   * Clear pending animation timeout
   * @private
   */
  #clearAnimationTimeout() {
    if (this.#animationTimeout) {
      clearTimeout(this.#animationTimeout);
      this.#animationTimeout = null;
    }
  }

  /**
   * Cancel pending scroll shadow update
   * @private
   */
  #cancelScrollUpdate() {
    if (this.#scrollUpdateFrame) {
      cancelAnimationFrame(this.#scrollUpdateFrame);
      this.#scrollUpdateFrame = null;
    }
  }

  /**
   * Deactivate focus trap with error handling
   * @private
   */
  #deactivateFocusTrap() {
    if (this.#focusTrap) {
      try {
        this.#focusTrap.deactivate();
      } catch (error) {
        console.error(
          "[pathogen--dialog] Error deactivating focus trap:",
          error,
        );
      }
    }
  }

  /**
   * Remove event listeners
   * @private
   */
  #removeEventListeners() {
    this.element.removeEventListener(
      "turbo:submit-end",
      this.handleFormSubmit.bind(this),
    );
  }

  /**
   * Save dialog state for Turbo navigation
   * @private
   */
  #saveStateForTurbo() {
    if (this.openValue) {
      this.close();
      if (this.#triggerId) {
        savedDialogStates.set(this.dialogTarget.id, { refocusTrigger: true });
      }
    }
  }

  /**
   * Cleanup dialog state from savedDialogStates Map
   * Prevents memory leaks by removing stale entries
   * @private
   */
  #cleanupDialogState() {
    // Only cleanup if dialog is closed and not being navigated
    if (!this.openValue && this.dialogTarget && this.dialogTarget.id) {
      const state = savedDialogStates.get(this.dialogTarget.id);
      // Remove entry if refocusTrigger is false (focus has been restored)
      if (state && !state.refocusTrigger) {
        savedDialogStates.delete(this.dialogTarget.id);
      }
    }
  }

  // Private helper methods for open()

  /**
   * Store trigger element ID for focus restoration
   * @private
   */
  #storeTriggerElement(event) {
    if (event && event.currentTarget && event.currentTarget.id) {
      this.#triggerId = event.currentTarget.id;
    }
  }

  /**
   * Mark dialog as turbo-permanent and save state
   * @private
   */
  #markTurboPermanent() {
    this.element.setAttribute("data-turbo-permanent", "");
    if (this.#triggerId) {
      savedDialogStates.set(this.dialogTarget.id, { refocusTrigger: true });
    }
  }

  /**
   * Prepare dialog UI for opening
   * @private
   */
  #prepareDialogForOpening() {
    this.#setAriaHiddenOnSiblings(true);
    this.backdropTarget.classList.remove("hidden");
    this.#lockBodyScroll();
    this.dialogTarget.classList.remove("hidden");
  }

  /**
   * Activate focus trap with error handling
   * @private
   */
  #activateFocusTrap() {
    if (this.#focusTrap) {
      try {
        this.#focusTrap.activate();
      } catch (error) {
        console.error(
          "[pathogen--dialog] Failed to activate focus trap:",
          error,
        );
      }
    }
  }

  /**
   * Announce dialog opened to screen readers
   * @private
   */
  #announceDialogOpened() {
    if (this.hasOpenAnnouncementValue) {
      announce(this.openAnnouncementValue);
    }
  }

  // Private helper methods for close()

  /**
   * Announce dialog closed to screen readers
   * @private
   */
  #announceDialogClosed() {
    if (this.hasCloseAnnouncementValue) {
      announce(this.closeAnnouncementValue);
    }
  }

  /**
   * Schedule dialog cleanup after animation
   * @private
   */
  #scheduleDialogCleanup() {
    this.#animationTimeout = setTimeout(() => {
      this.#animationTimeout = null;
      this.element.removeAttribute("data-turbo-permanent");
      this.openValue = false;
      this.#deactivateFocusTrap();
      this.dialogTarget.classList.add("hidden");
      this.backdropTarget.classList.add("hidden");
      this.#unlockBodyScroll();
      this.#restoreAriaVisibility();
      this.#restoreFocusToTrigger();
    }, this.constructor.ANIMATION_DURATION);
  }

  /**
   * Restore focus to trigger element
   * @private
   */
  #restoreFocusToTrigger() {
    if (this.#triggerId) {
      savedDialogStates.set(this.dialogTarget.id, { refocusTrigger: false });
      const triggerElement = document.getElementById(this.#triggerId);
      if (triggerElement) {
        triggerElement.focus();
      }
    }
  }
}
