import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["cancelButton", "newTokenFormParent"];

  // Remove the add new token form from the DOM while
  // retaining the parent element
  removeAddNewTokenForm() {
    this.newTokenFormParentTarget.innerHTML = "";
  }
}
