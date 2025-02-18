import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "buttonLabel", "successIcon"];
  static classes = ["copied"];

  async copy() {
    try {
      const content = this.sourceTarget.textContent.trim();
      await navigator.clipboard.writeText(content);

      // Visual feedback
      this.successIconTarget.classList.remove("hidden");
      this.buttonLabelTarget.classList.add("sr-only");
      // Reset after 2 seconds
      setTimeout(() => {
        this.successIconTarget.classList.add("hidden");
        this.buttonLabelTarget.classList.remove("sr-only");
      }, 2000);
    } catch (err) {
      console.error("Failed to copy text:", err);
    }
  }
}
