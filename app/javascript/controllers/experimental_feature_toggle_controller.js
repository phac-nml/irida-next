import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "status", "switch"];
  static values = {
    savingText: String,
    successText: String,
    validationErrorText: String,
    featureKey: String,
    clearDelay: Number,
    minimumSavingMs: Number,
  };

  connect() {
    this.pending = false;
    this.boundOnSubmitEnd = this.onSubmitEnd.bind(this);
    this.formTarget.addEventListener("turbo:submit-end", this.boundOnSubmitEnd);
    this.restoreFocus();
    this.announceCurrentStatus();
    this.clearSuccessAfterDelay();
  }

  disconnect() {
    this.formTarget.removeEventListener(
      "turbo:submit-end",
      this.boundOnSubmitEnd,
    );
  }

  submit() {
    if (this.pending) {
      this.switchTarget.checked = this.lastSubmittedChecked;
      return;
    }

    this.pending = true;
    this.lastSubmittedChecked = this.switchTarget.checked;
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

  onSubmitEnd(event) {
    if (event.detail.success) return;

    const responseHtml = event.detail.fetchResponse?.responseHTML;
    if (responseHtml?.includes("turbo-stream")) return;

    this.resetPendingState();
  }

  resetPendingState() {
    if (!this.pending) return;

    this.pending = false;

    if (this.lastSubmittedChecked !== undefined) {
      this.switchTarget.checked = !this.lastSubmittedChecked;
    }

    if (this.statusTarget.textContent.trim() === this.savingTextValue) {
      const errorMessage = this.hasValidationErrorTextValue
        ? this.validationErrorTextValue
        : "";
      this.statusTarget.textContent = errorMessage;
      if (errorMessage) this.announce(errorMessage);
    }
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
