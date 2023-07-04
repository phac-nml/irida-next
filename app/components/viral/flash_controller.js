import { Controller } from "@hotwired/stimulus";

/**
 * This controller is responsible for dismissing flash messages after a timeout
 */
export default class extends Controller {
  static values = { timeout: Number };

  connect() {
    if (this.timeoutValue > 0) {
      this.run();
      this.element.addEventListener("mouseenter", this.pause.bind(this));
      this.element.addEventListener("mouseleave", this.run.bind(this));
    }
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
    this.element.remove();
  }
}
