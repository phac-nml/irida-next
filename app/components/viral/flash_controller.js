import { Controller } from "@hotwired/stimulus";

/**
 * This controller is responsible for dismissing flash messages after a timeout
 */
export default class extends Controller {
  static values = { timeout: Number };

  connect() {
    if (this.timeoutValue > 0) {
      setTimeout(() => {
        this.dismiss();
      }, this.timeoutValue);
    }
  }

  dismiss() {
    this.element.remove();
  }
}
