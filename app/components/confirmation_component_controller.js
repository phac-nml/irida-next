import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["confirmButton"];

  inputChange(event) {
    // Since the value is set dynamically, stimulus cannot get a handle on it
    // We need to get the value from the element directly
    const value = this.element.getAttribute("data-confirmation-input-value");
    if (event.target.value === value) {
      this.confirmButtonTarget.disabled = false;
    } else {
      this.confirmButtonTarget.disabled = true;
    }
  }
}
