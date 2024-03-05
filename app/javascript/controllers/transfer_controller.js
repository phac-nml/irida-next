import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["submitButton", "confirmButton"];
  static values = { project: String };

  onChange(event) {
    if (event.target.value.length == 36) {
      this.submitButtonTarget.removeAttribute("disabled");
    } else {
      this.submitButtonTarget.setAttribute("disabled", "disabled");
    }
  }

  inputChanged(event) {
    if (event.target.value === this.projectValue) {
      this.confirmButtonTarget.removeAttribute("disabled");
    } else {
      this.confirmButtonTarget.setAttribute("disabled", "disabled");
    }
  }
}
