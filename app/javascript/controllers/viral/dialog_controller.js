import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["dialog", "close"];

  static values = { open: Boolean };

  connect() {
    if (this.openValue) this.open();
    this.element.setAttribute("data-controller-connected", "true");
  }

  disconnect() {
    this.close();
  }

  open() {
    this.openValue = true;
    this.dialogTarget.showModal();
  }

  close() {
    this.openValue = false;
    this.dialogTarget.close();
  }

  handleEsc(event) {
    event.preventDefault();
  }

  hideClose() {
    if (this.hasCloseTarget) {
      this.closeTarget.classList.add("hidden");
    }
  }
}
