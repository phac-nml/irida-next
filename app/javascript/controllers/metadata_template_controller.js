import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content", "template"];

  replace() {
    this.contentTarget.innerHTML = this.templateTarget.innerHTML;
  }
}
