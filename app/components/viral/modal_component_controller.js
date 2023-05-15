import { Controller } from "@hotwired/stimulus";
import { Modal } from "flowbite";

export default class extends Controller {
  static targets = ["modal"];

  connect() {
    this.modal = new Modal(this.modalTarget, {
      backdrop: "static",
      backdropClasses:
        "bg-gray-900 bg-opacity-50 dark:bg-opacity-80 fixed inset-0 z-40",
    });
    this.modal.show();
  }

  open() {
    this.modal.show();
  }

  close() {
    this.modal.hide();
  }
}
