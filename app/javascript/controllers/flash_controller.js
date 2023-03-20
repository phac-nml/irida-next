import { Controller } from "@hotwired/stimulus";

/**
 * This controller is responsible for dismissing flash messages after a timeout
 */
export default class extends Controller {
  connect() {
    console.log("Flash controller connected");
    // setTimeout(() => {
    //   this.dismiss();
    // }, 5000);
  }

  dismiss() {
    this.element.remove();
  }
}
