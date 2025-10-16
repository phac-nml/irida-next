import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["notice", "source"];
  #ignoreNextRefresh;
  #ignoreTimeoutId;

  initialize() {
    this.boundMessageHandler = this.messageHandler.bind(this);
    this.#ignoreNextRefresh = false;
    this.#ignoreTimeoutId = null;
  }

  sourceTargetConnected(element) {
    element.addEventListener("message", this.boundMessageHandler, true);
  }

  sourceTargetDisconnected(element) {
    element.removeEventListener("message", this.boundMessageHandler, true);
    this.#clearIgnoreTimeout();
  }

  messageHandler(event) {
    if (!this.#isRefreshTurboStream(event)) return;

    if (this.#ignoreNextRefresh) {
      this.#ignoreNextRefresh = false;
      this.#clearIgnoreTimeout();
      event.stopImmediatePropagation();
      return;
    }

    if (this.hasNoticeTarget) {
      this.noticeTarget.classList.remove("hidden");
    }

    event.stopImmediatePropagation();
  }

  dismiss() {
    this.noticeTarget.classList.add("hidden");
  }

  refresh() {
    // Reload the current page
    window.location.reload();
  }

  ignoreNextRefresh() {
    this.#ignoreNextRefresh = true;
    this.#clearIgnoreTimeout();
    this.#ignoreTimeoutId = window.setTimeout(() => {
      this.#ignoreNextRefresh = false;
      this.#ignoreTimeoutId = null;
    }, 5000);
  }

  #clearIgnoreTimeout() {
    if (this.#ignoreTimeoutId) {
      clearTimeout(this.#ignoreTimeoutId);
      this.#ignoreTimeoutId = null;
    }
  }

  #isRefreshTurboStream(event) {
    return (
      typeof event.data === "string" &&
      event.data.startsWith("<turbo-stream") &&
      event.data.includes('action="refresh"')
    );
  }
}
