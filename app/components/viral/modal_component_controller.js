import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal"];

  connect() {
    console.log("CONNECTED");
  }

  open() {
    console.log("OPEN");
    this.modalTarget.classList.remove("hidden");
    document.body.innerHTML +=
      '<div id="modal-backdrop" class="bg-gray-900 bg-opacity-50 dark:bg-opacity-80 fixed inset-0 z-40"></div>';
  }

  close() {
    console.log("CLOSE");
    this.modalTarget.classList.add("hidden");
    document.getElementById("modal-backdrop").remove();
  }
}
