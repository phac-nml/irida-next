import { Controller } from "@hotwired/stimulus";

// Announces short status messages to assistive technologies via a live region.
// Mount on a LiveRegionComponent span:
//   <%= render LiveRegionComponent.new(controller: "announcement", data: { controller: "announcement" }) %>
// Then call:
//   this.application.getControllerForElementAndIdentifier(el, "announcement")?.announce("...")
export default class extends Controller {
  static targets = ["status"];

  connect() {
    if (!this.hasStatusTarget) {
      const fallback = document.createElement("span");
      fallback.setAttribute("role", "status");
      fallback.setAttribute("aria-live", "polite");
      fallback.classList.add("sr-only");
      fallback.dataset.announcementTarget = "status";
      this.element.appendChild(fallback);
    }
  }

  announce(message) {
    if (!message || !this.hasStatusTarget) return;

    // Clear then set to ensure repeated messages are announced.
    this.statusTarget.textContent = "";
    requestAnimationFrame(() => {
      if (!this.element.isConnected) return;
      this.statusTarget.textContent = message;
    });
  }
}
