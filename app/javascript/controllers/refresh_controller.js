import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["notice", "source"];
  #ignoreNextRefresh;
  #ignoreTimeoutId;
  #debounceTimeoutId;
  #isDebouncing;

  initialize() {
    this.boundMessageHandler = this.messageHandler.bind(this);
    this.#ignoreNextRefresh = false;
    this.#ignoreTimeoutId = null;
    this.#debounceTimeoutId = null;
    this.#isDebouncing = false;
  }

  sourceTargetConnected(element) {
    element.addEventListener("message", this.boundMessageHandler, true);
  }

  sourceTargetDisconnected(element) {
    element.removeEventListener("message", this.boundMessageHandler, true);
    this.#clearIgnoreTimeout();
    this.#clearDebounceTimeout();
  }

  messageHandler(event) {
    if (!this.#isRefreshTurboStream(event)) return;

    if (this.#ignoreNextRefresh) {
      this.#ignoreNextRefresh = false;
      this.#clearIgnoreTimeout();
      // Stop propagation to prevent Turbo from auto-refreshing the page.
      // This controller takes full ownership of handling refresh streams.
      event.stopImmediatePropagation();
      return;
    }

    // If there's no notice target, allow Turbo's default auto-refresh behavior
    if (!this.hasNoticeTarget) {
      return;
    }

    // Debounce rapid successive refresh broadcasts (e.g., during bulk operations).
    // Show the notice on the first broadcast, then ignore subsequent ones for 300ms.
    if (this.#isDebouncing) {
      event.stopImmediatePropagation();
      return;
    }

    this.noticeTarget.classList.remove("hidden");

    this.#isDebouncing = true;
    this.#debounceTimeoutId = window.setTimeout(() => {
      this.#isDebouncing = false;
      this.#debounceTimeoutId = null;
    }, 300);

    event.stopImmediatePropagation();
  }

  dismiss() {
    this.noticeTarget.classList.add("hidden");
  }

  refresh() {
    // Reload the current page
    window.location.reload();
  }

  // Called by outlet controllers (e.g., editable-cell) to suppress the next refresh notice.
  // Used when the user initiates a change that will trigger a broadcast.
  ignoreNextRefresh() {
    this.#ignoreNextRefresh = true;
    this.#clearIgnoreTimeout();
    // Reset ignore flag after 5 seconds to handle delayed broadcasts.
    // This prevents the notice from being suppressed indefinitely if the
    // broadcast doesn't arrive immediately after a user action.
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

  #clearDebounceTimeout() {
    if (this.#debounceTimeoutId) {
      clearTimeout(this.#debounceTimeoutId);
      this.#debounceTimeoutId = null;
      this.#isDebouncing = false;
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
