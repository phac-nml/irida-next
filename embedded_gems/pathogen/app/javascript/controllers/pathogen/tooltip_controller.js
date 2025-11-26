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
 * - Clamps position to viewport bounds with 8px padding to prevent overflow
 * - Applies position via inline top/left styles on tooltip element (position: fixed)
 *
 * ## Accessibility
 * Follows W3C ARIA Authoring Practices Guide (APG) tooltip pattern:
 * - Tooltip remains open when cursor is over trigger OR tooltip
 * - Dismisses on Escape key press
 * - Dismisses on focus loss (blur) when triggered by focus
 * - Requires aria-describedby connection from trigger to tooltip
 *
 * @example
 * <div data-controller="pathogen--tooltip">
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

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
    // Add Escape key handler for keyboard dismissal
    this.boundHandleEscape = this.handleEscape.bind(this);
    document.addEventListener("keydown", this.boundHandleEscape);
  }

  disconnect() {
    // Clean up Escape key listener
    document.removeEventListener("keydown", this.boundHandleEscape);
  }

  triggerTargetConnected(element) {
    // Validate W3C ARIA APG requirement: trigger must have aria-describedby
    // pointing to the tooltip element
    this.#validateAriaDescribedBy(element);

    // Add data-action attributes to trigger for Stimulus event handling
    const actions = [
      "mouseenter->pathogen--tooltip#show",
      "mouseleave->pathogen--tooltip#hide",
      "focusin->pathogen--tooltip#show",
      "focusout->pathogen--tooltip#hide",
    ].join(" ");

    const existingActions = element.getAttribute("data-action") || "";
    const newActions = existingActions
      ? `${existingActions} ${actions}`
      : actions;
    element.setAttribute("data-action", newActions);
  }

  targetTargetConnected(element) {
    // Add mouse event handlers to tooltip itself to keep it open when cursor
    // moves from trigger to tooltip (W3C ARIA APG compliance)
    const actions = [
      "mouseenter->pathogen--tooltip#show",
      "mouseleave->pathogen--tooltip#hide",
    ].join(" ");

    const existingActions = element.getAttribute("data-action") || "";
    const newActions = existingActions
      ? `${existingActions} ${actions}`
      : actions;
    element.setAttribute("data-action", newActions);
  }

  /**
   * Shows the tooltip with fade-in and scale animation
   */
  show() {
    if (!this.hasTargetTarget) return;

    // Temporarily make tooltip visible but transparent for accurate measurement
    // This ensures the browser calculates proper dimensions for inline-block elements
    this.targetTarget.classList.remove("scale-90", "invisible");
    this.targetTarget.classList.add("scale-100", "visible");

    // Position tooltip using JavaScript (tooltip is visible but transparent)
    this.positionTooltip();

    // Now reveal tooltip with fade-in animation (remove opacity-0)
    this.targetTarget.classList.remove("opacity-0");
    this.targetTarget.classList.add("opacity-100");
  }

  /**
   * Hides the tooltip with fade-out and scale animation
   */
  hide() {
    if (!this.hasTargetTarget) return;

    // Remove visible state classes and add hidden state classes
    this.targetTarget.classList.remove("opacity-100", "scale-100", "visible");
    this.targetTarget.classList.add("opacity-0", "scale-90", "invisible");
  }

  /**
   * Handles Escape key press to dismiss tooltip
   * @param {KeyboardEvent} event
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
   * Position tooltip using JavaScript with viewport boundary detection.
   *
   * This method calculates the optimal position for the tooltip based on:
   * 1. Preferred placement (top, bottom, left, right) from data-placement attribute
   * 2. Viewport boundaries - flips placement if tooltip would overflow viewport edge
   * 3. Position clamping - ensures tooltip stays within viewport with 8px padding
   *
   * Uses getBoundingClientRect() for precise element positioning calculations.
   * Applies position via inline top and left styles (tooltip has position: fixed).
   */
  positionTooltip() {
    if (!this.hasTriggerTarget || !this.hasTargetTarget) return;

    try {
      const preferredPlacement = this.targetTarget.dataset.placement || "top";
      const spacing = this.#spacing();
      const viewportPadding = this.#viewportPadding();
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
      // Log error but don't break the UI - tooltip will use default positioning
      console.warn("[Pathogen::Tooltip] Tooltip positioning error:", error);

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
   * Validates that the trigger element has aria-describedby pointing to the tooltip.
   * This enforces W3C ARIA APG tooltip pattern requirement.
   * @param {HTMLElement} triggerElement - The trigger element
   * @private
   */
  #validateAriaDescribedBy(triggerElement) {
    if (!this.hasTargetTarget) return;

    const tooltipId = this.targetTarget.id;
    if (!tooltipId) {
      console.warn(
        "[Pathogen::Tooltip] Tooltip element must have an id attribute for aria-describedby connection.",
      );
      return;
    }

    const describedBy = triggerElement.getAttribute("aria-describedby");
    if (!describedBy) {
      console.error(
        `[Pathogen::Tooltip] Trigger element must have aria-describedby="${tooltipId}" ` +
          `pointing to the tooltip element (W3C ARIA APG requirement). ` +
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
        `[Pathogen::Tooltip] Trigger element's aria-describedby must include the tooltip ID "${tooltipId}". ` +
          `Current value: "${describedBy}". ` +
          `Trigger: ${triggerElement.tagName}${triggerElement.id ? `#${triggerElement.id}` : ""}`,
      );
    }
  }

  #spacing() {
    // 0.5rem spacing between trigger and tooltip
    return 8;
  }

  #viewportPadding() {
    // Minimum distance from viewport edge to tooltip
    return 8;
  }

  #isValidRect(rect) {
    return rect && rect.width > 0 && rect.height > 0;
  }

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
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;

    return (
      top >= viewportPadding &&
      left >= viewportPadding &&
      top + tooltipRect.height <= viewportHeight - viewportPadding &&
      left + tooltipRect.width <= viewportWidth - viewportPadding
    );
  }

  #getOppositePlacement(placement) {
    const opposites = {
      top: "bottom",
      bottom: "top",
      left: "right",
      right: "left",
    };
    return opposites[placement];
  }

  #clampToViewport(top, left, tooltipRect, viewportPadding) {
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;

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

  #applyPosition(top, left) {
    this.targetTarget.style.top = `${top}px`;
    this.targetTarget.style.left = `${left}px`;
  }

  #fallbackPosition(triggerRect, tooltipRect) {
    const spacing = this.#spacing();
    const viewportPadding = this.#viewportPadding();

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
}
