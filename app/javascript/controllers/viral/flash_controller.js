import { Controller } from "@hotwired/stimulus";

/**
 * This controller is responsible for dismissing flash messages after a timeout
 * with smooth animations
 */
export default class extends Controller {
  static values = { timeout: Number, type: String };

  initialize() {
    this.boundPause = this.pause.bind(this);
    this.boundRun = this.run.bind(this);
  }

  connect() {
    // Trigger entrance animation
    this.animateIn();

    // Always force errors to not have a timeout
    if (this.typeValue !== "error" && this.timeoutValue > 0) {
      this.run();
      this.element.addEventListener("mouseenter", this.boundPause);
      this.element.addEventListener("mouseleave", this.boundRun);
    }
  }

  disconnect() {
    this.#cleanup();
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
    // Add slide-out animation
    this.element.style.transform = "translateX(100%)";
    this.element.style.opacity = "0";
    this.element.style.transition = "all 0.3s ease-out";

    // Remove element after animation completes
    setTimeout(() => {
      this.element.remove();
    }, 300);
  }

  #cleanup() {
    clearTimeout(this.timeout);
    this.element.removeEventListener("mouseenter", this.boundPause);
    this.element.removeEventListener("mouseleave", this.boundRun);
  }
}
