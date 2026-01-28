import { Controller } from "@hotwired/stimulus";

/**
 * Module-level shared event handlers for performance.
 * Only one set of global listeners for all tooltip instances.
 * Uses a class to support private methods (ES2022).
 */
class TooltipRegistry {
  controllers = new Set();
  initialized = false;
  resizeRAF = null;

  register(controller) {
    this.controllers.add(controller);
    if (!this.initialized) {
      this.#setupGlobalListeners();
      this.initialized = true;
    }
  }

  unregister(controller) {
    this.controllers.delete(controller);
    if (this.controllers.size === 0 && this.initialized) {
      this.#teardownGlobalListeners();
      this.initialized = false;
    }
  }

  #setupGlobalListeners() {
    this.handleKeydown = (event) => {
      if (event.key === "Escape") {
        this.controllers.forEach((controller) =>
          controller.handleEscape(event),
        );
      }
    };

    this.handleTouchOutside = (event) => {
      this.controllers.forEach((controller) =>
        controller.handleTouchOutside(event),
      );
    };

    this.handleResize = () => {
      // Debounce resize with RAF
      if (this.resizeRAF) {
        cancelAnimationFrame(this.resizeRAF);
      }
      this.resizeRAF = requestAnimationFrame(() => {
        this.controllers.forEach((controller) => controller.handleResize());
        this.resizeRAF = null;
      });
    };

    document.addEventListener("keydown", this.handleKeydown);
    document.addEventListener("touchstart", this.handleTouchOutside);
    window.addEventListener("resize", this.handleResize);
  }

  #teardownGlobalListeners() {
    document.removeEventListener("keydown", this.handleKeydown);
    document.removeEventListener("touchstart", this.handleTouchOutside);
    window.removeEventListener("resize", this.handleResize);
    if (this.resizeRAF) {
      cancelAnimationFrame(this.resizeRAF);
      this.resizeRAF = null;
    }
  }
}

const tooltipRegistry = new TooltipRegistry();

/**
 * Pathogen::Tooltip Stimulus Controller
 *
 * Implements tooltip positioning using JavaScript for broad browser compatibility.
 * Calculates optimal position using getBoundingClientRect() with viewport boundary
 * detection, automatic placement flipping, and position clamping.
 *
 * ## Positioning Strategy
 * - Calculates position based on trigger element's bounding rect
 * - Detects viewport boundaries and flips placement if needed (top ↔ bottom, left ↔ right)
 * - Clamps position to viewport bounds with configurable padding to prevent overflow
 * - Applies position via inline top/left styles on tooltip element (position: fixed)
 *
 * ## Accessibility
 * Follows W3C ARIA Authoring Practices Guide (APG) tooltip pattern:
 * - Tooltip remains open when cursor is over trigger OR tooltip
 * - Dismisses on Escape key press
 * - Dismisses on focus loss (blur) when triggered by focus
 * - Dismisses on touch outside (mobile support)
 * - Requires aria-describedby connection from trigger to tooltip
 * - Validates trigger is keyboard-accessible
 * - Respects prefers-reduced-motion for animations
 * - Prevents multiple simultaneous tooltips
 *
 * @example
 * <div data-controller="pathogen--tooltip"
 *      data-pathogen--tooltip-spacing-value="8"
 *      data-pathogen--tooltip-viewport-padding-value="8">
 *   <a data-pathogen--tooltip-target="trigger"
 *      aria-describedby="tooltip-id">
 *     Hover or focus me
 *   </a>
 *   <div id="tooltip-id" data-pathogen--tooltip-target="tooltip" role="tooltip">
 *     Tooltip content
 *   </div>
 * </div>
 */
export default class extends Controller {
  static targets = ["trigger", "tooltip"];
  static values = {
    spacing: { type: Number, default: 8 },
    viewportPadding: { type: Number, default: 8 },
    touchDismissDelay: { type: Number, default: 3000 },
  };

