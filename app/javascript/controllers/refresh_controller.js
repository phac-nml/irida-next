import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["notice", "source"];

  initialize() {
    this.boundMessageHandler = this.messageHandler.bind(this);
  }

  sourceTargetConnected(element) {
    element.addEventListener("message", this.boundMessageHandler, true);
  }

  sourceTargetDisconnected(element) {
    element.removeEventListener("message", this.boundMessageHandler, true);
  }

  messageHandler(event) {
    if (
      typeof event.data === "string" &&
      event.data.startsWith("<turbo-stream") &&
      event.data.includes('action="refresh"')
    ) {
      this.noticeTarget.classList.remove("hidden");
      event.stopImmediatePropagation();
    }
  }

  dismiss() {
    this.noticeTarget.classList.add("hidden");
  }

  refresh() {
    // Reload the current page
    window.location.reload();
  }
}
