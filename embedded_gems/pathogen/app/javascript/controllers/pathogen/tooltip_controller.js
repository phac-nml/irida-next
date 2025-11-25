import { Controller } from "@hotwired/stimulus";

/**
 * Pathogen::Tooltip Stimulus Controller
 *
 * Implements custom tooltip show/hide behavior with JavaScript positioning.
 * Supports hover and focus triggers for accessibility.
 *
 * @example
 * <div data-controller="pathogen--tooltip">
 *   <a data-pathogen--tooltip-target="trigger"
 *      data-action="mouseenter->pathogen--tooltip#show mouseleave->pathogen--tooltip#hide focusin->pathogen--tooltip#show focusout->pathogen--tooltip#hide"
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
  }

  triggerTargetConnected(element) {
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

    // Set anchor-name for CSS anchor positioning (future enhancement)
    const existingStyle = element.getAttribute("style") || "";
    element.setAttribute(
      "style",
      existingStyle + "; anchor-name: --tooltip-trigger;",
    );
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
   * Position tooltip using JavaScript with viewport boundary detection
   */
  positionTooltip() {
    if (!this.hasTriggerTarget || !this.hasTargetTarget) return;

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
  }
}