  connect() {
    this.element.setAttribute("data-controller-connected", "true");

    // Store touch dismiss timeout for cleanup
    this.touchDismissTimeout = null;
    this.touchPrimed = false;
    this.touchStarted = false;
    this.escapeDismissed = false;

    // Check for reduced motion preference
    this.prefersReducedMotion = window.matchMedia(
      "(prefers-reduced-motion: reduce)",
    ).matches;

    // Cache viewport dimensions for performance
    this.viewportCache = this.#getViewportDimensions();

    // Register with shared event handler registry (single set of global listeners)
    tooltipRegistry.register(this);
  }

  disconnect() {
    // Unregister from shared event handler registry
    tooltipRegistry.unregister(this);

    // Clean up any pending touch dismiss timeout
    if (this.touchDismissTimeout) {
      clearTimeout(this.touchDismissTimeout);
      this.touchDismissTimeout = null;
    }
  }

  triggerTargetConnected(element) {
    // Validate W3C ARIA APG requirement: trigger must have aria-describedby
    // pointing to the tooltip element
    this.#validateAriaDescribedBy(element);

    // Validate trigger is keyboard-accessible
    this.#validateKeyboardAccessibility(element);

    // Add data-action attributes to trigger for Stimulus event handling
    const actions = [
      "mouseenter->pathogen--tooltip#show",
      "mouseleave->pathogen--tooltip#hide",
      "focusin->pathogen--tooltip#show",
      "focusout->pathogen--tooltip#hide",
      "touchstart->pathogen--tooltip#handleTouch",
      "click->pathogen--tooltip#handleClick",
    ];

    this.#addEventActions(element, actions);
  }

  tooltipTargetConnected(element) {
    // Add mouse event handlers to tooltip itself to keep it open when cursor
    // moves from trigger to tooltip (W3C ARIA APG compliance)
    const actions = [
      "mouseenter->pathogen--tooltip#show",
      "mouseleave->pathogen--tooltip#hide",
    ];

    this.#addEventActions(element, actions);
  }

  /**
   * Shows the tooltip with fade-in and scale animation.
   *
   * IMPORTANT: Animation Timing
   * - Duration: 200ms (duration-200 CSS class in tooltip.html.erb)
   * - Easing: ease-out
   * - Properties: opacity (fade), scale (zoom)
   * - Tests must wait 200ms + buffer before asserting visible state
   * - Recommended Capybara wait: `wait: 0.3` (300ms for reliability)
   *
   * Respects prefers-reduced-motion and hides other visible tooltips.
   */
  show() {
    if (!this.hasTooltipTarget) return;

    // Don't show if just dismissed by Escape (prevents re-show when focus returns)
    if (this.escapeDismissed) return;

    // Hide any other visible tooltips to prevent multiple simultaneous tooltips
    this.#hideOtherTooltips();

    // Update aria-hidden for screen readers
    this.tooltipTarget.setAttribute("aria-hidden", "false");

    if (this.prefersReducedMotion) {
      // Skip scale animation for users who prefer reduced motion
      this.tooltipTarget.classList.remove("invisible", "opacity-0");
      this.tooltipTarget.classList.add("visible", "opacity-100");
    } else {
      // Temporarily make tooltip visible but transparent for accurate measurement
      // This ensures the browser calculates proper dimensions for inline-block elements
      this.tooltipTarget.classList.remove("scale-90", "invisible");
      this.tooltipTarget.classList.add("scale-100", "visible");

      // Now reveal tooltip with fade-in animation (remove opacity-0)
      this.tooltipTarget.classList.remove("opacity-0");
      this.tooltipTarget.classList.add("opacity-100");
    }

    // Position tooltip using JavaScript (tooltip is visible but transparent/animating)
    this.positionTooltip();
  }

