import { Controller } from "@hotwired/stimulus";
import { Modal } from "flowbite";

export default class extends Controller {
  static targets = ["targetEl"];

  connect() {
    this.modal = new Modal(this.targetElTarget, {
      backdrop: 'dynamic',
      backdropClasses: "bg-gray-900 bg-opacity-50 dark:bg-opacity-80 fixed inset-0 z-40",
      closable: true,
    });
  }

  open() {
    console.log("open");
    this.modal.show();
  }
}
