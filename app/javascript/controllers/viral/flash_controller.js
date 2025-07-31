import { Controller } from "@hotwired/stimulus";

/**
 * This controller is responsible for dismissing flash messages after a timeout
 * with smooth animations
 */
export default class extends Controller {
  static values = { timeout: Number, type: String };

  connect() {
    // Trigger entrance animation
    this.animateIn();

    // Always force errors to not have a timeout
    if (this.typeValue !== "error" && this.timeoutValue > 0) {
      this.run();
      this.element.addEventListener("mouseenter", this.pause.bind(this));
      this.element.addEventListener("mouseleave", this.run.bind(this));
    }
  }

  animateIn() {
    // Use requestAnimationFrame to ensure the initial state is applied first
    requestAnimationFrame(() => {
      // Animate to final state
      this.element.style.opacity = "1";
      this.element.style.transform = "translateY(0) scale(1)";
    });
  }

  run() {
    this.startedTime = new Date().getTime();
    if (this.timeoutValue > 0) {
      this.timeout = setTimeout(() => {
        this.dismiss();
      }, this.timeoutValue);
    }
  }

  pause() {
    if (this.timeoutValue > 0) {
      clearTimeout(this.timeout);
      this.timeoutValue -= new Date().getTime() - this.startedTime;
    }
  }

  dismiss() {
    this.element.removeEventListener("mouseenter", this.pause);
    this.element.removeEventListener("mouseleave", this.run);

    // Add slide-out animation
    this.element.style.transform = "translateX(100%)";
    this.element.style.opacity = "0";
    this.element.style.transition = "all 0.3s ease-out";

    // Remove element after animation completes
    setTimeout(() => {
      this.element.remove();
    }, 300);
  }
}
