import { Controller } from "@hotwired/stimulus";

// Lets someone reveal what they typed in a password field. The toggle stays
// hidden until this connects, so nothing inert shows when JavaScript is off.
export default class extends Controller {
  static targets = ["input", "toggle", "showIcon", "hideIcon"];

  static values = {
    showLabel: String,
    hideLabel: String,
  };

  connect() {
    this.conceal = this.conceal.bind(this);
    this.form = this.inputTarget.form;
    this.form?.addEventListener("submit", this.conceal);
    this.toggleTarget.classList.replace("hidden", "grid");
    this.#render(false);
  }

  disconnect() {
    this.form?.removeEventListener("submit", this.conceal);
  }

  toggle() {
    this.#render(this.inputTarget.type === "password");
  }

  // Browsers only offer to save credentials from a password-type field.
  conceal() {
    this.#render(false);
  }

  #render(visible) {
    this.inputTarget.type = visible ? "text" : "password";
    this.toggleTarget.setAttribute("aria-pressed", String(visible));
    this.toggleTarget.setAttribute(
      "aria-label",
      visible ? this.hideLabelValue : this.showLabelValue,
    );
    this.showIconTarget.classList.toggle("hidden", visible);
    this.hideIconTarget.classList.toggle("hidden", !visible);
  }
}
