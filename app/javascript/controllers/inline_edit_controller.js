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
    if (event.key === "Escape") {
      this.reset();
    } else if (event.key === "Tab") {
      event.preventDefault();
      this.submit();
    }
  }

  handleBlurEvent(event) {
    // Use a dialog to confirm the change
    if (this.inputTarget.value !== this.originalValue) {
      event.preventDefault();
      if (confirm("Are you sure?")) {
        console.log("confirmed");
      } else {
        console.log("canceled");
      }
    } else {
      this.submit(); // Resets the to non-input state
    }
  }
}
