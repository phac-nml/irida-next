import { Controller } from "@hotwired/stimulus";

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
 *   <div id="tooltip-id" data-pathogen--tooltip-target="target" role="tooltip">
 *     Tooltip content
 *   </div>
 * </div>
 */
export default class extends Controller {
  static targets = ["trigger", "target"];
  static values = {
    spacing: { type: Number, default: 8 },
    viewportPadding: { type: Number, default: 8 },
    touchDismissDelay: { type: Number, default: 3000 },
  };

  connect() {
    this.element.setAttribute("data-controller-connected", "true");

    // Store touch dismiss timeout for cleanup
    this.touchDismissTimeout = null;

    // Check for reduced motion preference
    this.prefersReducedMotion = window.matchMedia(
      "(prefers-reduced-motion: reduce)",
    ).matches;

    // Cache viewport dimensions and update on resize for performance
    this.viewportCache = this.#getViewportDimensions();
    this.boundHandleResize = this.#handleResize.bind(this);
    window.addEventListener("resize", this.boundHandleResize);
    this.resizeRAF = null;

    // Add Escape key handler for keyboard dismissal
    this.boundHandleEscape = this.handleEscape.bind(this);
    document.addEventListener("keydown", this.boundHandleEscape);

    // Add touch outside handler for mobile dismissal
    this.boundHandleTouchOutside = this.handleTouchOutside.bind(this);
    document.addEventListener("touchstart", this.boundHandleTouchOutside);
  }

  disconnect() {
    // Clean up Escape key listener
    document.removeEventListener("keydown", this.boundHandleEscape);

    // Clean up touch outside listener
    document.removeEventListener("touchstart", this.boundHandleTouchOutside);

    // Clean up resize listener
    window.removeEventListener("resize", this.boundHandleResize);
    if (this.resizeRAF) {
      cancelAnimationFrame(this.resizeRAF);
      this.resizeRAF = null;
    }

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
    ];

    this.#addEventActions(element, actions);
  }

  targetTargetConnected(element) {
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
    if (!this.hasTargetTarget) return;

    // Hide any other visible tooltips to prevent multiple simultaneous tooltips
    this.#hideOtherTooltips();

    if (this.prefersReducedMotion) {
      // Skip scale animation for users who prefer reduced motion
      this.targetTarget.classList.remove("invisible", "opacity-0");
      this.targetTarget.classList.add("visible", "opacity-100");
    } else {
      // Temporarily make tooltip visible but transparent for accurate measurement
      // This ensures the browser calculates proper dimensions for inline-block elements
      this.targetTarget.classList.remove("scale-90", "invisible");
      this.targetTarget.classList.add("scale-100", "visible");

      // Now reveal tooltip with fade-in animation (remove opacity-0)
      this.targetTarget.classList.remove("opacity-0");
      this.targetTarget.classList.add("opacity-100");
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
    if (!this.hasTargetTarget) return;

    // Clear any pending touch dismiss timeout
    if (this.touchDismissTimeout) {
      clearTimeout(this.touchDismissTimeout);
      this.touchDismissTimeout = null;
    }

    if (this.prefersReducedMotion) {
      // Skip scale animation for users who prefer reduced motion
      this.targetTarget.classList.remove("visible", "opacity-100");
      this.targetTarget.classList.add("invisible", "opacity-0");
    } else {
      // Remove visible state classes and add hidden state classes with animation
      this.targetTarget.classList.remove("opacity-100", "scale-100", "visible");
      this.targetTarget.classList.add("opacity-0", "scale-90", "invisible");
    }
  }

  /**
   * Handles Escape key press to dismiss tooltip.
   * @param {KeyboardEvent} event - The keyboard event
   */
  handleEscape(event) {
    if (event.key === "Escape" && this.hasTargetTarget) {
      // Check if tooltip is currently visible
      if (
        this.targetTarget.classList.contains("opacity-100") &&
        this.targetTarget.classList.contains("visible")
      ) {
        this.hide();
        // Return focus to trigger element if it exists
        if (this.hasTriggerTarget) {
          this.triggerTarget.focus();
        }
      }
    }
  }

  /**
   * Handles touch events on trigger element for mobile support.
   * Shows tooltip and sets auto-dismiss timer.
   * @param {TouchEvent} event - The touch event
   */
  handleTouch(event) {
    // Prevent default to avoid triggering mouse events
    event.preventDefault();

    // Show tooltip
    this.show();

    // Set auto-dismiss timeout for better mobile UX
    if (this.touchDismissTimeout) {
      clearTimeout(this.touchDismissTimeout);
    }

    this.touchDismissTimeout = setTimeout(() => {
      this.hide();
      this.touchDismissTimeout = null;
    }, this.touchDismissDelayValue);
  }

  /**
   * Handles touch outside tooltip or trigger to dismiss on mobile.
   * @param {TouchEvent} event - The touch event
   */
  handleTouchOutside(event) {
    if (!this.hasTargetTarget || !this.hasTriggerTarget) return;

    // Check if tooltip is currently visible
    const isVisible =
      this.targetTarget.classList.contains("opacity-100") &&
      this.targetTarget.classList.contains("visible");

    if (!isVisible) return;

    // Check if touch is outside both tooltip and trigger
    const touchedElement = event.target;
    const isTouchOutside =
      !this.targetTarget.contains(touchedElement) &&
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
    if (!this.hasTriggerTarget || !this.hasTargetTarget) return;

    try {
      const preferredPlacement = this.targetTarget.dataset.placement || "top";
      const spacing = this.spacingValue;
      const viewportPadding = this.viewportPaddingValue;
      const triggerRect = this.triggerTarget.getBoundingClientRect();
      const tooltipRect = this.targetTarget.getBoundingClientRect();

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
      if (this.hasTargetTarget && this.hasTriggerTarget) {
        const triggerRect = this.triggerTarget.getBoundingClientRect();
        const tooltipRect = this.targetTarget.getBoundingClientRect();
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
    if (!this.hasTargetTarget) return;

    const tooltipId = this.targetTarget.id;
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
      .querySelectorAll('[data-pathogen--tooltip-target="target"].visible')
      .forEach((tooltip) => {
        if (
          tooltip !== this.targetTarget &&
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

  /**
   * Applies calculated position to tooltip element via inline styles.
   * @param {number} top - Top position in pixels
   * @param {number} left - Left position in pixels
   * @private
   */
  #applyPosition(top, left) {
    this.targetTarget.style.top = `${top}px`;
    this.targetTarget.style.left = `${left}px`;
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
   * Uses requestAnimationFrame for throttling to avoid layout thrashing.
   * Repositions visible tooltips automatically.
   * @private
   */
  #handleResize() {
    if (this.resizeRAF) {
      cancelAnimationFrame(this.resizeRAF);
    }

    this.resizeRAF = requestAnimationFrame(() => {
      this.viewportCache = this.#getViewportDimensions();

      // Reposition tooltip if currently visible
      if (
        this.hasTargetTarget &&
        this.targetTarget.classList.contains("visible")
      ) {
        this.positionTooltip();
      }

      this.resizeRAF = null;
    });
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