  /**
   * Hides the tooltip with fade-out and scale animation.
   *
   * IMPORTANT: Animation Timing
   * - Duration: 200ms (duration-200 CSS class in tooltip.html.erb)
   * - Hidden tooltips remain in DOM with 'invisible' + 'opacity-0' classes
   * - Tests must wait 200ms + buffer before asserting hidden state
   * - Use `visible: :all` in Capybara selectors to find hidden tooltips
   * - Example: `assert_selector 'div[role="tooltip"].invisible', visible: :all, wait: 0.3`
   *
   * Respects prefers-reduced-motion.
   */
  hide() {
    if (!this.hasTooltipTarget) return;

    // Clear any pending touch dismiss timeout
    if (this.touchDismissTimeout) {
      clearTimeout(this.touchDismissTimeout);
      this.touchDismissTimeout = null;
    }
    this.touchPrimed = false;

    // Update aria-hidden for screen readers
    this.tooltipTarget.setAttribute("aria-hidden", "true");

    if (this.prefersReducedMotion) {
      // Skip scale animation for users who prefer reduced motion
      this.tooltipTarget.classList.remove("visible", "opacity-100");
      this.tooltipTarget.classList.add("invisible", "opacity-0");
    } else {
      // Remove visible state classes and add hidden state classes with animation
      this.tooltipTarget.classList.remove(
        "opacity-100",
        "scale-100",
        "visible",
      );
      this.tooltipTarget.classList.add("opacity-0", "scale-90", "invisible");
    }
  }

  /**
   * Handles Escape key press to dismiss tooltip.
   * Called by the shared tooltipRegistry handler (key already filtered).
   * @param {KeyboardEvent} event - The keyboard event
   */
  handleEscape(event) {
    if (!this.hasTooltipTarget) return;

    // Check if tooltip is currently visible
    if (this.#isTooltipVisible()) {
      // Set flag to prevent immediate re-show when focus returns to trigger
      this.escapeDismissed = true;
      this.hide();
      // Return focus to trigger element if it exists
      if (this.hasTriggerTarget) {
        this.triggerTarget.focus();
      }
      // Clear the flag after a brief delay to allow the focusin event to be ignored
      setTimeout(() => {
        this.escapeDismissed = false;
      }, 100);
    }
  }

  /**
   * Handles touch events on trigger element for mobile support.
   * Shows tooltip on first tap, allows navigation on second tap.
   * Does not prevent default to allow scrolling - uses click handler for navigation prevention.
   * @param {TouchEvent} event - The touch event
   */
  handleTouch(event) {
    if (!this.hasTooltipTarget || !this.hasTriggerTarget) return;

    // Mark that a touch interaction started (used by click handler)
    this.touchStarted = true;
  }

  /**
   * Handles click events on trigger element for touch-based navigation control.
   * On touch devices, first tap shows tooltip and prevents navigation.
   * Second tap allows navigation.
   * @param {MouseEvent} event - The click event
   */
  handleClick(event) {
    if (!this.hasTooltipTarget || !this.hasTriggerTarget) return;

    // Only handle clicks that originated from touch (not mouse clicks)
    if (!this.touchStarted) return;
    this.touchStarted = false;

    const tooltipVisible = this.#isTooltipVisible();

    if (tooltipVisible && this.touchPrimed) {
      // Second tap: allow navigation and hide tooltip
      this.touchPrimed = false;
      this.hide();
      // Do not prevent default so click event can proceed
    } else {
      // First tap: show tooltip and prevent navigation
      this.touchPrimed = true;
      event.preventDefault();
      this.show();
      this.#startTouchDismissTimer();
    }
  }

  /**
   * Handles touch outside tooltip or trigger to dismiss on mobile.
   * @param {TouchEvent} event - The touch event
   */
  handleTouchOutside(event) {
    if (!this.hasTooltipTarget || !this.hasTriggerTarget) return;

    // Check if tooltip is currently visible
    const isVisible = this.#isTooltipVisible();

    if (!isVisible) return;

    // Check if touch is outside both tooltip and trigger
    const touchedElement = event.target;
    const isTouchOutside =
      !this.tooltipTarget.contains(touchedElement) &&
      !this.triggerTarget.contains(touchedElement) &&
      !this.element.contains(touchedElement);

    if (isTouchOutside) {
      this.hide();
    }
  }

