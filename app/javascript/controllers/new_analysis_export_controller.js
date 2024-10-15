import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["completedList", "error", "submitButton"];

  errorTargetConnected() {
    this.disableSubmit()
  }
  disableSubmit() {
    this.submitButtonTarget.disabled = true
  }
}
