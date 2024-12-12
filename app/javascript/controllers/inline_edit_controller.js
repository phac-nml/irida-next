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

  submit(event) {
    this.element.requestSubmit();
  }

  cancel(event) {
    if (event.key === "Escape") {
      this.inputTarget.value = this.originalValue;
      this.inputTarget.blur();
    }
  }
}
