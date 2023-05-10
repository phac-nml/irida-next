import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal"];

  connect() {
    console.log("CONNECTED");
  }

  open() {
    console.log("OPEN");
    this.modalTarget.classList.remove("hidden");
  }

  close() {
    console.log("CLOSE");
    this.modalTarget.classList.add("hidden");
  }
}