  /**
   * Position tooltip using JavaScript with viewport boundary detection.
   *
   * This method calculates the optimal position for the tooltip based on:
   * 1. Preferred placement (top, bottom, left, right) from data-placement attribute
   * 2. Viewport boundaries - flips placement if tooltip would overflow viewport edge
   * 3. Position clamping - ensures tooltip stays within viewport with configurable padding
   *
   * Uses getBoundingClientRect() for precise element positioning calculations.
   * Applies position via inline top and left styles (tooltip has position: fixed).
   * Uses cached viewport dimensions for performance (updated on resize).
   */
  positionTooltip() {
    if (!this.hasTriggerTarget || !this.hasTooltipTarget) return;

    try {
      const preferredPlacement = this.tooltipTarget.dataset.placement || "top";
      const spacing = this.spacingValue;
      const viewportPadding = this.viewportPaddingValue;
      const triggerRect = this.triggerTarget.getBoundingClientRect();
      const tooltipRect = this.tooltipTarget.getBoundingClientRect();

      // Validate dimensions to prevent invalid calculations
      if (!this.#isValidRect(triggerRect) || !this.#isValidRect(tooltipRect)) {
        // If dimensions are invalid, fall back to error handler logic
        throw new Error("Invalid tooltip or trigger dimensions");
      }

      // Determine best placement (prefer original, flip if needed)
      let placement = preferredPlacement;
      if (
        !this.#fitsInViewport(
          triggerRect,
          tooltipRect,
          preferredPlacement,
          spacing,
          viewportPadding,
        )
      ) {
        const opposite = this.#getOppositePlacement(preferredPlacement);
        if (
          opposite &&
          this.#fitsInViewport(
            triggerRect,
            tooltipRect,
            opposite,
            spacing,
            viewportPadding,
          )
        ) {
          placement = opposite;
        }
        // If neither fits, stick with preferred and clamp to viewport
      }

