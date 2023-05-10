import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["nameInput", "submitBtn"];
  static values = { name: String };

  validateName(event) {
    // When the name input value is the same as the value of the nameValue,
    // enable the submit button.
    this.submitBtnTarget.disabled = event.target.value === this.nameValue;
  }
}
