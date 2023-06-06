import { Controller } from "@hotwired/stimulus";
import { Modal } from "flowbite";

export default class extends Controller {
  static targets = ["modal"];
  static values = { open: Boolean };

  connect() {
    this.modal = new Modal(this.modalTarget, {});
    if (this.openValue) this.modal.show();
    this.element.setAttribute("data-controller-connected", "true");
  }

  open() {
    this.modal.show();
  }

  close() {
    this.modal.hide();
  }
}
