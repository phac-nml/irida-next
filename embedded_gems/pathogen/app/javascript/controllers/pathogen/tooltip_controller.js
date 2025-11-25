import { Controller } from "@hotwired/stimulus";

/**
 * Pathogen::Tooltip Stimulus Controller
 *
 * Implements custom tooltip show/hide behavior using CSS anchor positioning.
 * Supports hover and focus triggers for accessibility.
 *
 * @example
 * <div data-controller="pathogen--tooltip">
 *   <button data-pathogen--tooltip-target="trigger" aria-describedby="tooltip-id">
 *     Hover or focus me
 *   </button>
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

  disconnect() {
    // Clean up event listeners when controller is disconnected
    if (this.hasTriggerTarget) {
      this.triggerTarget.removeEventListener("mouseenter", this.show);
      this.triggerTarget.removeEventListener("mouseleave", this.hide);
      this.triggerTarget.removeEventListener("focusin", this.show);
      this.triggerTarget.removeEventListener("focusout", this.hide);
    }
  }

  targetTargetConnected() {
    // Set up event listeners when tooltip target is connected
    if (this.hasTriggerTarget && this.hasTargetTarget) {
      // Set anchor-name on trigger element for CSS anchor positioning
      // Using setAttribute to ensure compatibility
      this.triggerTarget.setAttribute("style",
        (this.triggerTarget.getAttribute("style") || "") + "; anchor-name: --tooltip-trigger;"
      );

      // Bind event handlers to preserve 'this' context
      this.show = this.#show.bind(this);
      this.hide = this.#hide.bind(this);

      // Add event listeners for hover and focus
      this.triggerTarget.addEventListener("mouseenter", this.show);
      this.triggerTarget.addEventListener("mouseleave", this.hide);
      this.triggerTarget.addEventListener("focusin", this.show);
      this.triggerTarget.addEventListener("focusout", this.hide);

      // Debug: Log when controller is connected
      console.log("Tooltip controller connected", {
        trigger: this.triggerTarget,
        target: this.targetTarget
      });
    }
  }

  /**
   * Shows the tooltip with fade-in and scale animation
   * @private
   */
  #show() {
    if (!this.hasTargetTarget) return;

    console.log("Showing tooltip", this.targetTarget);

    // Position tooltip using JavaScript as fallback for CSS anchor positioning
    this.#positionTooltip();

    // Remove hidden state classes and add visible state classes
    this.targetTarget.classList.remove("opacity-0", "scale-90", "invisible");
    this.targetTarget.classList.add("opacity-100", "scale-100", "visible");
  }

  /**
   * Position tooltip using JavaScript fallback
   * @private
   */
  #positionTooltip() {
    if (!this.hasTriggerTarget || !this.hasTargetTarget) return;

    const placement = this.targetTarget.dataset.placement || "top";
    const triggerRect = this.triggerTarget.getBoundingClientRect();
    const tooltipRect = this.targetTarget.getBoundingClientRect();
    const spacing = 8; // 0.5rem

    let top, left;

    switch (placement) {
      case "top":
        top = triggerRect.top - tooltipRect.height - spacing;
        left = triggerRect.left + (triggerRect.width / 2) - (tooltipRect.width / 2);
        break;
      case "bottom":
        top = triggerRect.bottom + spacing;
        left = triggerRect.left + (triggerRect.width / 2) - (tooltipRect.width / 2);
        break;
      case "left":
        top = triggerRect.top + (triggerRect.height / 2) - (tooltipRect.height / 2);
        left = triggerRect.left - tooltipRect.width - spacing;
        break;
      case "right":
        top = triggerRect.top + (triggerRect.height / 2) - (tooltipRect.height / 2);
        left = triggerRect.right + spacing;
        break;
    }

    // Apply calculated position (tooltip already has fixed positioning from template)
    this.targetTarget.style.top = `${top}px`;
    this.targetTarget.style.left = `${left}px`;

    console.log("Positioned tooltip at", { top, left, placement, triggerRect, tooltipRect });
  }

  /**
   * Hides the tooltip with fade-out and scale animation
   * @private
   */
  #hide() {
    if (!this.hasTargetTarget) return;

    console.log("Hiding tooltip", this.targetTarget);

    // Remove visible state classes and add hidden state classes
    this.targetTarget.classList.remove("opacity-100", "scale-100", "visible");
    this.targetTarget.classList.add("opacity-0", "scale-90", "invisible");
  }
}
