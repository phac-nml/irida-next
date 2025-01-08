import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input"];
  static values = {
    original: String,
  };

  connect() {
    this.inputTarget.focus();
    this.inputTarget.select();
  }

  submit() {
    if (!this.submitted) {
      this.element.requestSubmit();
    }
  }

  cancel(event) {
    if (event.key === "Escape") {
      this.inputTarget.value = this.originalValue;
      this.inputTarget.blur();
    } else if (event.key === "Enter") {
      this.submitted = true;
    }
  }
}
