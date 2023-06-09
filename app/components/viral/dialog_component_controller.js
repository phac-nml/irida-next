import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { open: Boolean };
  connect() {
    this.dialog = document.getElementById("dialog");
    console.log(this.openValue);
    if (this.openValue) this.open();
    this.element.setAttribute("data-controller-connected", "true");
  }

  open() {
    this.dialog.showModal();
  }

  close() {
    this.dialog.close();
  }
}
