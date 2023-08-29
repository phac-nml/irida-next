import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggle"];

  toggle(event) {
    if (event.target.tagName !== "A") {
      this.toggleTarget.click();
    }
  }
}
