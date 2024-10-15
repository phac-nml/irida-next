import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["completedList", "error", "submitButton"];

  errorTargetConnected() {
    this.check()
  }
  check() {
    this.submitButtonTarget.disabled = true
  }
}
