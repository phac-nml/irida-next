import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input"];

  connect() {
    this.inputTarget.focus();
    this.inputTarget.select();
  }

  submit() {
    this.element.requestSubmit();
  }
}
