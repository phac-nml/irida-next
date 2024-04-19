import { Controller } from "@hotwired/stimulus";
import validator from 'validator';

export default class extends Controller {
  static targets = ["submitButton", "confirmButton"];
  static values = { project: String };

  onChange(event) {
    if (validator.isUUID(event.target.value)) {
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

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
  }
}
