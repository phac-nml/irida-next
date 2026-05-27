import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "contents",
    "initial",
    "input",
    "copied",
    "hide",
    "view",
    "maskButton",
  ];
  static values = {
    item: String,
  };

  connect() {
    this.visible = false;
    this.maskButtonTarget.setAttribute("aria-pressed", "false");
    this.element.setAttribute("data-controller-connected", "true");
  }

  copyToClipboard() {
    navigator.clipboard.writeText(this.itemValue);

    this.initialTarget.classList.add("hidden");
    this.copiedTarget.classList.remove("hidden");
    setTimeout(() => {
      this.initialTarget.classList.remove("hidden");
      this.copiedTarget.classList.add("hidden");
    }, 2000);
  }

  toggleVisibility() {
    if (this.visible) {
      this.hideTarget.classList.remove("hidden");
      this.viewTarget.classList.add("hidden");
      this.inputTarget.value = Array.prototype.join.call(
        { length: this.itemValue.length },
        "*",
      );
    } else {
      this.hideTarget.classList.add("hidden");
      this.viewTarget.classList.remove("hidden");
      this.inputTarget.value = this.itemValue;
    }
    this.visible = !this.visible;
    this.maskButtonTarget.setAttribute(
      "aria-pressed",
      this.visible ? "true" : "false",
    );
  }

  removeTokenPanel() {
    const panel = document.getElementById("access-token-section");
    if (panel) {
      panel.remove();
    }
  }
}
