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

  #connection = 0;
  #feedbackTimeout;
  #resetFeedback;

  disconnect() {
    this.#connection += 1;
    this.#clearFeedback();
  }

  #clearFeedback() {
    clearTimeout(this.#feedbackTimeout);
    this.#resetFeedback?.();
    this.#resetFeedback = undefined;
  }

  connect() {
    this.visible = false;
    this.inputTarget.value = "*".repeat(this.itemValue.length);
    this.hideTarget.classList.remove("hidden");
    this.viewTarget.classList.add("hidden");
    this.maskButtonTarget.setAttribute("aria-pressed", "false");
    this.element.setAttribute("data-controller-connected", "true");
  }

  async copyToClipboard() {
    if (!navigator.clipboard) {
      console.error("Clipboard API not available");
      return;
    }
    const connection = this.#connection;
    try {
      await navigator.clipboard.writeText(this.itemValue);
      if (connection !== this.#connection) return;
      this.#clearFeedback();
      const initial = this.initialTarget;
      const copied = this.copiedTarget;
      initial.classList.add("hidden");
      copied.classList.remove("hidden");
      this.#resetFeedback = () => {
        initial.classList.remove("hidden");
        copied.classList.add("hidden");
      };
      this.#feedbackTimeout = setTimeout(() => this.#clearFeedback(), 2000);
    } catch (error) {
      console.error("Failed to copy token:", error);
    }
  }

  toggleVisibility() {
    if (this.visible) {
      this.hideTarget.classList.remove("hidden");
      this.viewTarget.classList.add("hidden");
      this.inputTarget.value = "*".repeat(this.itemValue.length);
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
