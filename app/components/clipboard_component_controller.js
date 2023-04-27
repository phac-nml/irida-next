import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["contents", "initial", "input", "copied", "hide", "view"];
  static values = { item: String };

  connect() {
    this.visible = false;
    this.element.setAttribute("data-controller-connected", "true");
  }

  copyToClipboard() {
    navigator.permissions
      .query({ name: "clipboard-write" })
      .then((result) => {
        navigator.clipboard.writeText(this.itemValue);
      })
      .catch(() => {
        this.inputTarget.select();
        // NOTE: This is deprecated but works in older browsers
        document.execCommand("copy");
      })
      .finally(() => {
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
      this.inputTarget.value = Array.prototype.join.call(
        { length: this.itemValue.length },
        "*"
      );
    } else {
      this.hideTarget.classList.add("hidden");
      this.viewTarget.classList.remove("hidden");
      this.inputTarget.value = this.itemValue;
    }
    this.visible = !this.visible;
  }
}
