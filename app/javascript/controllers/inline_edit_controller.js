import { Controller } from "@hotwired/stimulus";

/**
 * Controller for handling inline editing functionality
 * @extends Controller
 */
export default class extends Controller {
  static targets = ["input", "newValue"];
  static values = {
    original: String,
  };

  connect() {
    this.inputTarget.focus();
    this.inputTarget.select();
  }

  // Handle keyboard events
  keydown(event) {
    if (event.key === "Escape") {
      this.reset();
    } else if (event.key === "Tab") {
      event.preventDefault();
      this.submit();
    }
  }

  // Handle blur event
  async blur(event) {
    if (!this.hasChanges) {
      this.reset();
      return;
    }

    event.preventDefault();
    const dialog = this.element.querySelector("dialog");
    if (!dialog) return;

    this.updateNewValue();
    await this.showConfirmDialog(dialog);
  }

  // Private methods
  get hasChanges() {
    const newValue = this.inputTarget.value.trim();
    return newValue !== this.originalValue;
  }

  updateNewValue() {
    if (this.hasNewValueTarget) {
      this.newValueTarget.textContent = this.inputTarget.value;
    }
  }

  async showConfirmDialog(dialog) {
    dialog.showModal();

    // Focus the cancel button for accessibility
    const cancelButton = dialog.querySelector('button[value="cancel"]');
    if (cancelButton) {
      requestAnimationFrame(() => cancelButton.focus());
    }

    // Handle dialog actions
    dialog.addEventListener(
      "click",
      (e) => {
        if (e.target.tagName !== "BUTTON") return;

        e.target.value === "confirm" ? this.submit() : this.reset();
        dialog.close();
      },
      { once: true },
    );

    // Handle dialog close
    dialog.addEventListener(
      "close",
      () => {
        this.inputTarget.focus();
      },
      { once: true },
    );
  }

  submit() {
    try {
      this.element.requestSubmit();
    } catch {
      this.reset();
    }
  }

  reset() {
    this.inputTarget.value = this.originalValue;
    this.submit();
  }
}