      const { top, left } = this.#calculatePosition(
        triggerRect,
        tooltipRect,
        placement,
        spacing,
      );

      const { top: clampedTop, left: clampedLeft } = this.#clampToViewport(
        top,
        left,
        tooltipRect,
        viewportPadding,
      );

      this.#applyPosition(clampedTop, clampedLeft);
    } catch (error) {
      // Fallback to default top positioning with viewport boundary clamping
      if (this.hasTooltipTarget && this.hasTriggerTarget) {
        const triggerRect = this.triggerTarget.getBoundingClientRect();
        const tooltipRect = this.tooltipTarget.getBoundingClientRect();
        if (this.#isValidRect(triggerRect) && this.#isValidRect(tooltipRect)) {
          this.#fallbackPosition(triggerRect, tooltipRect);
        }
      }
    }
  }

  /**
   * Adds event action attributes to an element.
   * Merges new actions with existing data-action attribute.
   * @param {HTMLElement} element - The element to add actions to
   * @param {string[]} actions - Array of action strings to add
   * @private
   */
  #addEventActions(element, actions) {
    const actionString = actions.join(" ");
    const existingActions = element.getAttribute("data-action") || "";
    const newActions = existingActions
      ? `${existingActions} ${actionString}`
      : actionString;
    element.setAttribute("data-action", newActions);
  }

  /**
   * Validates that the trigger element has aria-describedby pointing to the tooltip.
   * This enforces W3C ARIA APG tooltip pattern requirement.
   * Uses standardized console error levels for ARIA violations.
   * @param {HTMLElement} triggerElement - The trigger element
   * @private
   */
  #validateAriaDescribedBy(triggerElement) {
    if (!this.hasTooltipTarget) return;

    const tooltipId = this.tooltipTarget.id;
    if (!tooltipId) {
      console.error(
        "[Pathogen::Tooltip] CRITICAL: Tooltip element must have an id attribute. " +
          "This violates W3C ARIA APG tooltip pattern requirements.",
      );
      return;
    }

    const describedBy = triggerElement.getAttribute("aria-describedby");
    if (!describedBy) {
      console.error(
        `[Pathogen::Tooltip] CRITICAL: Trigger element missing aria-describedby="${tooltipId}". ` +
          `This violates W3C ARIA APG requirements. ` +
          `Trigger: ${triggerElement.tagName}${triggerElement.id ? `#${triggerElement.id}` : ""}`,
      );
      return;
    }

    // Check if aria-describedby includes the tooltip ID
    const describedByIds = describedBy
      .split(/\s+/)
      .filter((id) => id.trim().length > 0);
    if (!describedByIds.includes(tooltipId)) {
      console.error(
        `[Pathogen::Tooltip] CRITICAL: aria-describedby must include tooltip ID "${tooltipId}". ` +
          `Current value: "${describedBy}". ` +
          `Trigger: ${triggerElement.tagName}${triggerElement.id ? `#${triggerElement.id}` : ""}`,
      );
    }
  }

  /**
   * Validates that the trigger element is keyboard-accessible.
   * Logs a warning for accessibility best practice violations.
   * @param {HTMLElement} triggerElement - The trigger element
   * @private
   */
  #validateKeyboardAccessibility(triggerElement) {
    // Check if element is inherently focusable or has tabindex
    const isFocusable = triggerElement.matches(
      'a, button, input, select, textarea, [tabindex]:not([tabindex="-1"])',
    );

    if (!isFocusable) {
      console.warn(
        `[Pathogen::Tooltip] WARNING: Trigger element is not keyboard-focusable. ` +
          `Consider adding tabindex="0" for better accessibility. ` +
          `Trigger: ${triggerElement.tagName}${triggerElement.id ? `#${triggerElement.id}` : ""}`,
      );
    }
  }

  /**
   * Hides any other visible tooltips to prevent multiple simultaneous tooltips.
   * @private
   */
  #hideOtherTooltips() {
    // Find all visible tooltips except this one
    document
      .querySelectorAll('[data-pathogen--tooltip-target="tooltip"].visible')
      .forEach((tooltip) => {
        if (
          tooltip !== this.tooltipTarget &&
          tooltip.classList.contains("visible")
        ) {
          // Get the controller for this tooltip and hide it
          const controller =
            this.application.getControllerForElementAndIdentifier(
              tooltip.closest("[data-controller*='pathogen--tooltip']"),
              "pathogen--tooltip",
            );
          if (controller) {
            controller.hide();
          }
        }
      });
  }

  #isTooltipVisible() {
    return (
      this.hasTooltipTarget &&
      this.tooltipTarget.classList.contains("opacity-100") &&
      this.tooltipTarget.classList.contains("visible")
    );
  }

  /**
   * Validates that a DOMRect has valid dimensions.
   * @param {DOMRect} rect - The rectangle to validate
   * @returns {boolean} True if rect has positive width and height
   * @private
   */
  #isValidRect(rect) {
    return rect && rect.width > 0 && rect.height > 0;
  }

  /**
   * Calculates tooltip position based on trigger rect and placement.
   * @param {DOMRect} triggerRect - The trigger element's bounding rectangle
   * @param {DOMRect} tooltipRect - The tooltip element's bounding rectangle
   * @param {string} placement - Desired placement (top, bottom, left, right)
   * @param {number} spacing - Space between trigger and tooltip in pixels
   * @returns {{top: number, left: number}} Calculated top and left positions
   * @private
   */
  #calculatePosition(triggerRect, tooltipRect, placement, spacing) {
    let top;
    let left;

    switch (placement) {
      case "bottom":
        top = triggerRect.bottom + spacing;
        left = triggerRect.left + triggerRect.width / 2 - tooltipRect.width / 2;
        break;
      case "left":
        top = triggerRect.top + triggerRect.height / 2 - tooltipRect.height / 2;
        left = triggerRect.left - tooltipRect.width - spacing;
        break;
      case "right":
        top = triggerRect.top + triggerRect.height / 2 - tooltipRect.height / 2;
        left = triggerRect.right + spacing;
        break;
      case "top":
      default:
        top = triggerRect.top - tooltipRect.height - spacing;
        left = triggerRect.left + triggerRect.width / 2 - tooltipRect.width / 2;
        break;
    }

    return { top, left };
  }

  /**
   * Checks if tooltip would fit in viewport with given placement.
   * Uses cached viewport dimensions for performance.
   * @param {DOMRect} triggerRect - The trigger element's bounding rectangle
   * @param {DOMRect} tooltipRect - The tooltip element's bounding rectangle
   * @param {string} placement - Desired placement to test
   * @param {number} spacing - Space between trigger and tooltip in pixels
   * @param {number} viewportPadding - Minimum padding from viewport edges
   * @returns {boolean} True if tooltip fits within viewport boundaries
   * @private
   */
  #fitsInViewport(
    triggerRect,
    tooltipRect,
    placement,
    spacing,
    viewportPadding,
  ) {
    const { top, left } = this.#calculatePosition(
      triggerRect,
      tooltipRect,
      placement,
      spacing,
    );
    // Use cached viewport dimensions instead of window.innerWidth/innerHeight
    const { width: viewportWidth, height: viewportHeight } = this.viewportCache;

    return (
      top >= viewportPadding &&
      left >= viewportPadding &&
      top + tooltipRect.height <= viewportHeight - viewportPadding &&
      left + tooltipRect.width <= viewportWidth - viewportPadding
    );
  }

  /**
   * Gets the opposite placement for tooltip flipping.
   * @param {string} placement - Current placement
   * @returns {string} Opposite placement (top↔bottom, left↔right)
   * @private
   */
  #getOppositePlacement(placement) {
    const opposites = {
      top: "bottom",
      bottom: "top",
      left: "right",
      right: "left",
    };
    return opposites[placement];
  }

  /**
   * Clamps tooltip position to viewport boundaries with padding.
   * Uses cached viewport dimensions for performance.
   * @param {number} top - Calculated top position
   * @param {number} left - Calculated left position
   * @param {DOMRect} tooltipRect - The tooltip element's bounding rectangle
   * @param {number} viewportPadding - Minimum padding from viewport edges
   * @returns {{top: number, left: number}} Clamped positions
   * @private
   */
  #clampToViewport(top, left, tooltipRect, viewportPadding) {
    // Use cached viewport dimensions instead of window.innerWidth/innerHeight
    const { width: viewportWidth, height: viewportHeight } = this.viewportCache;

    const clampedLeft = Math.max(
      viewportPadding,
      Math.min(left, viewportWidth - tooltipRect.width - viewportPadding),
    );

    const clampedTop = Math.max(
      viewportPadding,
      Math.min(top, viewportHeight - tooltipRect.height - viewportPadding),
    );

    return { top: clampedTop, left: clampedLeft };
  }

  #startTouchDismissTimer() {
    if (this.touchDismissTimeout) {
      clearTimeout(this.touchDismissTimeout);
    }

    this.touchDismissTimeout = setTimeout(() => {
      this.hide();
      this.touchPrimed = false;
      this.touchDismissTimeout = null;
    }, this.touchDismissDelayValue);
  }

  /**
   * Applies calculated position to tooltip element via inline styles.
   * @param {number} top - Top position in pixels
   * @param {number} left - Left position in pixels
   * @private
   */
  #applyPosition(top, left) {
    this.tooltipTarget.style.top = `${top}px`;
    this.tooltipTarget.style.left = `${left}px`;
  }

  /**
   * Fallback positioning when normal positioning fails.
   * Defaults to top placement with viewport clamping.
   * @param {DOMRect} triggerRect - The trigger element's bounding rectangle
   * @param {DOMRect} tooltipRect - The tooltip element's bounding rectangle
   * @private
   */
  #fallbackPosition(triggerRect, tooltipRect) {
    const spacing = this.spacingValue;
    const viewportPadding = this.viewportPaddingValue;

    const { top, left } = this.#calculatePosition(
      triggerRect,
      tooltipRect,
      "top",
      spacing,
    );

    const { top: clampedTop, left: clampedLeft } = this.#clampToViewport(
      top,
      left,
      tooltipRect,
      viewportPadding,
    );

    this.#applyPosition(clampedTop, clampedLeft);
  }

  /**
   * Handles window resize events and updates viewport cache.
   * Called by the shared tooltipRegistry handler.
   * Repositions visible tooltips automatically.
   */
  handleResize() {
    this.viewportCache = this.#getViewportDimensions();

    // Reposition tooltip if currently visible
    if (
      this.hasTooltipTarget &&
      this.tooltipTarget.classList.contains("visible")
    ) {
      this.positionTooltip();
    }
  }

  /**
   * Gets current viewport dimensions.
   * @returns {{width: number, height: number}} Viewport dimensions
   * @private
   */
  #getViewportDimensions() {
    return {
      width: window.innerWidth,
      height: window.innerHeight,
    };
  }
}
