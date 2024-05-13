import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { open: Boolean };
  connect() {
    this.dialog = document.getElementById("dialog");
    if (this.openValue) this.open();
    this.element.setAttribute("data-controller-connected", "true");
  }

  disconnect() {
    this.openValue = false;
  }

  open() {
    this.dialog.showModal();
  }

  close() {
    this.dialog.close();
  }

  handleEsc(event) {
    event.preventDefault();
  }
}
