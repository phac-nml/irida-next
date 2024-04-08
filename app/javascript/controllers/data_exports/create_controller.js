import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["nameInput"];

  // Prevents an empty name input being submitted as an empty string (we want nil)
  clearEmptyNameInput() {
    if (!this.nameInputTarget.value) {
      this.nameInputTarget.remove()
    }
  }
}
