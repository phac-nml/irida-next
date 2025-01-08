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
    this.element.requestSubmit();
  }

  reset() {
    this.inputTarget.value = this.originalValue;
    this.submit();
  }

  inputKeydown(event) {
    if(event.key === "Escape") {
      this.reset();
    }
  }
}
