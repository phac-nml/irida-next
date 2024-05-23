import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['dialog'];

  static values = { open: Boolean };

  connect() {
    if (this.openValue) this.open();
    this.element.setAttribute("data-controller-connected", "true");
  }

  disconnect() {
    this.openValue = false;
  }

  open() {
    this.dialogTarget.showModal();
  }

  close() {
    this.dialogTarget.close();
  }

  handleEsc(event) {
    event.preventDefault();
  }
}
