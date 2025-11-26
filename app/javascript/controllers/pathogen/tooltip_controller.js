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

    // Position tooltip using JavaScript
    this.positionTooltip();

    // Remove hidden state classes and add visible state classes
    this.targetTarget.classList.remove("opacity-0", "scale-90", "invisible");
    this.targetTarget.classList.add("opacity-100", "scale-100", "visible");
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
      const triggerRect = this.triggerTarget.getBoundingClientRect();
      const tooltipRect = this.targetTarget.getBoundingClientRect();
      const spacing = 8; // 0.5rem
      const viewportPadding = 8; // Minimum distance from viewport edge

      // Calculate position for a given placement
      const calculatePosition = (placement) => {
        let top, left;

        switch (placement) {
          case "top":
            top = triggerRect.top - tooltipRect.height - spacing;
            left =
              triggerRect.left + triggerRect.width / 2 - tooltipRect.width / 2;
            break;
          case "bottom":
            top = triggerRect.bottom + spacing;
            left =
              triggerRect.left + triggerRect.width / 2 - tooltipRect.width / 2;
            break;
          case "left":
            top =
              triggerRect.top + triggerRect.height / 2 - tooltipRect.height / 2;
            left = triggerRect.left - tooltipRect.width - spacing;
            break;
          case "right":
            top =
              triggerRect.top + triggerRect.height / 2 - tooltipRect.height / 2;
            left = triggerRect.right + spacing;
            break;
        }

        return { top, left };
      };

      // Check if tooltip fits within viewport for a given placement
      const fitsInViewport = (placement) => {
        const { top, left } = calculatePosition(placement);
        const viewportWidth = window.innerWidth;
        const viewportHeight = window.innerHeight;

        return (
          top >= viewportPadding &&
          left >= viewportPadding &&
          top + tooltipRect.height <= viewportHeight - viewportPadding &&
          left + tooltipRect.width <= viewportWidth - viewportPadding
        );
      };

      // Get opposite placement for flipping
      const getOppositePlacement = (placement) => {
        const opposites = {
          top: "bottom",
          bottom: "top",
          left: "right",
          right: "left",
        };
        return opposites[placement];
      };

      // Determine best placement (prefer original, flip if needed)
      let placement = preferredPlacement;
      if (!fitsInViewport(preferredPlacement)) {
        const opposite = getOppositePlacement(preferredPlacement);
        if (fitsInViewport(opposite)) {
          placement = opposite;
        }
        // If neither fits, stick with preferred and clamp to viewport
      }

      let { top, left } = calculatePosition(placement);

      // Clamp position to viewport bounds
      const viewportWidth = window.innerWidth;
      const viewportHeight = window.innerHeight;

      // Horizontal clamping
      if (left < viewportPadding) {
        left = viewportPadding;
      } else if (left + tooltipRect.width > viewportWidth - viewportPadding) {
        left = viewportWidth - tooltipRect.width - viewportPadding;
      }

      // Vertical clamping
      if (top < viewportPadding) {
        top = viewportPadding;
      } else if (top + tooltipRect.height > viewportHeight - viewportPadding) {
        top = viewportHeight - tooltipRect.height - viewportPadding;
      }

      // Apply calculated position (tooltip has fixed positioning from template)
      this.targetTarget.style.top = `${top}px`;
      this.targetTarget.style.left = `${left}px`;
    } catch (error) {
      // Log error but don't break the UI - tooltip will use default positioning
      console.warn("Tooltip positioning error:", error);
      // Fallback to default top positioning
      if (this.hasTargetTarget && this.hasTriggerTarget) {
        const triggerRect = this.triggerTarget.getBoundingClientRect();
        const tooltipRect = this.targetTarget.getBoundingClientRect();
        const spacing = 8; // 0.5rem - matches spacing constant above
        // Center tooltip above trigger
        this.targetTarget.style.top = `${triggerRect.top - tooltipRect.height - spacing}px`;
        this.targetTarget.style.left = `${triggerRect.left + triggerRect.width / 2 - tooltipRect.width / 2}px`;
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
}
