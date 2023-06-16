import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["submitButton", "confirmButton"];
  static values = { projectName: String };

  onChange(event) {
    if (!Number.isNaN(Number.parseInt(event.target.value))) {
      this.submitButtonTarget.removeAttribute("disabled");
    } else {
      this.submitButtonTarget.setAttribute("disabled", "disabled");
    }
  }

  inputChanged(event) {
    console.log(event.target.value, this.projectNameValue);
  }
}
