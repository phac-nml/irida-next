import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    message: String,
  };

  connect() {
    this.idempotentConnect();
  }

  idempotentConnect() {
    this.element.setAttribute("data-controller-connected", "true");

    setTimeout(() => {
      this.element.innerText = this.messageValue;
    }, 1000);
  }
}
