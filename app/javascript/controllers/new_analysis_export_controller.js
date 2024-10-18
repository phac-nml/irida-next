import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["error", "submitButton"];

  errorTargetConnected() {
    this.disableSubmit()
  }
  disableSubmit() {
    this.submitButtonTarget.disabled = true
  }
}
