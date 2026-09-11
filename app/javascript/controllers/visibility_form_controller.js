import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["privateWarning", "publicWarning", "submit", "visibility"];
  static values = { current: String };

  connect() {
    this.updateWarning();
  }

  update(event) {
    this.submitTarget.disabled = event.target.value === this.currentValue;
    this.updateWarning();
  }

  updateConfirmationWarning() {
    this.updateWarning();
  }

  updateWarning() {
    const selectedVisibility = this.visibilityTargets.find(
      (radio) => radio.checked,
    )?.value;
    const publicSelected = selectedVisibility === "true";

    this.publicWarningTarget.classList.toggle("hidden", !publicSelected);
    this.privateWarningTarget.classList.toggle("hidden", publicSelected);
  }
}
