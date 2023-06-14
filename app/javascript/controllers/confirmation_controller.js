import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["submitButton"];

  onChange(event) {
    if (!Number.isNaN(Number.parseInt(event.target.value))) {
      this.submitButtonTarget.removeAttribute("disabled");
    } else {
      this.submitButtonTarget.setAttribute("disabled", "disabled");
    }
  }
}
