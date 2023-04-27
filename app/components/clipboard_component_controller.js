import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["contents", "initial", "input", "copied", "hide", "view"];

  connect() {
    this.visible = false;
  }

  copyToClipboard() {
    navigator.clipboard.writeText(this.inputTarget.value).then(() => {
      this.initialTarget.classList.add("hidden");
      this.copiedTarget.classList.remove("hidden");
      setTimeout(() => {
        this.initialTarget.classList.remove("hidden");
        this.copiedTarget.classList.add("hidden");
      }, 2000);
    });
  }

  toggleVisibility() {
    if (this.visible) {
      this.hideTarget.classList.remove("hidden");
      this.viewTarget.classList.add("hidden");
      this.inputTarget.type = "password";
    } else {
      this.hideTarget.classList.add("hidden");
      this.viewTarget.classList.remove("hidden");
      this.inputTarget.type = "text";
    }
    this.visible = !this.visible;
  }
}
