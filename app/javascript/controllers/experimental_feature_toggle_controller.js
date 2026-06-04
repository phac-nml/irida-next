import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "status", "switch"];
  static values = {
    savingText: String,
    successText: String,
    featureKey: String,
    clearDelay: Number,
    minimumSavingMs: Number,
  };

  connect() {
    this.pending = false;
    this.restoreFocus();
    this.announceCurrentStatus();
    this.clearSuccessAfterDelay();
  }

  submit() {
    if (this.pending) {
      this.switchTarget.checked = this.lastSubmittedChecked;
      return;
    }

    this.pending = true;
    this.lastSubmittedChecked = this.switchTarget.checked;
    this.element.setAttribute("aria-busy", "true");
    this.switchTarget.setAttribute("aria-disabled", "true");
    this.statusTarget.textContent = this.savingTextValue;
    this.announce(this.savingTextValue);
    sessionStorage.setItem(this.sessionStorageKey(), this.switchTarget.id);

    const minimumSavingMs = this.hasMinimumSavingMsValue
      ? this.minimumSavingMsValue
      : 900;
    window.setTimeout(() => {
      this.formTarget.requestSubmit();
    }, minimumSavingMs);
  }

  sessionStorageKey() {
    return `experimentalFeatureToggleFocus:${this.featureKeyValue}`;
  }

  restoreFocus() {
    const restoreId = sessionStorage.getItem(this.sessionStorageKey());
    if (restoreId && restoreId === this.switchTarget.id) {
      this.switchTarget.focus();
      sessionStorage.removeItem(this.sessionStorageKey());
    }
  }

  clearSuccessAfterDelay() {
    if (this.statusTarget.textContent.trim() !== this.successTextValue) return;

    const delay = this.hasClearDelayValue ? this.clearDelayValue : 3000;
    window.setTimeout(() => {
      if (this.statusTarget.textContent.trim() === this.successTextValue) {
        this.statusTarget.textContent = "";
      }
    }, delay);
  }

  announceCurrentStatus() {
    const currentStatus = this.statusTarget.textContent.trim();
    if (!currentStatus) return;
    if (currentStatus === this.savingTextValue) return;

    this.announce(currentStatus);
  }

  announce(message) {
    const announcer = document.getElementById(
      "experimental-features-live-announcer",
    );
    if (announcer) announcer.textContent = message;
  }
}
